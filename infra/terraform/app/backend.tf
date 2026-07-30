# Partial backend config: bucket and region come from `terraform init -backend-config=...`
# in the deploy workflow, so the bucket name (which embeds the account id) is not committed.
#
# use_lockfile is S3 native locking, available since Terraform 1.10. It replaces the
# DynamoDB table the S3 backend used to need, so the bootstrap stack creates only a bucket.

terraform {
  backend "s3" {
    key          = "plated/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
