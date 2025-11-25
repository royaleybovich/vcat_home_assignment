variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Base project name"
  type        = string
  default     = "user-mgmt"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =======================================================
# VPC Variables
# =======================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets. CIDR blocks are calculated using cidrsubnet() function."
  type = map(object({
    subnet_number            = number
    availability_zone_suffix = string
    map_public_ip_on_launch  = bool
  }))
  default = {
    "a" = {
      subnet_number            = 1
      availability_zone_suffix = "a"
      map_public_ip_on_launch  = true
    }
    "b" = {
      subnet_number            = 2
      availability_zone_suffix = "b"
      map_public_ip_on_launch  = true
    }
  }
}

variable "public_subnet_newbits" {
  description = "Number of additional bits to add to VPC CIDR prefix for public subnets (e.g., 8 for /24 subnets from /16 VPC)"
  type        = number
  default     = 8
}

variable "private_subnets" {
  description = "Map of private subnets. CIDR blocks are calculated using cidrsubnet() function."
  type = map(object({
    subnet_number            = number
    availability_zone_suffix = string
    map_public_ip_on_launch  = bool
  }))
  default = {
    "a" = {
      subnet_number            = 11
      availability_zone_suffix = "a"
      map_public_ip_on_launch  = false
    }
    "b" = {
      subnet_number            = 12
      availability_zone_suffix = "b"
      map_public_ip_on_launch  = false
    }
  }
}

variable "private_subnet_newbits" {
  description = "Number of additional bits to add to VPC CIDR prefix for private subnets (e.g., 8 for /24 subnets from /16 VPC)"
  type        = number
  default     = 8
}

# =======================================================
# Database Variables
# =======================================================
variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version. Available versions vary by region. Common versions: 15.15, 16.11"
  type        = string
  default     = "15.15"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling (GB)"
  type        = number
  default     = null
}

variable "db_storage_type" {
  description = "Database storage type"
  type        = string
  default     = "gp3"
}

variable "db_storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "db_publicly_accessible" {
  description = "Make database publicly accessible"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = true
}

variable "db_final_snapshot_identifier" {
  description = "Final snapshot identifier"
  type        = string
  default     = null
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "db_enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "db_parameter_group_name" {
  description = "Parameter group name"
  type        = string
  default     = null
}

# =======================================================
# ECR Variables
# =======================================================
variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable ECR scan on push"
  type        = bool
  default     = true
}

# =======================================================
# ECS Variables
# =======================================================
variable "app_port" {
  description = "Application container port"
  type        = number
  default     = 3000
}

variable "container_image" {
  description = "Backend container image (ECR URI with tag)"
  type        = string
  default     = "REPLACE_ME_ECR_IMAGE"
}

variable "ecs_container_insights" {
  description = "Enable ECS container insights"
  type        = bool
  default     = true
}

variable "ecs_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "ecs_task_cpu" {
  description = "ECS task CPU units"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "ECS task memory (MB)"
  type        = string
  default     = "512"
}

variable "ecs_task_network_mode" {
  description = "ECS task network mode"
  type        = string
  default     = "awsvpc"
}

variable "ecs_task_requires_compatibilities" {
  description = "ECS task requires compatibilities"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "ecs_container_environment" {
  description = "Additional container environment variables"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "ecs_container_health_check" {
  description = "Container health check configuration"
  type = object({
    command     = list(string)
    interval    = optional(number)
    timeout     = optional(number)
    retries     = optional(number)
    startPeriod = optional(number)
  })
  default = null
}

variable "ecs_container_cpu" {
  description = "Container CPU units"
  type        = number
  default     = null
}

variable "ecs_container_memory" {
  description = "Container memory (MB)"
  type        = number
  default     = null
}

variable "ecs_service_desired_count" {
  description = "ECS service desired count"
  type        = number
  default     = 1
}

variable "ecs_service_launch_type" {
  description = "ECS service launch type"
  type        = string
  default     = "FARGATE"
}

variable "ecs_service_platform_version" {
  description = "ECS service platform version"
  type        = string
  default     = "LATEST"
}

variable "ecs_service_assign_public_ip" {
  description = "Assign public IP to ECS tasks"
  type        = bool
  default     = true
}

variable "ecs_deployment_maximum_percent" {
  description = "Maximum deployment percent"
  type        = number
  default     = 200
}

variable "ecs_deployment_minimum_healthy_percent" {
  description = "Minimum healthy deployment percent"
  type        = number
  default     = 100
}

variable "ecs_deployment_circuit_breaker_enable" {
  description = "Enable deployment circuit breaker"
  type        = bool
  default     = false
}

variable "ecs_deployment_circuit_breaker_rollback" {
  description = "Enable deployment circuit breaker rollback"
  type        = bool
  default     = false
}

variable "ecs_service_enable_execute_command" {
  description = "Enable ECS execute command"
  type        = bool
  default     = false
}

# =======================================================
# ALB Variables
# =======================================================
variable "alb_internal" {
  description = "Create internal ALB"
  type        = bool
  default     = false
}

variable "alb_type" {
  description = "ALB type"
  type        = string
  default     = "application"
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "alb_enable_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "alb_enable_http2" {
  description = "Enable HTTP/2 on ALB"
  type        = bool
  default     = true
}

variable "alb_enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "alb_target_group_protocol" {
  description = "Target group protocol"
  type        = string
  default     = "HTTP"
}

variable "alb_target_group_type" {
  description = "Target group type"
  type        = string
  default     = "ip"
}

variable "alb_target_group_deregistration_delay" {
  description = "Target group deregistration delay in seconds"
  type        = number
  default     = 300
}

variable "alb_health_check_enabled" {
  description = "Enable health check"
  type        = bool
  default     = true
}

variable "alb_health_check_healthy_threshold" {
  description = "Health check healthy threshold"
  type        = number
  default     = 2
}

variable "alb_health_check_unhealthy_threshold" {
  description = "Health check unhealthy threshold"
  type        = number
  default     = 2
}

variable "alb_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "alb_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "alb_health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "alb_health_check_matcher" {
  description = "Health check matcher (HTTP status codes)"
  type        = string
  default     = "200-399"
}

variable "alb_health_check_port" {
  description = "Health check port"
  type        = string
  default     = "traffic-port"
}

variable "alb_health_check_protocol" {
  description = "Health check protocol"
  type        = string
  default     = "HTTP"
}

variable "alb_listener_port" {
  description = "ALB listener port"
  type        = number
  default     = 80
}

variable "alb_listener_protocol" {
  description = "ALB listener protocol"
  type        = string
  default     = "HTTP"
}

variable "alb_listener_ssl_policy" {
  description = "ALB listener SSL policy (for HTTPS)"
  type        = string
  default     = null
}

variable "alb_listener_certificate_arn" {
  description = "ALB listener certificate ARN (for HTTPS)"
  type        = string
  default     = null
}
