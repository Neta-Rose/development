output "state_bucket" {
  description = "Set this as AWS_TF_STATE_BUCKET in GitHub Actions secrets."
  value       = aws_s3_bucket.state.id
}

output "deploy_role_arn" {
  description = "Set this as AWS_DEPLOY_ROLE_ARN in GitHub Actions secrets."
  value       = aws_iam_role.deploy.arn
}

output "lambda_exec_role_arn" {
  description = "Consumed by the app stack as TF_VAR_lambda_exec_role_arn / -var."
  value       = aws_iam_role.lambda_exec.arn
}

output "ecr_repository_url" {
  description = "Push target for the deploy workflow."
  value       = aws_ecr_repository.plated.repository_url
}

output "github_secrets" {
  description = "Everything the server-deploy workflow needs, ready to paste."
  value = {
    AWS_REGION           = var.aws_region
    AWS_DEPLOY_ROLE_ARN  = aws_iam_role.deploy.arn
    AWS_TF_STATE_BUCKET  = aws_s3_bucket.state.id
    AWS_LAMBDA_EXEC_ROLE = aws_iam_role.lambda_exec.arn
  }
}
