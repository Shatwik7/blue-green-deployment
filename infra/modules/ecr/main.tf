locals {
  effective_repository_name = var.repository_name != null ? var.repository_name : "${var.project_name}-${var.environment}-frontend"
}

resource "aws_ecr_repository" "this" {
  count = var.create_repository ? 1 : 0

  name                 = local.effective_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

data "aws_ecr_repository" "existing" {
  count = var.create_repository ? 0 : 1

  name = local.effective_repository_name
}
