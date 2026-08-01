variable "gcp_project_id" {
  description = "GCP Project ID."
  type        = string
}

variable "gcp_region" {
  description = "Region to deploy into."
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  description = "Must match bootstrap stack's name_prefix."
  type        = string
  default     = "healthapp"
}

variable "image_tag" {
  description = "Container image tag to deploy (git SHA)."
  type        = string
}

variable "ai_model" {
  description = "Vision model ID."
  type        = string
  default     = "vertex:gemini-2.5-flash"
}

variable "ai_api_key" {
  description = "Generic AI API key if key-authenticated models are targeted."
  type        = string
  default     = ""
  sensitive   = true
}

variable "plate_api_token" {
  description = "Bearer token required on /v1/plate/detect."
  type        = string
  default     = ""
  sensitive   = true
}
