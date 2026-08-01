resource "google_storage_bucket" "state" {
  name                     = "${var.name_prefix}-tf-state-${var.gcp_project_id}"
  location                 = var.gcp_region
  force_destroy            = false
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }
}
