output "repository_name" {
  value = var.create_repository ? aws_ecr_repository.this[0].name : data.aws_ecr_repository.existing[0].name
}

output "repository_url" {
  value = var.create_repository ? aws_ecr_repository.this[0].repository_url : data.aws_ecr_repository.existing[0].repository_url
}
