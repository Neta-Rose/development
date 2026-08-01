package main

import (
	"context"
	"fmt"
	"net/http"
	"sync"

	"github.com/tmc/langchaingo/llms"
	"github.com/tmc/langchaingo/llms/bedrock"
	"github.com/tmc/langchaingo/llms/googleai"
	"github.com/tmc/langchaingo/llms/openai"
)

type ProviderFactory struct {
	cfg      Config
	hc       *http.Client
	mu       sync.RWMutex
	llmCache map[string]llms.Model
}

func NewProviderFactory(cfg Config, hc *http.Client) *ProviderFactory {
	if hc == nil {
		hc = &http.Client{}
	}
	return &ProviderFactory{
		cfg:      cfg,
		hc:       hc,
		llmCache: make(map[string]llms.Model),
	}
}

func (f *ProviderFactory) GetModel(ctx context.Context, provider string, modelID string) (llms.Model, error) {
	if !f.cfg.ProviderConfigured(provider) {
		return nil, errNotConfigured
	}

	key := fmt.Sprintf("%s:%s", provider, modelID)

	f.mu.RLock()
	model, ok := f.llmCache[key]
	f.mu.RUnlock()
	if ok {
		return model, nil
	}

	f.mu.Lock()
	defer f.mu.Unlock()
	if model, ok := f.llmCache[key]; ok {
		return model, nil
	}

	var created llms.Model
	var err error

	switch provider {
	case "openai", "openrouter":
		opts := []openai.Option{
			openai.WithToken(f.cfg.APIKey),
			openai.WithBaseURL(f.cfg.Endpoint),
			openai.WithModel(modelID),
			openai.WithHTTPClient(f.hc),
		}
		created, err = openai.New(opts...)

	case "vertex", "gcp":
		opts := []googleai.Option{
			googleai.WithCloudProject(f.cfg.GCPProjectID),
			googleai.WithCloudLocation(f.cfg.GCPLocation),
			googleai.WithDefaultModel(modelID),
		}
		created, err = googleai.New(ctx, opts...)

	case "bedrock", "aws":
		opts := []bedrock.Option{
			bedrock.WithModel(modelID),
		}
		created, err = bedrock.New(opts...)

	default:
		return nil, fmt.Errorf("unsupported provider %q", provider)
	}

	if err != nil {
		return nil, err
	}

	f.llmCache[key] = created
	return created, nil
}
