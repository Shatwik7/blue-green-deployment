variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "active_color" {
  type = string

  validation {
    condition     = contains(["blue", "green"], var.active_color)
    error_message = "active_color must be either blue or green."
  }
}
