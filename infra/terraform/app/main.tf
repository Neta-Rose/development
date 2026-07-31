# The plate detector on AWS: an ECR repository and a Lambda behind a function URL.
#
# Why Lambda and not a container service: App Runner entered maintenance mode on
# 2026-04-30 and accepts no new customers, and ECS Express Mode — its official
# successor — cannot scale to zero, so it bills a shared ALB plus a Fargate task around
# the clock. This workload is a handful of requests a day, each spent almost entirely
# blocked on OpenRouter. At 512 MB and ~8s per detection that is 4 GB-seconds a request,
# against a perpetual free tier of 400,000 GB-seconds a month: roughly 100k detections
# free, then about 5c per thousand.
#
# The crossover is near 20,000 detections/day. Past that, a long-running container
# amortises better because one process serves many concurrent I/O-blocked requests
# while Lambda holds an instance per request — at which point replace lambda.tf with an
# aws_ecs_express_gateway_service and drop the adapter line from server/Dockerfile.
# Nothing in server/ or the Flutter client depends on this choice.

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
      Component = "plated"
      ManagedBy = "terraform"
    }
  }
}

locals {
  name = "${var.name_prefix}-plated"
}
