variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
}

variable "project_name" {
  description = "Project prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "shared"
}
