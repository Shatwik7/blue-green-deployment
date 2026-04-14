variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "create_repository" {
  description = "Whether Terraform should create the ECR repository"
  type        = bool
  default     = true
}

variable "repository_name" {
  description = "Optional explicit ECR repository name"
  type        = string
  default     = null
}
