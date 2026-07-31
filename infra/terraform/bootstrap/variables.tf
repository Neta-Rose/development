variable "aws_region" {
  description = "Region for the state bucket. The app stack can live elsewhere, but there is no reason for it to."
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  description = "owner/name of the repository allowed to assume the deploy role."
  type        = string
  default     = "CommRogue/development"
}

variable "deploy_branch" {
  description = <<-EOT
    Branch whose workflow runs may assume the deploy role. Only this branch can reach AWS;
    pull requests deliberately get no credentials at all (they run `terraform validate`,
    which needs none), so a PR can never apply.
  EOT
  type        = string
  default     = "main"
}

variable "name_prefix" {
  description = "Prefix for every resource name, so this stack can coexist with others in one account."
  type        = string
  default     = "healthapp"
}
