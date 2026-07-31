# The Lambda execution role.
#
# It lives in the bootstrap stack, not the app stack, on purpose: if the app stack created
# it then the deploy role would need iam:CreateRole/AttachRolePolicy, which is close enough
# to account admin to make the OIDC trust boundary meaningless. Here the deploy role gets
# nothing but iam:PassRole on this one ARN.

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.name_prefix}-plated-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# CloudWatch Logs and nothing else. The detector talks to exactly one thing — OpenRouter,
# over the public internet — and touches no AWS API, so it needs no other grant.
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
