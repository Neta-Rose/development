package main

import (
	"errors"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// Config is the whole configuration surface of the service. Every value comes
// from the environment, which is the point of this service existing at all:
// the OpenRouter key stays here instead of shipping inside the app binary
// where any user can read it out.
type Config struct {
	// Addr is the listen address. `PORT` alone is honoured too, so the service
	// drops into a platform that injects it.
	Addr string

	// APIKey is the OpenRouter key. Empty is a *normal* state, not a startup
	// failure: the app treats "not configured" as "AI logging unavailable" and
	// hides the mode, and /healthz still answers so a deploy can be checked
	// before the secret is set.
	APIKey string

	// Model is the OpenRouter model id sent with every request. This is the one
	// knob this feature is meant to be re-pointed on — swapping detectors is an
	// env change and a restart, with no client release.
	Model string

	// AllowModelOverride lets a request name its own model. Off by default:
	// with it on, anything that can reach this service chooses what we are
	// billed for.
	AllowModelOverride bool

	// Endpoint is the OpenRouter chat-completions URL. Configurable only so a
	// test can point it at a stub; it must stay HTTPS in production.
	Endpoint string

	// Referer and Title populate OpenRouter's optional attribution headers.
	Referer string
	Title   string

	// AuthToken, when set, is required from clients as
	// `Authorization: Bearer <token>`. Empty means the endpoint is open, which
	// is logged loudly at startup — an open endpoint spends our OpenRouter
	// credit for whoever finds it.
	AuthToken string

	// MaxShots caps images per request. The client caps at the same number; this
	// is the copy that a hostile caller cannot edit.
	MaxShots int

	// MaxRequestBytes caps the decoded request body.
	MaxRequestBytes int64

	// UpstreamBudget is the *total* wall-clock allowance for one detection,
	// including the single resend after an unreadable reply. It sits below the
	// app's own 30 s timeout on purpose, so the app receives a described
	// failure instead of giving up on us first.
	UpstreamBudget time.Duration

	Temperature float64
	MaxTokens   int
}

const (
	defaultModel    = "google/gemini-2.5-flash"
	defaultEndpoint = "https://openrouter.ai/api/v1/chat/completions"
)

// modelIDPattern is what a request-supplied model id may contain. OpenRouter
// ids look like `vendor/name:variant`; anything else is refused rather than
// forwarded, since the value lands in a JSON body we sign with our key.
var modelIDPattern = regexp.MustCompile(`^[A-Za-z0-9._\-]+/[A-Za-z0-9._\-]+(:[A-Za-z0-9._\-]+)?$`)

// LoadConfig reads the environment. It never returns the key in an error.
func LoadConfig() (Config, error) {
	cfg := Config{
		Addr:               listenAddr(),
		APIKey:             strings.TrimSpace(os.Getenv("OPENROUTER_API_KEY")),
		Model:              envString("OPENROUTER_MODEL", defaultModel),
		AllowModelOverride: envBool("ALLOW_MODEL_OVERRIDE", false),
		Endpoint:           envString("OPENROUTER_ENDPOINT", defaultEndpoint),
		Referer:            envString("OPENROUTER_REFERER", ""),
		Title:              envString("OPENROUTER_TITLE", "healthapp plate detection"),
		AuthToken:          strings.TrimSpace(os.Getenv("PLATE_API_TOKEN")),
		MaxShots:           envInt("MAX_SHOTS", 8),
		MaxRequestBytes:    int64(envInt("MAX_REQUEST_BYTES", 24<<20)),
		UpstreamBudget:     envDuration("OPENROUTER_TIMEOUT", 24*time.Second),
		Temperature:        envFloat("OPENROUTER_TEMPERATURE", 0),
		MaxTokens:          envInt("OPENROUTER_MAX_TOKENS", 2048),
	}
	return cfg, cfg.validate()
}

func (c Config) validate() error {
	if !modelIDPattern.MatchString(c.Model) {
		return errors.New("OPENROUTER_MODEL is not a valid model id")
	}
	if !strings.HasPrefix(c.Endpoint, "https://") &&
		!strings.HasPrefix(c.Endpoint, "http://127.0.0.1") &&
		!strings.HasPrefix(c.Endpoint, "http://localhost") {
		return errors.New("OPENROUTER_ENDPOINT must be https, or loopback http for tests")
	}
	if c.MaxShots < 1 {
		return errors.New("MAX_SHOTS must be at least 1")
	}
	if c.MaxRequestBytes < 1024 {
		return errors.New("MAX_REQUEST_BYTES is implausibly small")
	}
	if c.UpstreamBudget <= 0 {
		return errors.New("OPENROUTER_TIMEOUT must be positive")
	}
	if c.MaxTokens < 256 {
		return errors.New("OPENROUTER_MAX_TOKENS must be at least 256")
	}
	return nil
}

// Configured reports whether detection can run at all.
func (c Config) Configured() bool { return c.APIKey != "" }

// ResolveModel picks the model for one request: the configured one, unless
// overrides are enabled and the caller named a syntactically valid id.
func (c Config) ResolveModel(requested string) (string, error) {
	requested = strings.TrimSpace(requested)
	if requested == "" {
		return c.Model, nil
	}
	if !c.AllowModelOverride {
		return "", errors.New("per-request model override is disabled")
	}
	if !modelIDPattern.MatchString(requested) {
		return "", errors.New("model is not a valid model id")
	}
	return requested, nil
}

func listenAddr() string {
	if addr := strings.TrimSpace(os.Getenv("ADDR")); addr != "" {
		return addr
	}
	if port := strings.TrimSpace(os.Getenv("PORT")); port != "" {
		return ":" + port
	}
	return ":8080"
}

func envString(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func envInt(key string, fallback int) int {
	v, err := strconv.Atoi(envString(key, ""))
	if err != nil {
		return fallback
	}
	return v
}

func envFloat(key string, fallback float64) float64 {
	v, err := strconv.ParseFloat(envString(key, ""), 64)
	if err != nil {
		return fallback
	}
	return v
}

func envBool(key string, fallback bool) bool {
	v, err := strconv.ParseBool(envString(key, ""))
	if err != nil {
		return fallback
	}
	return v
}

func envDuration(key string, fallback time.Duration) time.Duration {
	raw := envString(key, "")
	if raw == "" {
		return fallback
	}
	// Bare numbers read as seconds, which is what anyone writing
	// OPENROUTER_TIMEOUT=30 means.
	if secs, err := strconv.Atoi(raw); err == nil {
		return time.Duration(secs) * time.Second
	}
	d, err := time.ParseDuration(raw)
	if err != nil {
		return fallback
	}
	return d
}
