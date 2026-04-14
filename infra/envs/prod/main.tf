data "aws_availability_zones" "available" {
  state = "available"
}

module "network" {
  source = "../../modules/network"

  project_name       = var.project_name
  environment        = var.environment
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "ecr" {
  source = "../../modules/ecr"

  project_name      = var.project_name
  environment       = var.environment
  create_repository = false
  repository_name   = "${var.project_name}-${var.environment}-frontend"
}

locals {
  blue_image_uri  = "${module.ecr.repository_url}:${var.blue_image_tag}"
  green_image_uri = "${module.ecr.repository_url}:${var.green_image_tag}"
}

module "load_balancer" {
  source = "../../modules/load_balancer"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.network.vpc_id
  subnet_ids   = module.network.public_subnet_ids
  active_color = var.active_color
}

module "compute" {
  source = "../../modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  vpc_id                 = module.network.vpc_id
  subnet_ids             = module.network.public_subnet_ids
  alb_security_group_id  = module.load_balancer.alb_security_group_id
  blue_target_group_arn  = module.load_balancer.blue_target_group_arn
  green_target_group_arn = module.load_balancer.green_target_group_arn
  blue_image_uri         = local.blue_image_uri
  green_image_uri        = local.green_image_uri
  instance_type          = var.instance_type
  blue_desired_capacity  = var.blue_desired_capacity
  green_desired_capacity = var.green_desired_capacity
}
