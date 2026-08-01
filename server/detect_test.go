package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

const testKey = "sk-or-v1-THIS-IS-THE-TEST-KEY-DO-NOT-LEAK"

func base64Of(b []byte) string { return base64.StdEncoding.EncodeToString(b) }

func testJPEG(seed byte) []byte {
	return []byte{0xFF, 0xD8, 0xFF, 0xE0, seed, 0x2A, 0x00}
}

func completionBody(t *testing.T, content string) string {
	t.Helper()
	b, err := json.Marshal(map[string]any{
		"choices": []any{
			map[string]any{"message": map[string]any{"content": content}},
		},
	})
	if err != nil {
		t.Fatalf("encode stub reply: %v", err)
	}
	return string(b)
}

// stubOpenRouter stands up a fake OpenRouter and returns a detector pointed at
// it, the request bodies it received, and the number of calls made.
func stubOpenRouter(t *testing.T, handler http.HandlerFunc) (*Detector, *[]chatRequest, *atomic.Int32) {
	t.Helper()

	var calls atomic.Int32
	captured := &[]chatRequest{}

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls.Add(1)
		raw, _ := io.ReadAll(r.Body)
		var parsed chatRequest
		if err := json.Unmarshal(raw, &parsed); err == nil {
			*captured = append(*captured, parsed)
		}
		// Stash the raw body and headers for the assertions that need them.
		r.Body = io.NopCloser(strings.NewReader(string(raw)))
		handler(w, r)
	}))
	t.Cleanup(srv.Close)

	cfg := Config{
		APIKey:         testKey,
		Model:          "test/vision-1",
		Endpoint:       srv.URL,
		MaxShots:       8,
		UpstreamBudget: 5 * time.Second,
		MaxTokens:      2048,
	}
	return NewDetector(cfg, NewProviderFactory(cfg, srv.Client())), captured, &calls
}

// The scenario the whole feature exists for, ported from the design prototype's
// four-shot sequence: the chicken thigh is in every shot and must reach the
// plate exactly once, carrying all four shot numbers.
func TestDetectCountsARepeatedItemOnce(t *testing.T) {
	reply := `{"items":[
      {"instance_id":"chicken_1","name":"Chicken thigh","search_term":"chicken thigh",
       "grams":140,"confidence":0.94,"shots":[1,2,3,4],"emoji":"🍗",
       "kcal_100g":209,"protein_100g":26,"carb_100g":0,"fat_100g":11},
      {"instance_id":"salad_1","name":"Mixed leaf salad","search_term":"lettuce",
       "grams":85,"confidence":0.9,"shots":[2,3,4],"emoji":"🥗",
       "kcal_100g":20,"protein_100g":2,"carb_100g":3,"fat_100g":0},
      {"instance_id":"bread_1","name":"Sourdough slice","search_term":"sourdough bread",
       "grams":50,"confidence":0.95,"shots":[3,4],"emoji":"🍞",
       "kcal_100g":250,"protein_100g":9,"carb_100g":48,"fat_100g":2}
    ]}`

	detector, _, calls := stubOpenRouter(t, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, completionBody(t, reply))
	})

	shots := [][]byte{testJPEG(1), testJPEG(2), testJPEG(3), testJPEG(4)}
	plate := []PlateItem{
		{InstanceID: "chicken_1", Name: "Chicken thigh", Grams: 140},
		{InstanceID: "salad_1", Name: "Mixed leaf salad", Grams: 85},
	}

	items, err := detector.Detect(context.Background(), "test/vision-1", shots, plate)
	if err != nil {
		t.Fatalf("Detect: %v", err)
	}
	if calls.Load() != 1 {
		t.Errorf("calls = %d, want 1", calls.Load())
	}
	if len(items) != 3 {
		t.Fatalf("want 3 items, got %d: %+v", len(items), items)
	}
	if items[0].InstanceID != "chicken_1" {
		t.Errorf("first id = %q, want chicken_1", items[0].InstanceID)
	}
	if !reflect.DeepEqual(items[0].Shots, []int{1, 2, 3, 4}) {
		t.Errorf("chicken shots = %v, want [1 2 3 4]", items[0].Shots)
	}
	// One chicken thigh eaten, one row, one log entry.
	seen := map[string]int{}
	for _, it := range items {
		seen[it.InstanceID]++
	}
	for id, n := range seen {
		if n != 1 {
			t.Errorf("id %q appears %d times, want once", id, n)
		}
	}
}

