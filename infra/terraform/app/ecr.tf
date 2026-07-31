# Created by the bootstrap stack, because the image has to be pushable before this stack has
# ever run. Read here only to build the image URI.
data "aws_ecr_repository" "plated" {
  name = local.name
}
