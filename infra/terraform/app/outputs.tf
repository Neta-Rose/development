output "function_url" {
  description = "Set this as the PLATE_API_URL GitHub secret. Includes a trailing slash, which plateDetectEndpoint strips."
  value       = aws_lambda_function_url.plated.function_url
}

output "ecr_repository_url" {
  description = "Push target for the deploy workflow."
  value       = data.aws_ecr_repository.plated.repository_url
}

output "log_group" {
  description = "aws logs tail <this> --follow"
  value       = aws_cloudwatch_log_group.plated.name
}
