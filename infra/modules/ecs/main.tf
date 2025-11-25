# CloudWatch log groups
resource "aws_cloudwatch_log_group" "this" {
  for_each = var.log_groups

  name              = each.value.name
  retention_in_days = each.value.retention_in_days != null ? each.value.retention_in_days : 7
  kms_key_id        = each.value.kms_key_id

  tags = merge(
    {
      Name = each.value.name
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

# IAM roles
resource "aws_iam_role" "this" {
  for_each = var.iam_roles

  name = "${var.name_prefix}-${each.value.name}"

  assume_role_policy = each.value.assume_role_policy != null ? each.value.assume_role_policy : jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name = "${var.name_prefix}-${each.value.name}"
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = merge([
    for role_key, role in var.iam_roles : {
      for policy_arn in role.managed_policy_arns != null ? role.managed_policy_arns : [] :
      "${role_key}-${policy_arn}" => {
        role_key   = role_key
        policy_arn = policy_arn
      }
    }
  ]...)

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy" "inline" {
  for_each = merge([
    for role_key, role in var.iam_roles : {
      for policy_name, policy_doc in role.inline_policies != null ? role.inline_policies : {} :
      "${role_key}-${policy_name}" => {
        role_key    = role_key
        policy_name = policy_name
        policy      = policy_doc
      }
    }
  ]...)

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.role_key].id
  policy = each.value.policy
}

# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_config.name != null ? var.cluster_config.name : "${var.name_prefix}-cluster"

  dynamic "setting" {
    for_each = var.cluster_config.container_insights != null && var.cluster_config.container_insights ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }

  tags = merge(
    {
      Name = var.cluster_config.name != null ? var.cluster_config.name : "${var.name_prefix}-cluster"
    },
    var.cluster_config.tags != null ? var.cluster_config.tags : {},
    var.tags
  )
}

# Load balancers
resource "aws_lb" "this" {
  for_each = var.load_balancers

  name               = each.value.name
  internal           = each.value.internal != null ? each.value.internal : false
  load_balancer_type = each.value.load_balancer_type != null ? each.value.load_balancer_type : "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]
  idle_timeout       = each.value.idle_timeout
  enable_deletion_protection = each.value.enable_deletion_protection != null ? each.value.enable_deletion_protection : false
  enable_http2       = each.value.enable_http2 != null ? each.value.enable_http2 : true
  enable_cross_zone_load_balancing = each.value.enable_cross_zone_load_balancing != null ? each.value.enable_cross_zone_load_balancing : true

  tags = merge(
    {
      Name = each.value.name
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

# Target groups
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = each.value.name
  port                 = each.value.port
  protocol             = each.value.protocol != null ? each.value.protocol : "HTTP"
  vpc_id               = each.value.vpc_id != null ? each.value.vpc_id : var.vpc_id
  target_type          = each.value.target_type != null ? each.value.target_type : "ip"
  deregistration_delay = each.value.deregistration_delay

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []
    content {
      enabled             = health_check.value.enabled != null ? health_check.value.enabled : true
      healthy_threshold   = health_check.value.healthy_threshold != null ? health_check.value.healthy_threshold : 2
      unhealthy_threshold = health_check.value.unhealthy_threshold != null ? health_check.value.unhealthy_threshold : 2
      timeout             = health_check.value.timeout != null ? health_check.value.timeout : 5
      interval            = health_check.value.interval != null ? health_check.value.interval : 30
      path                = health_check.value.path != null ? health_check.value.path : "/"
      matcher             = health_check.value.matcher != null ? health_check.value.matcher : "200"
      port                = health_check.value.port != null ? health_check.value.port : "traffic-port"
      protocol            = health_check.value.protocol != null ? health_check.value.protocol : "HTTP"
    }
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      enabled         = stickiness.value.enabled != null ? stickiness.value.enabled : false
      type            = stickiness.value.type != null ? stickiness.value.type : "lb_cookie"
      cookie_duration = stickiness.value.cookie_duration
    }
  }

  tags = merge(
    {
      Name = each.value.name
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

# Listeners
resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this[each.value.load_balancer_key].arn
  port              = each.value.port
  protocol          = each.value.protocol != null ? each.value.protocol : "HTTP"
  ssl_policy        = each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn

  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      type = default_action.value.type
      target_group_arn = default_action.value.type == "forward" && default_action.value.target_group_key != null ? aws_lb_target_group.this[default_action.value.target_group_key].arn : null

      dynamic "redirect" {
        for_each = default_action.value.type == "redirect" && default_action.value.redirect != null ? [default_action.value.redirect] : []
        content {
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code != null ? redirect.value.status_code : "HTTP_301"
          host        = redirect.value.host
          path        = redirect.value.path
          query       = redirect.value.query
        }
      }

      dynamic "fixed_response" {
        for_each = default_action.value.type == "fixed-response" && default_action.value.fixed_response != null ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code != null ? fixed_response.value.status_code : "200"
        }
      }
    }
  }

  tags = merge(
    {
      Name = "${each.value.load_balancer_key}-listener-${each.value.port}"
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

# Task definitions
resource "aws_ecs_task_definition" "this" {
  for_each = var.task_definitions

  family                   = each.value.family
  cpu                      = each.value.cpu != null ? each.value.cpu : "256"
  memory                   = each.value.memory != null ? each.value.memory : "512"
  network_mode             = each.value.network_mode != null ? each.value.network_mode : "awsvpc"
  requires_compatibilities = each.value.requires_compatibilities != null ? each.value.requires_compatibilities : ["FARGATE"]
  execution_role_arn       = each.value.execution_role_arn != null ? each.value.execution_role_arn : (length(var.iam_roles) > 0 && contains(keys(var.iam_roles), "task_execution") ? aws_iam_role.this["task_execution"].arn : null)
  task_role_arn            = each.value.task_role_arn != null ? each.value.task_role_arn : (length(var.iam_roles) > 0 && contains(keys(var.iam_roles), "task") ? aws_iam_role.this["task"].arn : null)

  container_definitions = jsonencode(each.value.container_definitions)

  tags = merge(
    {
      Name = each.value.family
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

# ECS services
resource "aws_ecs_service" "this" {
  for_each = var.services

  name            = each.value.name
  cluster         = each.value.cluster_key != null ? aws_ecs_cluster.this[each.value.cluster_key].id : aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.value.task_definition_key].arn
  desired_count   = each.value.desired_count != null ? each.value.desired_count : 1
  launch_type     = each.value.launch_type != null ? each.value.launch_type : "FARGATE"
  platform_version = each.value.platform_version

  network_configuration {
    subnets          = each.value.network_configuration.subnets
    security_groups  = each.value.network_configuration.security_groups
    assign_public_ip = each.value.network_configuration.assign_public_ip != null ? each.value.network_configuration.assign_public_ip : true
  }

  dynamic "load_balancer" {
    for_each = each.value.load_balancer != null ? [each.value.load_balancer] : []
    content {
      target_group_arn = aws_lb_target_group.this[load_balancer.value.target_group_key].arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  # Deployment configuration - these are direct attributes, not a block
  deployment_maximum_percent         = try(each.value.deployment_configuration.maximum_percent, 200)
  deployment_minimum_healthy_percent = try(each.value.deployment_configuration.minimum_healthy_percent, 100)
  enable_execute_command = each.value.enable_execute_command != null ? each.value.enable_execute_command : false

  depends_on = [
    aws_lb_listener.this
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(
    {
      Name = each.value.name
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

# =======================================================
# OUTPUTS
# =======================================================

output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "load_balancer_dns_names" {
  description = "Map of load balancer DNS names by key"
  value       = { for k, v in aws_lb.this : k => v.dns_name }
}

output "load_balancer_zone_ids" {
  description = "Map of load balancer zone IDs by key"
  value       = { for k, v in aws_lb.this : k => v.zone_id }
}

output "load_balancer_arns" {
  description = "Map of load balancer ARNs by key"
  value       = { for k, v in aws_lb.this : k => v.arn }
}

output "target_group_arns" {
  description = "Map of target group ARNs by key"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "task_definition_arns" {
  description = "Map of task definition ARNs by key"
  value       = { for k, v in aws_ecs_task_definition.this : k => v.arn }
}

output "service_names" {
  description = "Map of service names by key"
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "iam_role_arns" {
  description = "Map of IAM role ARNs by key"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "log_group_names" {
  description = "Map of log group names by key"
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.name }
}

# Convenience outputs for backward compatibility
output "alb_dns_name" {
  description = "ALB DNS name (first load balancer if multiple)"
  value       = try(values(aws_lb.this)[0].dns_name, null)
}

output "alb_zone_id" {
  description = "ALB zone ID (first load balancer if multiple)"
  value       = try(values(aws_lb.this)[0].zone_id, null)
}
