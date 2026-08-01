resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.name_prefix}-plated-sa"
  display_name = "Cloud Run runtime service account for healthapp plate detection"
}

resource "google_project_iam_member" "vertex_ai_user" {
  project = var.gcp_project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_cloud_run_v2_service" "plated" {
  name                = "${var.name_prefix}-plated"
  location            = var.gcp_region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false


  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.name_prefix}-plated/server:${var.image_tag}"

      ports {
        container_port = 8080
      }

      env {
        name  = "AI_MODEL"
        value = var.ai_model
      }
      env {
        name  = "GCP_PROJECT_ID"
        value = var.gcp_project_id
      }
      env {
        name  = "GCP_LOCATION"
        value = var.gcp_region
      }
      env {
        name  = "PLATE_API_TOKEN"
        value = var.plate_api_token
      }
      env {
        name  = "AI_API_KEY"
        value = var.ai_api_key
      }

      resources {
        limits = {
          memory = "512Mi"
          cpu    = "1000m"
        }
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.plated.project
  location = google_cloud_run_v2_service.plated.location
  name     = google_cloud_run_v2_service.plated.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
