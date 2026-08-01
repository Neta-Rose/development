# Multi-Provider AI Support via LangChainGo

The Go plate detection server (`server/`) is expanded from a single OpenRouter client to support multiple AI providers (OpenRouter, Google Vertex AI, AWS Bedrock, OpenAI) using `github.com/tmc/langchaingo`.

## Context

Originally, the server communicated exclusively with OpenRouter via a direct HTTP client (`openrouter.go`). To allow using GCP Vertex AI, AWS Bedrock, direct OpenAI endpoints, or OpenRouter without maintaining custom SDK clients for each service, the server needs a unified provider abstraction and dynamic provider selection.

## Decision

1. **Use `langchaingo` (`github.com/tmc/langchaingo`)** as the unified LLM provider interface (`llms.Model`).
2. **Provider Selection via `provider:model_id` Prefix**:
   - Model strings use the format `provider:model_id` (e.g., `openrouter:google/gemini-2.5-flash`, `vertex:gemini-2.5-flash`, `bedrock:us.anthropic.claude-3-5-sonnet-20241022-v2:0`, `openai:gpt-4o`).
   - Unprefixed model strings default to `openrouter:` for full backward compatibility.
3. **Lazy Provider Factory & Credential Lifecycle**:
   - Provider credentials (`OPENROUTER_API_KEY`, `GCP_PROJECT_ID` & `GCP_LOCATION`, `AWS_REGION`, `OPENAI_API_KEY`) are inspected at server startup.
   - Provider instances are lazily instantiated and cached per provider/model.
   - Targeting an unconfigured provider gracefully returns `codeNotConfigured`.
4. **Structured JSON Output & Error Mapping**:
   - Output uses `llms.WithJSONMode()` with markdown code fence sanitization (`stripCodeFence`) and 1 resend attempt on unreadable replies.
   - Provider transport/status errors map to the server's wire error codes (`codeTimeout`, `codeNoConnection`, `codeUnreadable`, `codeUpstreamError`).

## Consequences

- **Extensibility**: Adding new AI providers supported by `langchaingo` requires only registering the provider in `ProviderFactory`.
- **Backward Compatibility**: Existing clients and configuration using OpenRouter model IDs continue to work unchanged without breaking API contracts.
- **Dependencies**: Introduces `github.com/tmc/langchaingo` into `server/go.mod`.
