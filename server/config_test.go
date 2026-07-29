package main

import (
	"testing"
	"time"
)

func TestLoadConfigDefaults(t *testing.T) {
	// t.Setenv restores the environment after the test, and forbids t.Parallel.
	t.Setenv("OPENROUTER_API_KEY", "")
	t.Setenv("OPENROUTER_MODEL", "")
	t.Setenv("ADDR", "")
	t.Setenv("PORT", "")

	cfg, err := LoadConfig()
	if err != nil {
		t.Fatalf("LoadConfig: %v", err)
	}
	if cfg.Model != defaultModel {
		t.Errorf("model = %q, want %q", cfg.Model, defaultModel)
	}
	if cfg.Addr != ":8080" {
		t.Errorf("addr = %q", cfg.Addr)
	}
	if cfg.Configured() {
		t.Error("an empty key must read as not configured, not as an error")
	}
	if cfg.AllowModelOverride {
		t.Error("model override must default to off")
	}
	// Below the app's own 30 s ceiling, so the app sees a described failure
	// rather than timing out on us first.
	if cfg.UpstreamBudget >= 30*time.Second {
		t.Errorf("budget = %v, want under the client's 30s timeout", cfg.UpstreamBudget)
	}
}

func TestLoadConfigReadsTheModelAndPort(t *testing.T) {
	t.Setenv("OPENROUTER_MODEL", "anthropic/claude-sonnet-4.5")
	t.Setenv("ADDR", "")
	t.Setenv("PORT", "9999")
	t.Setenv("OPENROUTER_TIMEOUT", "18")

	cfg, err := LoadConfig()
	if err != nil {
		t.Fatalf("LoadConfig: %v", err)
	}
	if cfg.Model != "anthropic/claude-sonnet-4.5" {
		t.Errorf("model = %q", cfg.Model)
	}
	if cfg.Addr != ":9999" {
		t.Errorf("addr = %q, want :9999", cfg.Addr)
	}
	// A bare number reads as seconds, which is what anyone writing it means.
	if cfg.UpstreamBudget != 18*time.Second {
		t.Errorf("budget = %v, want 18s", cfg.UpstreamBudget)
	}
}

func TestLoadConfigRejectsAMalformedModel(t *testing.T) {
	t.Setenv("OPENROUTER_MODEL", "not a model id")
	if _, err := LoadConfig(); err == nil {
		t.Fatal("want an error for a malformed model id")
	}
}

func TestLoadConfigRejectsAPlainHTTPEndpoint(t *testing.T) {
	t.Setenv("OPENROUTER_ENDPOINT", "http://openrouter.example.com/api")
	if _, err := LoadConfig(); err == nil {
		t.Fatal("want an error: the key must not travel in clear text")
	}
}

func TestResolveModel(t *testing.T) {
	base := Config{Model: "test/vision-1"}

	if got, err := base.ResolveModel(""); err != nil || got != "test/vision-1" {
		t.Errorf("empty request = %q, %v", got, err)
	}
	if _, err := base.ResolveModel("other/vision-2"); err == nil {
		t.Error("override must be refused while ALLOW_MODEL_OVERRIDE is off")
	}

	open := Config{Model: "test/vision-1", AllowModelOverride: true}
	if got, err := open.ResolveModel("other/vision-2:free"); err != nil || got != "other/vision-2:free" {
		t.Errorf("allowed override = %q, %v", got, err)
	}
	for _, bad := range []string{"no-slash", "a//b", "vendor/name;rm -rf", `vendor/"name"`} {
		if _, err := open.ResolveModel(bad); err == nil {
			t.Errorf("ResolveModel(%q) was accepted", bad)
		}
	}
}
