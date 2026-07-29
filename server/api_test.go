package main

import (
	"bytes"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

// newTestAPI wires the real API onto a stubbed OpenRouter.
func newTestAPI(t *testing.T, cfgFn func(*Config), upstream http.HandlerFunc) *API {
	t.Helper()

	srv := httptest.NewServer(upstream)
	t.Cleanup(srv.Close)

	cfg := Config{
		APIKey:          testKey,
		Model:           "test/vision-1",
		Endpoint:        srv.URL,
		MaxShots:        8,
		MaxRequestBytes: 4 << 20,
		UpstreamBudget:  5 * time.Second,
		MaxTokens:       2048,
	}
	if cfgFn != nil {
		cfgFn(&cfg)
	}

	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	return NewAPI(cfg, NewDetector(cfg, newOpenRouterClient(cfg, srv.Client())), log)
}

func postDetect(t *testing.T, api *API, body any, headers map[string]string) *httptest.ResponseRecorder {
	t.Helper()

	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("encode request: %v", err)
	}
	req := httptest.NewRequest(http.MethodPost, "/v1/plate/detect", bytes.NewReader(raw))
	req.Header.Set("Content-Type", "application/json")
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	rec := httptest.NewRecorder()
	api.Routes().ServeHTTP(rec, req)
	return rec
}

func okUpstream(t *testing.T, content string) http.HandlerFunc {
	t.Helper()
	return func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, completionBody(t, content))
	}
}

func decodeError(t *testing.T, rec *httptest.ResponseRecorder) errorDetail {
	t.Helper()
	var body errorBody
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("response is not an error body: %v (%s)", err, rec.Body.String())
	}
	return body.Error
}

func TestHealthzReportsConfigurationWithoutTheKey(t *testing.T) {
	api := newTestAPI(t, nil, okUpstream(t, `{"items":[]}`))

	rec := httptest.NewRecorder()
	api.Routes().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d", rec.Code)
	}
	if strings.Contains(rec.Body.String(), testKey) {
		t.Fatal("/healthz leaked the api key")
	}
	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("not JSON: %v", err)
	}
	if body["configured"] != true {
		t.Errorf("configured = %v, want true", body["configured"])
	}
}

func TestDetectEndpointReturnsTheDeduplicatedPlate(t *testing.T) {
	api := newTestAPI(t, nil, okUpstream(t,
		`{"items":[
		   {"instance_id":"chicken_1","name":"Chicken thigh","search_term":"chicken thigh",
		    "grams":140,"confidence":0.94,"shots":[1,2],"emoji":"🍗",
		    "kcal_100g":209,"protein_100g":26,"carb_100g":0,"fat_100g":11},
		   {"instance_id":"chicken_1","name":"Chicken thigh","search_term":"chicken thigh",
		    "grams":140,"confidence":0.5,"shots":[2],"emoji":"🍗",
		    "kcal_100g":209,"protein_100g":26,"carb_100g":0,"fat_100g":11}
		 ]}`))

	rec := postDetect(t, api, detectRequest{
		Shots: []string{base64Of(testJPEG(1)), base64Of(testJPEG(2))},
	}, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body.String())
	}
	var body detectResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("not a detect response: %v", err)
	}
	if body.Model != "test/vision-1" {
		t.Errorf("model = %q", body.Model)
	}
	if len(body.Items) != 1 {
		t.Fatalf("want the duplicate collapsed to 1 item, got %d", len(body.Items))
	}
	if len(body.Items[0].Shots) != 2 {
		t.Errorf("shots = %v, want both", body.Items[0].Shots)
	}
}

func TestDetectEndpointAcceptsADataURLPrefix(t *testing.T) {
	api := newTestAPI(t, nil, okUpstream(t, `{"items":[]}`))

	rec := postDetect(t, api, detectRequest{
		Shots: []string{"data:image/jpeg;base64," + base64Of(testJPEG(1))},
	}, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body.String())
	}
}

func TestDetectEndpointRejectsBadInput(t *testing.T) {
	cases := []struct {
		name  string
		shots []string
	}{
		{"no shots", nil},
		{"not base64", []string{"@@@@not-base64@@@@"}},
		{"not a jpeg", []string{base64Of([]byte("PNG\x89 nope"))}},
		{"too many shots", func() []string {
			out := make([]string, 9)
			for i := range out {
				out[i] = base64Of(testJPEG(byte(i)))
			}
			return out
		}()},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			api := newTestAPI(t, nil, okUpstream(t, `{"items":[]}`))
			rec := postDetect(t, api, detectRequest{Shots: tc.shots}, nil)
			if rec.Code != http.StatusBadRequest {
				t.Fatalf("status = %d, want 400 (body %s)", rec.Code, rec.Body.String())
			}
			if got := decodeError(t, rec).Code; got != codeBadRequest {
				t.Errorf("code = %q, want %q", got, codeBadRequest)
			}
		})
	}
}

