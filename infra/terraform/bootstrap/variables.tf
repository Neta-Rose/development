variable "gcp_region" {
  description = "Region for GCP resources and state bucket."
  type        = string
  default     = "us-central1"
}

variable "gcp_project_id" {
  description = "GCP Project ID."
  type        = string
}

variable "github_repo" {
  description = "owner/name of the repository allowed to assume the deploy service account."
  type        = string
  default     = "CommRogue/development"
}

variable "deploy_branch" {
  description = <<-EOT
    Branch whose workflow runs may authenticate via Workload Identity Federation.
  EOT
  type        = string
  default     = "main"
}

variable "name_prefix" {
  description = "Prefix for resource naming."
  type        = string
  default     = "healthapp"
}
