# =======================================================
# VPC Outputs
# =======================================================
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "db_subnet_ids" {
  description = "Private subnet IDs (backward compatibility alias)"
  value       = module.vpc.db_subnet_ids
}

# =======================================================
# Security Group Outputs
# =======================================================
output "alb_sg_id" {
  description = "ALB security group ID"
  value       = module.security.alb_sg_id
}

output "ecs_sg_id" {
  description = "ECS security group ID"
  value       = module.security.ecs_sg_id
}

output "db_sg_id" {
  description = "Database security group ID"
  value       = module.security.db_sg_id
}

# =======================================================
# ECR Outputs
# =======================================================
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.ecr.repository_urls
}

# =======================================================
# Database Outputs
# =======================================================
output "db_endpoint" {
  description = "Database endpoint"
  value       = module.database.db_endpoint
  sensitive   = false
}

output "db_port" {
  description = "Database port"
  value       = module.database.db_port
}

output "db_endpoints" {
  description = "Map of database endpoints"
  value       = module.database.db_endpoints
}

# =======================================================
# ECS Outputs
# =======================================================
output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.ecs.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = module.ecs.alb_zone_id
}

output "load_balancer_dns_names" {
  description = "Map of load balancer DNS names"
  value       = module.ecs.load_balancer_dns_names
}

