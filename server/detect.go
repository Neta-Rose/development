package main

import (
	"context"
	"encoding/json"
	"errors"
	"strings"

	"github.com/tmc/langchaingo/llms"
)

// Detector turns a batch of shots into a deduplicated plate.
type Detector struct {
	factory *ProviderFactory
	cfg     Config
}

func NewDetector(cfg Config, factory *ProviderFactory) *Detector {
	return &Detector{factory: factory, cfg: cfg}
}

// Detect sends the whole batch and returns one entry per distinct physical food
// item across all of it.
func (d *Detector) Detect(
	ctx context.Context,
	rawModel string,
	shots [][]byte,
	plate []PlateItem,
) ([]Detection, error) {
	if !d.cfg.Configured() {
		return nil, errNotConfigured
	}
	if len(shots) == 0 {
		return nil, errors.New("detect: no shots")
	}

	provider, modelID := d.cfg.ParseModel(rawModel)
	if !d.cfg.ProviderConfigured(provider) {
		return nil, errNotConfigured
	}

	model, err := d.factory.GetModel(ctx, provider, modelID)
	if err != nil {
		return nil, classifyTransportError(err)
	}

	ctx, cancel := context.WithTimeout(ctx, d.cfg.UpstreamBudget)
	defer cancel()

	userText := buildUserText(len(shots), plate)

	userParts := make([]llms.ContentPart, 0, len(shots)+1)
	userParts = append(userParts, llms.TextPart(userText))
	for _, shot := range shots {
		userParts = append(userParts, llms.BinaryPart("image/jpeg", shot))
	}

	messages := []llms.MessageContent{
		llms.TextParts(llms.ChatMessageTypeSystem, systemPrompt),
		{
			Role:  llms.ChatMessageTypeHuman,
			Parts: userParts,
		},
	}

	opts := []llms.CallOption{
		llms.WithTemperature(d.cfg.Temperature),
		llms.WithMaxTokens(d.cfg.MaxTokens),
		llms.WithJSONMode(),
	}

	var lastErr error
	for attempt := 0; attempt < 2; attempt++ {
		resp, err := model.GenerateContent(ctx, messages, opts...)
		if err == nil && len(resp.Choices) > 0 {
			content := resp.Choices[0].Content
			if content != "" {
				items, perr := parseReply(content, len(shots), plate)
				if perr == nil {
					return items, nil
				}
				err = perr
			} else {
				err = errUnreadable
			}
		} else if err != nil {
			err = classifyTransportError(err)
		} else {
			err = errUnreadable
		}

		// Only an unreadable reply earns the resend.
		if !errors.Is(err, errUnreadable) {
			return nil, err
		}
		lastErr = err
	}
	return nil, lastErr
}

// parseReply validates the model's content string and normalises it.
func parseReply(content string, shotCount int, plate []PlateItem) ([]Detection, error) {
	var reply modelReply
	if err := json.Unmarshal([]byte(stripCodeFence(content)), &reply); err != nil {
		return nil, errUnreadable
	}
	if reply.Items == nil {
		return nil, errUnreadable
	}

	raw := *reply.Items
	items := normalizeDetections(raw, shotCount, plate)

	if len(raw) > 0 && len(items) == 0 {
		return nil, errUnreadable
	}
	return items, nil
}

// stripCodeFence unwraps a ```json ... ``` block.
func stripCodeFence(s string) string {
	t := strings.TrimSpace(s)
	if !strings.HasPrefix(t, "```") {
		return t
	}
	if i := strings.IndexByte(t, '\n'); i >= 0 {
		t = t[i+1:]
	} else {
		t = strings.TrimPrefix(t, "```")
	}
	if i := strings.LastIndex(t, "```"); i >= 0 {
		t = t[:i]
	}
	return strings.TrimSpace(t)
}
