# GCP Cloud Run and Vertex AI Migration

The Go plate detection server (`server/`) is migrated from AWS Lambda and OpenRouter defaults to GCP Cloud Run and Google Vertex AI.

## Context

Originally, the server was deployed on AWS Lambda with OpenRouter as the primary AI provider. To leverage native GCP infrastructure, GCP Workload Identity Federation, and Google Vertex AI models (e.g. `vertex:gemini-2.5-flash`), the hosting architecture and CI pipeline are updated to target GCP Cloud Run.

## Decision

1. **Host Server on GCP Cloud Run v2**:
   - Containerized Go service deployed as `google_cloud_run_v2_service` (`healthapp-plated`) in region `us-central1`.
   - Ingress configured for public HTTP invocations (`allUsers` with `roles/run.invoker`), protected at the application layer by `PLATE_API_TOKEN` bearer authentication.
   - Cloud Run runtime service account granted `roles/aiplatform.user` for Vertex AI model calls.

2. **Generic Model Configuration (`AI_MODEL`)**:
   - Generalize server configuration to read `AI_MODEL` as the primary environment variable, falling back to `OPENROUTER_MODEL` for backward compatibility.
   - Set default model to `vertex:gemini-2.5-flash`.

3. **Keyless CI/CD via Workload Identity Federation (WIF)**:
   - GitHub Actions authenticates via GCP Workload Identity Federation OIDC token exchange (`google-github-actions/auth`), eliminating long-lived service account key secrets.
   - Images are built and pushed to GCP Artifact Registry (`healthapp-plated`).

4. **Terraform Infrastructure as Code**:
   - `infra/terraform/bootstrap` provisions GCP Artifact Registry, Workload Identity Pool/Provider, deploy service account, and GCS state bucket.
   - `infra/terraform/app` provisions the Cloud Run service, IAM bindings, and environment variables.

## Consequences

- **Native GCP Vertex AI**: Food detection leverages Vertex AI directly via IAM authorization without third-party proxy tokens.
- **Unified Configuration**: `AI_MODEL` allows switching seamlessly between Vertex AI, Bedrock, OpenAI, or OpenRouter via environment configuration.
- **Streamlined CI/CD**: Keyless GitHub Actions OIDC deployment to GCP Cloud Run.