func TestDetectSendsEveryShotInOrderAfterOneTextPart(t *testing.T) {
	detector, captured, _ := stubOpenRouter(t, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, completionBody(t, `{"items":[]}`))
	})

	shots := [][]byte{testJPEG(11), testJPEG(22), testJPEG(33)}
	if _, err := detector.Detect(context.Background(), "test/vision-1", shots, nil); err != nil {
		t.Fatalf("Detect: %v", err)
	}

	req := (*captured)[0]
	if req.Model != "test/vision-1" {
		t.Errorf("model = %q", req.Model)
	}
	if len(req.Messages) != 2 || req.Messages[0].Role != "system" || req.Messages[1].Role != "user" {
		t.Fatalf("messages = %+v", req.Messages)
	}

	parts, ok := req.Messages[1].Content.([]any)
	if !ok {
		t.Fatalf("user content is %T, want a parts array", req.Messages[1].Content)
	}
	if len(parts) != len(shots)+1 {
		t.Fatalf("parts = %d, want %d", len(parts), len(shots)+1)
	}
	first, _ := parts[0].(map[string]any)
	if first["type"] != "text" {
		t.Errorf("first part is %v, want text", first["type"])
	}
	for i, shot := range shots {
		part, _ := parts[i+1].(map[string]any)
		partType, _ := part["type"].(string)
		if partType != "image_url" && partType != "binary" {
			t.Fatalf("part %d is %v, want image_url or binary", i+1, partType)
		}
		if url, ok := part["image_url"].(map[string]any); ok {
			got, _ := url["url"].(string)
			want := "data:image/jpeg;base64," + base64Of(shot)
			if got != want {
				t.Errorf("part %d carries the wrong shot: shot order is what makes the prompt's shot numbers true", i+1)
			}
		}
	}
}

func TestDetectRequestsAStrictSchemaAndParameterHonouringProviders(t *testing.T) {
	detector, _, _ := stubOpenRouter(t, func(w http.ResponseWriter, r *http.Request) {
		raw, _ := io.ReadAll(r.Body)

		if got := r.Header.Get("Authorization"); got != "Bearer "+testKey {
			t.Errorf("authorization header = %q", got)
		}

		var body map[string]any
		if err := json.Unmarshal(raw, &body); err != nil {
			t.Fatalf("request is not JSON: %v", err)
		}
		format, _ := body["response_format"].(map[string]any)
		if format["type"] != "json_object" && format["type"] != "json_schema" {
			t.Errorf("response_format.type = %v, want json_object", format["type"])
		}
		_, _ = io.WriteString(w, completionBody(t, `{"items":[]}`))
	})

	if _, err := detector.Detect(context.Background(), "test/vision-1", [][]byte{testJPEG(1)}, nil); err != nil {
		t.Fatalf("Detect: %v", err)
	}
}

func TestDetectResendsOnceOnAnUnreadableReply(t *testing.T) {
	var n atomic.Int32
	detector, _, calls := stubOpenRouter(t, func(w http.ResponseWriter, _ *http.Request) {
		if n.Add(1) == 1 {
			_, _ = io.WriteString(w, completionBody(t, "Sure! Here is what I see: chicken."))
			return
		}
		_, _ = io.WriteString(w, completionBody(t,
			`{"items":[{"instance_id":"a","name":"Apple","search_term":"apple","grams":100,
			  "confidence":0.9,"shots":[1],"emoji":"🍎","kcal_100g":52,"protein_100g":0,
			  "carb_100g":14,"fat_100g":0}]}`))
	})

	items, err := detector.Detect(context.Background(), "test/vision-1", [][]byte{testJPEG(1)}, nil)
	if err != nil {
		t.Fatalf("Detect: %v", err)
	}
	if calls.Load() != 2 {
		t.Errorf("calls = %d, want 2", calls.Load())
	}
	if len(items) != 1 {
		t.Errorf("want the second attempt's item, got %+v", items)
	}
}

func TestDetectGivesUpAfterTwoUnreadableReplies(t *testing.T) {
	detector, _, calls := stubOpenRouter(t, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, completionBody(t, "not json at all"))
	})

	_, err := detector.Detect(context.Background(), "test/vision-1", [][]byte{testJPEG(1)}, nil)
	if !errors.Is(err, errUnreadable) {
		t.Fatalf("err = %v, want errUnreadable", err)
	}
	if calls.Load() != 2 {
		t.Errorf("calls = %d, want exactly 2", calls.Load())
	}
}

func TestDetectTreatsRowsThatAllFailNormalisationAsUnreadable(t *testing.T) {
	detector, _, calls := stubOpenRouter(t, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, completionBody(t,
			`{"items":[{"instance_id":"","name":"","search_term":"","grams":0,"confidence":0.9,
			  "shots":[1],"emoji":"","kcal_100g":0,"protein_100g":0,"carb_100g":0,"fat_100g":0}]}`))
	})

	_, err := detector.Detect(context.Background(), "test/vision-1", [][]byte{testJPEG(1)}, nil)
	if !errors.Is(err, errUnreadable) {
		t.Fatalf("err = %v, want errUnreadable", err)
	}
	if calls.Load() != 2 {
		t.Errorf("calls = %d, want 2", calls.Load())
	}
}

func TestDetectAcceptsAnEmptyPlateAsAnAnswer(t *testing.T) {
	// "No food in these shots" is a real answer and must not be retried: the app
	// has copy for it.
	detector, _, calls := stubOpenRouter(t, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, completionBody(t, `{"items":[]}`))
	})

	items, err := detector.Detect(context.Background(), "test/vision-1", [][]byte{testJPEG(1)}, nil)
	if err != nil {
		t.Fatalf("Detect: %v", err)
	}
	if len(items) != 0 {
		t.Errorf("items = %+v, want none", items)
	}
	if calls.Load() != 1 {
		t.Errorf("calls = %d, want 1", calls.Load())
	}
}

