package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
)

// Sentinel failures. Each maps to exactly one error code on the way out and to
// exactly one case of the app's sealed VisionFailure, so the camera pane's copy
// is decided by an exhaustive switch rather than by string matching.
var (
	errNotConfigured = errors.New("openrouter: no api key configured")
	errNoConnection  = errors.New("openrouter: unreachable")
	errTimeout       = errors.New("openrouter: timed out")
	errUnreadable    = errors.New("openrouter: reply did not satisfy the response schema")
)

// upstreamError is a non-2xx from OpenRouter. It carries the status code and
// nothing else — no body, no headers. That is not tidiness: an OpenRouter error
// body can echo back parts of the request, and a failure value that structurally
// cannot hold one structurally cannot leak the key through a log line.
type upstreamError struct{ Status int }

func (e *upstreamError) Error() string {
	return fmt.Sprintf("openrouter: upstream status %d", e.Status)
}

// maxUpstreamBody caps what is read from OpenRouter. A completion of a few
// thousand tokens is tens of kilobytes; anything near this cap is a malfunction.
const maxUpstreamBody = 4 << 20

type openRouterClient struct {
	http *http.Client
	cfg  Config
}

func newOpenRouterClient(cfg Config, hc *http.Client) *openRouterClient {
	if hc == nil {
		hc = &http.Client{}
	}
	return &openRouterClient{http: hc, cfg: cfg}
}

type chatRequest struct {
	Model          string          `json:"model"`
	Messages       []chatMessage   `json:"messages"`
	Temperature    float64         `json:"temperature"`
	MaxTokens      int             `json:"max_tokens"`
	ResponseFormat json.RawMessage `json:"response_format"`
	Provider       *providerPrefs  `json:"provider,omitempty"`
}

// providerPrefs asks OpenRouter to route only to providers that honour every
// parameter sent. Without it a provider that ignores `response_format` can be
// chosen, and the reply comes back as prose that no amount of retrying fixes.
type providerPrefs struct {
	RequireParameters bool `json:"require_parameters"`
}

type chatMessage struct {
	Role string `json:"role"`
	// Content is a plain string for the system message and a parts array for the
	// user message. OpenRouter accepts both shapes on the same field.
	Content any `json:"content"`
}

type contentPart struct {
	Type     string        `json:"type"`
	Text     string        `json:"text,omitempty"`
	ImageURL *imageURLPart `json:"image_url,omitempty"`
}

type imageURLPart struct {
	URL string `json:"url"`
}

type chatResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
			Refusal string `json:"refusal"`
		} `json:"message"`
		FinishReason string `json:"finish_reason"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

// complete sends one chat completion and returns the assistant's content string.
// It knows nothing about food: prompts arrive as arguments and the reply leaves
// unparsed, so a change to the detection contract never reaches this file.
func (c *openRouterClient) complete(
	ctx context.Context,
	model string,
	userText string,
	shots [][]byte,
) (string, error) {
	if !c.cfg.Configured() {
		return "", errNotConfigured
	}

	// Text first, then one image per shot in shot order. The order is what makes
	// "image 3 is shot 3" in the prompt true, and the whole deduplication
	// contract is written in terms of shot numbers.
	parts := make([]contentPart, 0, len(shots)+1)
	parts = append(parts, contentPart{Type: "text", Text: userText})
	for _, shot := range shots {
		parts = append(parts, contentPart{
			Type: "image_url",
			ImageURL: &imageURLPart{
				URL: "data:image/jpeg;base64," + base64.StdEncoding.EncodeToString(shot),
			},
		})
	}

	body, err := json.Marshal(chatRequest{
		Model: model,
		Messages: []chatMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: parts},
		},
		Temperature:    c.cfg.Temperature,
		MaxTokens:      c.cfg.MaxTokens,
		ResponseFormat: responseSchema(),
		Provider:       &providerPrefs{RequireParameters: true},
	})
	if err != nil {
		return "", fmt.Errorf("openrouter: encode request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.cfg.Endpoint, bytes.NewReader(body))
	if err != nil {
		return "", fmt.Errorf("openrouter: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.cfg.APIKey)
	if c.cfg.Referer != "" {
		req.Header.Set("HTTP-Referer", c.cfg.Referer)
	}
	if c.cfg.Title != "" {
		req.Header.Set("X-Title", c.cfg.Title)
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return "", classifyTransportError(err)
	}
	defer func() {
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, maxUpstreamBody))
		_ = resp.Body.Close()
	}()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		// The body is deliberately not read into the error.
		return "", &upstreamError{Status: resp.StatusCode}
	}

	raw, err := io.ReadAll(io.LimitReader(resp.Body, maxUpstreamBody))
	if err != nil {
		return "", classifyTransportError(err)
	}

	var parsed chatResponse
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return "", errUnreadable
	}
	if parsed.Error != nil || len(parsed.Choices) == 0 {
		return "", errUnreadable
	}
	choice := parsed.Choices[0]
	if choice.Message.Refusal != "" {
		return "", errUnreadable
	}
	if choice.Message.Content == "" {
		return "", errUnreadable
	}
	return choice.Message.Content, nil
}

// classifyTransportError separates "we ran out of time" from "we could not get
// there", because the two produce different copy and only one of them is worth a
// retry button that behaves differently.
func classifyTransportError(err error) error {
	if errors.Is(err, context.DeadlineExceeded) {
		return errTimeout
	}
	var netErr net.Error
	if errors.As(err, &netErr) && netErr.Timeout() {
		return errTimeout
	}
	if errors.Is(err, context.Canceled) {
		// The caller went away — most often the app cancelled. Nothing is
		// rendered for it, but it is not a connection fault either.
		return context.Canceled
	}
	return errNoConnection
}
