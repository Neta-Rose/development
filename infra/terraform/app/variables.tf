variable "aws_region" {
  description = "Region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Must match the bootstrap stack's name_prefix — the deploy role's policies are scoped to it."
  type        = string
  default     = "healthapp"
}

variable "lambda_exec_role_arn" {
  description = "Output lambda_exec_role_arn from the bootstrap stack. Created there so this stack needs no IAM write access."
  type        = string
}

variable "image_tag" {
  description = <<-EOT
    Container image tag to deploy — the git SHA, passed by the deploy workflow. An immutable
    tag rather than `latest` so `terraform plan` shows a real diff for every deploy and a
    rollback is just an earlier SHA.
  EOT
  type        = string
}

variable "openrouter_api_key" {
  description = <<-EOT
    OpenRouter key. Empty is a legal state: /healthz still answers 200 with
    "configured": false and the app hides AI logging, which is how a first deploy can be
    health-checked before the secret exists.
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "plate_api_token" {
  description = <<-EOT
    Bearer token required on /v1/plate/detect. Empty leaves the endpoint open to anyone who
    finds the URL, spending OpenRouter credit — the function URL is public, so set this.
    Same value as the PLATE_API_TOKEN dart-define baked into the app.
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "openrouter_model" {
  description = "Vision model id. A deployment knob rather than a client release — the whole reason this service exists."
  type        = string
  default     = "google/gemini-2.5-flash"
}

variable "memory_mb" {
  description = <<-EOT
    Lambda CPU scales with memory, but this workload is I/O-bound on OpenRouter, so this is
    really just the GB-seconds multiplier. 512 is generous for decoding ~2 MB of base64;
    halving it halves the bill and doubles the free-tier headroom.
  EOT
  type        = number
  default     = 512
}

variable "reserved_concurrency" {
  description = <<-EOT
    Spend cap and abuse brake: each concurrent request pins one instance for the full
    upstream call. Set to 0 to hard-kill the endpoint — every request then returns 429.
  EOT
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "Set explicitly so the log group does not default to never expiring."
  type        = number
  default     = 14
}