func TestDetectDoesNotResendAnUpstreamError(t *testing.T) {
	detector, _, calls := stubOpenRouter(t, func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusTooManyRequests)
		_, _ = io.WriteString(w, `{"error":{"message":"rate limited"}}`)
	})

	_, err := detector.Detect(context.Background(), "test/vision-1", [][]byte{testJPEG(1)}, nil)

	var upstream *upstreamError
	if !errors.As(err, &upstream) {
		t.Fatalf("err = %v, want *upstreamError", err)
	}
	if upstream.Status != http.StatusTooManyRequests {
		t.Errorf("status = %d, want 429", upstream.Status)
	}
	if calls.Load() != 1 {
		t.Errorf("calls = %d, want 1: retrying a rate limit inside one request helps nobody", calls.Load())
	}
}

func TestDetectReportsTimeoutWithinItsBudget(t *testing.T) {
	release := make(chan struct{})
	t.Cleanup(func() { close(release) })

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		select {
		case <-release:
		case <-r.Context().Done():
		case <-time.After(5 * time.Second):
		}
	}))
	t.Cleanup(srv.Close)

	cfg := Config{
		APIKey:         testKey,
		Model:          "test/vision-1",
		Endpoint:       srv.URL,
		MaxShots:       8,
		UpstreamBudget: 150 * time.Millisecond,
		MaxTokens:      2048,
	}
	detector := NewDetector(cfg, NewProviderFactory(cfg, srv.Client()))

	_, err := detector.Detect(context.Background(), cfg.Model, [][]byte{testJPEG(1)}, nil)
	if !errors.Is(err, errTimeout) {
		t.Fatalf("err = %v, want errTimeout", err)
	}
}

func TestDetectReportsNoConnection(t *testing.T) {
	cfg := Config{
		APIKey: testKey,
		Model:  "test/vision-1",
		// Closed port on loopback: nothing is listening, so this is a connect
		// failure rather than a timeout.
		Endpoint:       "http://127.0.0.1:1",
		MaxShots:       8,
		UpstreamBudget: 2 * time.Second,
		MaxTokens:      2048,
	}
	detector := NewDetector(cfg, NewProviderFactory(cfg, &http.Client{}))

	_, err := detector.Detect(context.Background(), cfg.Model, [][]byte{testJPEG(1)}, nil)
	if !errors.Is(err, errNoConnection) {
		t.Fatalf("err = %v, want errNoConnection", err)
	}
}

func TestDetectWithoutAKeyMakesNoRequest(t *testing.T) {
	var calls atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		calls.Add(1)
	}))
	t.Cleanup(srv.Close)

	cfg := Config{Model: "test/vision-1", Endpoint: srv.URL, MaxShots: 8,
		UpstreamBudget: time.Second, MaxTokens: 2048}
	detector := NewDetector(cfg, NewProviderFactory(cfg, srv.Client()))

	_, err := detector.Detect(context.Background(), cfg.Model, [][]byte{testJPEG(1)}, nil)
	if !errors.Is(err, errNotConfigured) {
		t.Fatalf("err = %v, want errNotConfigured", err)
	}
	if calls.Load() != 0 {
		t.Errorf("made %d requests without a key, want 0", calls.Load())
	}
}

// The key is the one secret this service holds. No failure it produces may
// carry it, including when the upstream body echoes it straight back.
func TestNoFailureCarriesTheAPIKey(t *testing.T) {
	handlers := map[string]http.HandlerFunc{
		"echoing 500": func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = io.WriteString(w, `{"error":{"message":"bad key `+testKey+`"}}`)
		},
		"echoing prose 200": func(w http.ResponseWriter, _ *http.Request) {
			_, _ = io.WriteString(w, completionBody(t, "your key is "+testKey))
		},
	}

	for name, handler := range handlers {
		t.Run(name, func(t *testing.T) {
			detector, _, _ := stubOpenRouter(t, handler)
			_, err := detector.Detect(context.Background(), "test/vision-1", [][]byte{testJPEG(1)}, nil)
			if err == nil {
				t.Fatal("want a failure")
			}
			if strings.Contains(err.Error(), testKey) {
				t.Fatalf("error text carries the api key: %v", err)
			}
		})
	}
}

func TestStripCodeFence(t *testing.T) {
	cases := map[string]string{
		"{\"items\":[]}":                       `{"items":[]}`,
		"```json\n{\"items\":[]}\n```":         `{"items":[]}`,
		"```\n{\"items\":[]}\n```":             `{"items":[]}`,
		"  ```json\r\n{\"items\":[]}\r\n```  ": `{"items":[]}`,
	}
	for in, want := range cases {
		if got := stripCodeFence(in); got != want {
			t.Errorf("stripCodeFence(%q) = %q, want %q", in, got, want)
		}
	}
}
