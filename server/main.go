package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	log := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))

	cfg, err := LoadConfig()
	if err != nil {
		log.Error("invalid configuration", "err", err)
		os.Exit(2)
	}

	// A missing key is a normal state, not a failure: the app hides AI logging
	// when the service reports `not_configured`, and this lets a deploy be
	// health-checked before the secret exists.
	if !cfg.Configured() {
		log.Warn("OPENROUTER_API_KEY is empty; detection will report not_configured")
	}
	// An open endpoint spends our OpenRouter credit for anyone who finds it.
	if cfg.AuthToken == "" {
		log.Warn("PLATE_API_TOKEN is empty: /v1/plate/detect is UNAUTHENTICATED. " +
			"Set it, or keep this service off the public internet.")
	}
	if cfg.AllowModelOverride {
		log.Warn("ALLOW_MODEL_OVERRIDE is on: callers choose the model that gets billed")
	}

	// The per-request budget lives in Detector; this timeout is the backstop for a
	// connection that hangs before any of it applies.
	httpClient := &http.Client{
		Timeout: cfg.UpstreamBudget + 5*time.Second,
		Transport: &http.Transport{
			MaxIdleConns:        16,
			MaxIdleConnsPerHost: 8,
			IdleConnTimeout:     90 * time.Second,
			TLSHandshakeTimeout: 10 * time.Second,
			ForceAttemptHTTP2:   true,
		},
	}

	api := NewAPI(cfg, NewDetector(cfg, newOpenRouterClient(cfg, httpClient)), log)

	srv := &http.Server{
		Addr:    cfg.Addr,
		Handler: api.Routes(),
		// Read timeouts must clear the time it takes a phone on a slow uplink to
		// push a few megabytes of JPEG.
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       60 * time.Second,
		WriteTimeout:      cfg.UpstreamBudget + 30*time.Second,
		IdleTimeout:       120 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Info("listening",
			"addr", cfg.Addr,
			"model", cfg.Model,
			"configured", cfg.Configured(),
			"authenticated", cfg.AuthToken != "",
		)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error("server stopped", "err", err)
			stop()
		}
	}()

	<-ctx.Done()
	log.Info("shutting down")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Error("shutdown", "err", err)
		os.Exit(1)
	}
}
