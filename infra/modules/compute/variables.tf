variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "blue_target_group_arn" {
  type = string
}

variable "green_target_group_arn" {
  type = string
}

variable "blue_image_uri" {
  type = string
}

variable "green_image_uri" {
  type = string
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