func TestDetectEndpointEnforcesTheSharedSecret(t *testing.T) {
	withToken := func(c *Config) { c.AuthToken = "s3cret-token" }
	body := detectRequest{Shots: []string{base64Of(testJPEG(1))}}

	for _, tc := range []struct {
		name   string
		header map[string]string
		want   int
	}{
		{"no header", nil, http.StatusUnauthorized},
		{"wrong token", map[string]string{"Authorization": "Bearer nope"}, http.StatusUnauthorized},
		{"not bearer", map[string]string{"Authorization": "s3cret-token"}, http.StatusUnauthorized},
		{"correct token", map[string]string{"Authorization": "Bearer s3cret-token"}, http.StatusOK},
	} {
		t.Run(tc.name, func(t *testing.T) {
			api := newTestAPI(t, withToken, okUpstream(t, `{"items":[]}`))
			rec := postDetect(t, api, body, tc.header)
			if rec.Code != tc.want {
				t.Fatalf("status = %d, want %d (body %s)", rec.Code, tc.want, rec.Body.String())
			}
		})
	}
}

func TestDetectEndpointRejectsAModelOverrideByDefault(t *testing.T) {
	api := newTestAPI(t, nil, okUpstream(t, `{"items":[]}`))

	rec := postDetect(t, api, detectRequest{
		Shots: []string{base64Of(testJPEG(1))},
		Model: "someone/expensive-model",
	}, nil)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400: an open override spends our credit", rec.Code)
	}
}

func TestDetectEndpointHonoursAnAllowedModelOverride(t *testing.T) {
	var seen string
	api := newTestAPI(t,
		func(c *Config) { c.AllowModelOverride = true },
		func(w http.ResponseWriter, r *http.Request) {
			var req chatRequest
			_ = json.NewDecoder(r.Body).Decode(&req)
			seen = req.Model
			_, _ = io.WriteString(w, completionBody(t, `{"items":[]}`))
		})

	rec := postDetect(t, api, detectRequest{
		Shots: []string{base64Of(testJPEG(1))},
		Model: "other/vision-2",
	}, nil)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body.String())
	}
	if seen != "other/vision-2" {
		t.Errorf("upstream model = %q, want other/vision-2", seen)
	}
}

// Each upstream failure has to arrive as the one code the camera pane switches
// on, and the upstream status has to survive so `detection failed · 429` can be
// rendered.
func TestDetectEndpointMapsFailuresOntoCodes(t *testing.T) {
	body := detectRequest{Shots: []string{base64Of(testJPEG(1))}}

	t.Run("upstream error keeps its status", func(t *testing.T) {
		api := newTestAPI(t, nil, func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusTooManyRequests)
		})
		rec := postDetect(t, api, body, nil)
		if rec.Code != http.StatusBadGateway {
			t.Fatalf("status = %d, want 502", rec.Code)
		}
		detail := decodeError(t, rec)
		if detail.Code != codeUpstreamError {
			t.Errorf("code = %q", detail.Code)
		}
		if detail.Status != http.StatusTooManyRequests {
			t.Errorf("upstream status = %d, want 429", detail.Status)
		}
	})

	t.Run("unreadable", func(t *testing.T) {
		api := newTestAPI(t, nil, okUpstream(t, "prose, not json"))
		rec := postDetect(t, api, body, nil)
		if rec.Code != http.StatusBadGateway {
			t.Fatalf("status = %d, want 502", rec.Code)
		}
		if got := decodeError(t, rec).Code; got != codeUnreadable {
			t.Errorf("code = %q, want %q", got, codeUnreadable)
		}
	})

	t.Run("not configured", func(t *testing.T) {
		api := newTestAPI(t, func(c *Config) { c.APIKey = "" }, okUpstream(t, `{"items":[]}`))
		rec := postDetect(t, api, body, nil)
		if rec.Code != http.StatusServiceUnavailable {
			t.Fatalf("status = %d, want 503", rec.Code)
		}
		if got := decodeError(t, rec).Code; got != codeNotConfigured {
			t.Errorf("code = %q, want %q", got, codeNotConfigured)
		}
	})

	t.Run("no connection", func(t *testing.T) {
		api := newTestAPI(t,
			func(c *Config) { c.Endpoint = "http://127.0.0.1:1" },
			okUpstream(t, `{"items":[]}`))
		rec := postDetect(t, api, body, nil)
		if rec.Code != http.StatusBadGateway {
			t.Fatalf("status = %d, want 502", rec.Code)
		}
		if got := decodeError(t, rec).Code; got != codeNoConnection {
			t.Errorf("code = %q, want %q", got, codeNoConnection)
		}
	})
}

func TestDetectEndpointNeverEchoesTheKey(t *testing.T) {
	api := newTestAPI(t, nil, func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = io.WriteString(w, `{"error":{"message":"invalid key `+testKey+`"}}`)
	})

	rec := postDetect(t, api, detectRequest{Shots: []string{base64Of(testJPEG(1))}}, nil)

	if strings.Contains(rec.Body.String(), testKey) {
		t.Fatalf("response leaked the api key: %s", rec.Body.String())
	}
}

func TestDetectEndpointRejectsWrongMethod(t *testing.T) {
	api := newTestAPI(t, nil, okUpstream(t, `{"items":[]}`))

	rec := httptest.NewRecorder()
	api.Routes().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/plate/detect", nil))

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want 405", rec.Code)
	}
}
