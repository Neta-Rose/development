output "state_bucket" {
  description = "GCS bucket name for Terraform backend state."
  value       = google_storage_bucket.state.name
}

output "workload_identity_provider" {
  description = "GCP Workload Identity Provider full name."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "deploy_service_account" {
  description = "Service account email for deployment."
  value       = google_service_account.deploy.email
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository ID."
  value       = google_artifact_registry_repository.plated.name
}

output "github_secrets" {
  description = "Required environment variables & secrets for server-deploy workflow."
  value = {
    GCP_PROJECT_ID             = var.gcp_project_id
    GCP_REGION                 = var.gcp_region
    WORKLOAD_IDENTITY_PROVIDER = google_iam_workload_identity_pool_provider.github.name
    GCP_DEPLOY_SERVICE_ACCOUNT = google_service_account.deploy.email
    GCP_TF_STATE_BUCKET        = google_storage_bucket.state.name
  }
}
