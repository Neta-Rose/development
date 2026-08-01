package main

import (
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"
)

// API is the HTTP surface: one detection endpoint and one health check.
type API struct {
	cfg      Config
	detector *Detector
	log      *slog.Logger
}

func NewAPI(cfg Config, detector *Detector, log *slog.Logger) *API {
	return &API{cfg: cfg, detector: detector, log: log}
}

func (a *API) Routes() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", a.handleHealth)
	mux.HandleFunc("GET /health", a.handleHealth)
	mux.HandleFunc("POST /v1/plate/detect", a.handleDetect)
	return mux
}

func (a *API) handleHealth(w http.ResponseWriter, _ *http.Request) {
	// Deliberately says whether a key is present, never what it is: this is how a
	// deploy is checked before the secret is wired up.
	writeJSON(w, http.StatusOK, map[string]any{
		"status":     "ok",
		"configured": a.cfg.Configured(),
		"model":      a.cfg.Model,
		"max_shots":  a.cfg.MaxShots,
	})
}

func (a *API) handleDetect(w http.ResponseWriter, r *http.Request) {
	started := time.Now()

	if !a.authorized(r) {
		writeError(w, http.StatusUnauthorized, codeUnauthorized, "missing or invalid bearer token", 0)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, a.cfg.MaxRequestBytes)

	var req detectRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		// A body over the cap surfaces here too; either way the caller sent
		// something this service will not process.
		writeError(w, http.StatusBadRequest, codeBadRequest, "body is not a valid detect request", 0)
		return
	}

	shots, err := decodeShots(req.Shots, a.cfg.MaxShots)
	if err != nil {
		writeError(w, http.StatusBadRequest, codeBadRequest, err.Error(), 0)
		return
	}

	model, err := a.cfg.ResolveModel(req.Model)
	if err != nil {
		writeError(w, http.StatusBadRequest, codeBadRequest, err.Error(), 0)
		return
	}

	items, err := a.detector.Detect(r.Context(), model, shots, req.Plate)
	if err != nil {
		a.writeDetectError(w, r, err, model, started)
		return
	}

	a.log.Info("detected",
		"model", model,
		"shots", len(shots),
		"staged", len(req.Plate),
		"items", len(items),
		"merged", countMerged(items),
		"ms", time.Since(started).Milliseconds(),
	)
	writeJSON(w, http.StatusOK, detectResponse{Model: model, Items: items})
}

// writeDetectError maps a detection failure onto the one code the app expects.
// The mapping is total: an unrecognised error becomes `internal`, never a 200
// with an empty plate, because an empty plate is a meaningful answer.
func (a *API) writeDetectError(w http.ResponseWriter, r *http.Request, err error, model string, started time.Time) {
	logFailure := func(code string) {
		a.log.Warn("detection failed",
			"code", code,
			"model", model,
			"ms", time.Since(started).Milliseconds(),
		)
	}

	switch {
	case errors.Is(err, errNotConfigured):
		logFailure(codeNotConfigured)
		writeError(w, http.StatusServiceUnavailable, codeNotConfigured,
			"detection is not configured on this server", 0)
	case errors.Is(err, errTimeout):
		logFailure(codeTimeout)
		writeError(w, http.StatusGatewayTimeout, codeTimeout, "the detector timed out", 0)
	case errors.Is(err, errNoConnection):
		logFailure(codeNoConnection)
		writeError(w, http.StatusBadGateway, codeNoConnection, "could not reach the detector", 0)
	case errors.Is(err, errUnreadable):
		logFailure(codeUnreadable)
		writeError(w, http.StatusBadGateway, codeUnreadable,
			"the detector's answer could not be read", 0)
	case r.Context().Err() != nil:
		// The client hung up. Nothing will read the response; skip the noise.
		return
	default:
		var upstream *upstreamError
		if errors.As(err, &upstream) {
			logFailure(codeUpstreamError)
			writeError(w, http.StatusBadGateway, codeUpstreamError,
				fmt.Sprintf("the detector returned status %d", upstream.Status), upstream.Status)
			return
		}
		logFailure(codeInternal)
		writeError(w, http.StatusInternalServerError, codeInternal, "detection failed", 0)
	}
}

// authorized checks the optional shared secret in constant time.
func (a *API) authorized(r *http.Request) bool {
	if a.cfg.AuthToken == "" {
		return true
	}
	header := r.Header.Get("Authorization")
	token, ok := strings.CutPrefix(header, "Bearer ")
	if !ok {
		return false
	}
	return subtle.ConstantTimeCompare([]byte(strings.TrimSpace(token)), []byte(a.cfg.AuthToken)) == 1
}

// decodeShots validates the images. Each must be base64 (a `data:` prefix is
// tolerated) and must actually be a JPEG: forwarding whatever arrived would turn
// a client bug into a bill.
func decodeShots(raw []string, maxShots int) ([][]byte, error) {
	if len(raw) == 0 {
		return nil, errors.New("shots must hold at least one image")
	}
	if len(raw) > maxShots {
		return nil, fmt.Errorf("shots must hold at most %d images", maxShots)
	}

	out := make([][]byte, 0, len(raw))
	for i, s := range raw {
		payload := s
		if idx := strings.Index(payload, ";base64,"); idx >= 0 {
			payload = payload[idx+len(";base64,"):]
		}
		payload = strings.TrimSpace(payload)

		data, err := base64.StdEncoding.DecodeString(payload)
		if err != nil {
			// Some encoders drop the padding.
			data, err = base64.RawStdEncoding.DecodeString(payload)
		}
		if err != nil {
			return nil, fmt.Errorf("shot %d is not valid base64", i+1)
		}
		if !isJPEG(data) {
			return nil, fmt.Errorf("shot %d is not a JPEG", i+1)
		}
		out = append(out, data)
	}
	return out, nil
}

func isJPEG(b []byte) bool {
	return len(b) > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF
}

// countMerged is the log's view of the feature working: items seen in more than
// one shot and counted once anyway.
func countMerged(items []Detection) int {
	n := 0
	for _, it := range items {
		if len(it.Shots) > 1 {
			n++
		}
	}
	return n
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func writeError(w http.ResponseWriter, status int, code, message string, upstreamStatus int) {
	writeJSON(w, status, errorBody{Error: errorDetail{
		Code:    code,
		Message: message,
		Status:  upstreamStatus,
	}})
}
