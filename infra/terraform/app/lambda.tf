# Created explicitly rather than left to Lambda, which would create it with no expiry.
resource "aws_cloudwatch_log_group" "plated" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "plated" {
  function_name = local.name
  role          = var.lambda_exec_role_arn

  package_type = "Image"
  image_uri    = "${data.aws_ecr_repository.plated.repository_url}:${var.image_tag}"

  # arm64 is ~20% cheaper per GB-second and the Dockerfile cross-compiles for it.
  architectures = ["arm64"]
  memory_size   = var.memory_mb

  # Must clear the server's WriteTimeout of OPENROUTER_TIMEOUT + 30s (~54s by default), or
  # Lambda kills the invocation mid-response and the client sees a truncated read rather
  # than the server's own timeout error. Function URLs impose no separate ceiling — this is
  # why the design does not use API Gateway, whose 29s cap would sit below the upstream call.
  timeout = 60

  reserved_concurrent_executions = var.reserved_concurrency

  environment {
    variables = {
      OPENROUTER_API_KEY = var.openrouter_api_key
      PLATE_API_TOKEN    = var.plate_api_token
      OPENROUTER_MODEL   = var.openrouter_model

      # Lambda rejects invocations over 6 MB before the handler ever sees them, which would
      # surface to the app as a bare 413 instead of the server's JSON error envelope. Capping
      # below that keeps rejection inside the server, where it has a documented error code.
      # The client already downscales every shot to 1024px @ q80 (~2 MB of base64 for a full
      # eight-shot plate), so this ceiling is not reachable in normal use.
      MAX_SHOTS         = "8"
      MAX_REQUEST_BYTES = "5242880"
    }
  }

  # Without this the first deploy races: Lambda creates the group itself on first invoke,
  # and the aws_cloudwatch_log_group resource then fails as already-existing.
  depends_on = [aws_cloudwatch_log_group.plated]
}

resource "aws_lambda_function_url" "plated" {
  function_name = aws_lambda_function.plated.function_name

  # The gate is the server's own constant-time bearer check on PLATE_API_TOKEN, not IAM:
  # the client is a phone with a compile-time token, and AWS_IAM would mean shipping SigV4
  # credentials in the app. This is what PLATE_API_TOKEN was built for.
  authorization_type = "NONE"
}

# AuthType=NONE still needs an explicit resource policy — creating the URL config alone
# leaves every request 403ing. The console adds this silently; Terraform does not.
resource "aws_lambda_permission" "plated_url" {
  statement_id           = "AllowPublicFunctionUrlInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.plated.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
