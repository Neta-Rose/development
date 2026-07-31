# The role GitHub Actions assumes to deploy the server.
#
# Scoped to one branch of one repository, and to the resources the app stack actually
# manages. Notably it holds no IAM write permission at all — see iam-lambda.tf.

resource "aws_iam_role" "deploy" {
  name               = "${var.name_prefix}-deploy"
  assume_role_policy = data.aws_iam_policy_document.deploy_assume.json
}

data "aws_iam_policy_document" "deploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # One branch only. Pull requests are absent from this list by design: the PR job runs
    # `terraform validate`, which needs no credentials, so a PR cannot reach AWS even if a
    # workflow file in it asks to.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/${var.deploy_branch}",
      ]
    }
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.name_prefix}-deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}

data "aws_iam_policy_document" "deploy" {
  # Remote state.
  statement {
    sid       = "TerraformState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid    = "TerraformStateObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  # ECR. GetAuthorizationToken is account-wide because the token is not repository-scoped.
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Push and read only. The repository itself is created in this stack (ecr.tf), so the
  # deploy role cannot create, reconfigure or delete one.
  statement {
    sid    = "EcrPushAndRead"
    effect = "Allow"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "ecr:GetLifecyclePolicy",
      # Image push.
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.name_prefix}-*"]
  }

  statement {
    sid    = "Lambda"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:DeleteFunction",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:ListTags",
      "lambda:PutFunctionConcurrency",
      "lambda:DeleteFunctionConcurrency",
      "lambda:GetFunctionUrlConfig",
      "lambda:CreateFunctionUrlConfig",
      "lambda:UpdateFunctionUrlConfig",
      "lambda:DeleteFunctionUrlConfig",
      # The AuthType=NONE function URL needs a resource policy granting InvokeFunctionUrl.
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy",
    ]
    resources = ["arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.name_prefix}-*"]
  }

  # The whole of the deploy role's IAM power: hand this one role to Lambda, nothing else.
  statement {
    sid       = "PassExecutionRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.lambda_exec.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:ListTagsForResource",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name_prefix}-*"]
  }
}
