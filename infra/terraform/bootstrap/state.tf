# Remote state for the app stack.
#
# Versioned because a corrupted apply is recoverable from an earlier object version, and
# encrypted + fully private because the app stack's state contains OPENROUTER_API_KEY and
# PLATE_API_TOKEN: Lambda cannot source an env var from a secret ARN the way ECS can, so
# the values necessarily pass through Terraform. This bucket is the thing protecting them.
#
# No DynamoDB lock table: the app stack's backend uses S3 native locking (use_lockfile),
# which needs nothing but the bucket.

resource "aws_s3_bucket" "state" {
  bucket = "${var.name_prefix}-tfstate-${data.aws_caller_identity.current.account_id}"

  # State is the one thing worth keeping if this stack is ever torn down.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Belt and braces on a bucket holding secrets: reject any request that is not over TLS.
resource "aws_s3_bucket_policy" "state_tls_only" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_tls_only.json
}

data "aws_iam_policy_document" "state_tls_only" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
