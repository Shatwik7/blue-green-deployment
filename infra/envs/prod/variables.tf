variable "aws_region" {
  type = string
}

variable "project_name" {
  type    = string
  default = "react-bluegreen"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "active_color" {
  type    = string
  default = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_color)
    error_message = "active_color must be blue or green."
  }
}

variable "blue_image_tag" {
  type    = string
  default = "latest"
}

variable "green_image_tag" {
  type    = string
  default = "latest"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "blue_desired_capacity" {
  type    = number
  default = 1
}

variable "green_desired_capacity" {
  type    = number
  default = 0
}
