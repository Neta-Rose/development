output "cloud_run_url" {
  description = "Public URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.plated.uri
}
