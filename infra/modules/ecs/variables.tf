variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB and ECS tasks"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_config" {
  description = "ECS cluster configuration"
  type = object({
    name               = optional(string)
    container_insights = optional(bool)
    tags               = optional(map(string))
  })
  default = {
    container_insights = true
  }
}

variable "load_balancers" {
  description = "Map of load balancers to create"
  type = map(object({
    name               = string
    internal           = optional(bool)
    load_balancer_type = optional(string)
    idle_timeout       = optional(number)
    enable_deletion_protection = optional(bool)
    enable_http2       = optional(bool)
    enable_cross_zone_load_balancing = optional(bool)
    tags               = optional(map(string))
  }))
  default = {}
}

variable "target_groups" {
  description = "Map of target groups to create"
  type = map(object({
    name                 = string
    port                 = number
    protocol             = optional(string)
    vpc_id               = optional(string)
    target_type          = optional(string)
    deregistration_delay = optional(number)
    health_check = optional(object({
      enabled             = optional(bool)
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
      timeout             = optional(number)
      interval            = optional(number)
      path                = optional(string)
      matcher             = optional(string)
      port                = optional(string)
      protocol            = optional(string)
    }))
    stickiness = optional(object({
      enabled         = optional(bool)
      type            = optional(string)
      cookie_duration = optional(number)
    }))
    tags = optional(map(string))
  }))
  default = {}
}

variable "listeners" {
  description = "Map of load balancer listeners"
  type = map(object({
    load_balancer_key = string
    port              = number
    protocol          = optional(string)
    ssl_policy        = optional(string)
    certificate_arn   = optional(string)
    default_action = object({
      type             = string
      target_group_key = optional(string)
      redirect = optional(object({
        port        = optional(string)
        protocol    = optional(string)
        status_code = optional(string)
        host        = optional(string)
        path        = optional(string)
        query       = optional(string)
      }))
      fixed_response = optional(object({
        content_type = string
        message_body = optional(string)
        status_code  = optional(string)
      }))
    })
    tags = optional(map(string))
  }))
  default = {}
}

variable "task_definitions" {
  description = "Map of ECS task definitions"
  type = map(object({
    family                   = string
    cpu                      = optional(string)
    memory                   = optional(string)
    network_mode             = optional(string)
    requires_compatibilities = optional(list(string))
    execution_role_arn       = optional(string)
    task_role_arn            = optional(string)
    container_definitions = list(object({
      name      = string
      image     = string
      essential = optional(bool)
      portMappings = optional(list(object({
        containerPort = number
        hostPort      = optional(number)
        protocol      = optional(string)
      })))
      environment = optional(list(object({
        name  = string
        value = string
      })))
      secrets = optional(list(object({
        name      = string
        valueFrom = string
      })))
      logConfiguration = optional(object({
        logDriver = string
        options   = map(string)
      }))
      healthCheck = optional(object({
        command     = list(string)
        interval    = optional(number)
        timeout     = optional(number)
        retries     = optional(number)
        startPeriod = optional(number)
      }))
      cpu    = optional(number)
      memory = optional(number)
    }))
    tags = optional(map(string))
  }))
  default = {}
}

variable "services" {
  description = "Map of ECS services to create"
  type = map(object({
    name            = string
    cluster_key     = optional(string)
    task_definition_key = string
    desired_count   = optional(number)
    launch_type     = optional(string)
    platform_version = optional(string)
    network_configuration = object({
      subnets         = list(string)
      security_groups = list(string)
      assign_public_ip = optional(bool)
    })
    load_balancer = optional(object({
      target_group_key = string
      container_name   = string
      container_port   = number
    }))
    deployment_configuration = optional(object({
      maximum_percent         = optional(number)
      minimum_healthy_percent = optional(number)
      deployment_circuit_breaker = optional(object({
        enable   = optional(bool)
        rollback = optional(bool)
      }))
    }))
    enable_execute_command = optional(bool)
    enable_logging         = optional(bool)
    log_group_name         = optional(string)
    log_retention_days     = optional(number)
    tags                   = optional(map(string))
  }))
  default = {}
}

variable "iam_roles" {
  description = "Map of IAM roles to create for ECS"
  type = map(object({
    name                 = string
    assume_role_policy   = optional(string)
    managed_policy_arns  = optional(list(string))
    inline_policies      = optional(map(string))
    tags                 = optional(map(string))
  }))
  default = {}
}

variable "log_groups" {
  description = "Map of CloudWatch log groups to create"
  type = map(object({
    name              = string
    retention_in_days = optional(number)
    kms_key_id        = optional(string)
    tags              = optional(map(string))
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
