# The image repository lives here rather than in the app stack for two reasons: the image
# must exist before the app stack can reference its tag (so the app stack cannot be the thing
# that creates it), and keeping it here means the deploy role needs no ecr:CreateRepository —
# only push and read.

resource "aws_ecr_repository" "plated" {
  name = "${var.name_prefix}-plated"

  # Deploys reference an exact git SHA, so a tag must never be repointed underneath a
  # deployed function.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Untagged layers accumulate on every rebuild and ECR storage is billed per GB.
resource "aws_ecr_lifecycle_policy" "plated" {
  repository = aws_ecr_repository.plated.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after a day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the 10 most recent images; older ones are still rollback targets in git"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      },
    ]
  })
}
