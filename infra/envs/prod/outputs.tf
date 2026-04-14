output "alb_dns_name" {
  value = module.load_balancer.alb_dns_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "active_color" {
  value = var.active_color
}
