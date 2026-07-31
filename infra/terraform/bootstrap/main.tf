# One-time bootstrap. Apply this by hand, with admin credentials, before CI can run.
#
# Everything here is a chicken-and-egg resource: the state bucket the app stack stores
# its state in, the trust relationship that lets GitHub Actions authenticate at all,
# and the two IAM roles. Keeping the roles here rather than in the app stack is what
# lets the deploy role carry *no* IAM write permissions — see iam-deploy.tf.
#
# This stack's own state is local and disposable: every resource is either named
# deterministically or discoverable, so a lost state file is re-importable rather than
# a catastrophe. Do not commit terraform.tfstate.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "healthapp"
      Component = "bootstrap"
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
