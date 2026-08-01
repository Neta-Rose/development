resource "google_artifact_registry_repository" "plated" {
  location      = var.gcp_region
  repository_id = "${var.name_prefix}-plated"
  description   = "Docker container repository for the healthapp plate detection server"
  format        = "DOCKER"
}
