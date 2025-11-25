locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# =======================================================
# VPC Module
# =======================================================
module "vpc" {
  source = "./modules/vpc"

  name_prefix = local.name_prefix
  aws_region  = var.aws_region
  vpc_cidr    = var.vpc_cidr

  public_subnets         = var.public_subnets
  public_subnet_newbits  = var.public_subnet_newbits
  private_subnets        = var.private_subnets
  private_subnet_newbits = var.private_subnet_newbits

  tags = var.tags
}

# =======================================================
# Security Groups Module
# =======================================================

module "security" {
  source = "./modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  app_port    = var.app_port

  security_groups = {
    alb = {
      name        = "alb-sg"
      description = "Security group for Application Load Balancer"
      ingress_rules = [
        {
          description = "HTTP from internet"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          description = "HTTPS from internet"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress_rules = [
        {
          description = "Allow all outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    ecs = {
      name        = "ecs-sg"
      description = "Security group for ECS tasks"
      ingress_rules = [
        {
          description     = "Allow traffic from ALB"
          from_port       = var.app_port
          to_port         = var.app_port
          protocol        = "tcp"
          security_groups = ["alb"]
        }
      ]
      egress_rules = [
        {
          description = "Allow all outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
    db = {
      name        = "db-sg"
      description = "Security group for RDS database"
      ingress_rules = [
        {
          description     = "PostgreSQL from ECS"
          from_port       = 5432
          to_port         = 5432
          protocol        = "tcp"
          security_groups = ["ecs"]
        }
      ]
      egress_rules = [
        {
          description = "Allow all outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  }

  tags = var.tags
}

# =======================================================
# ECR Module
# =======================================================

module "ecr" {
  source = "./modules/ecr"

  name_prefix = local.name_prefix
  environment = var.environment

  repositories = {
    backend = {
      name                 = "${local.name_prefix}-backend"
      image_tag_mutability = var.ecr_image_tag_mutability
      scan_on_push         = var.ecr_scan_on_push
      tags                 = var.tags
    }
  }

  tags = var.tags
}

# =======================================================
# Database Module
# =======================================================

module "database" {
  source = "./modules/database"

  name_prefix       = local.name_prefix
  db_subnet_ids     = module.vpc.private_subnet_ids
  db_sg_id          = module.security.db_sg_id
  subnet_group_name = ""

  databases = {
    postgres = {
      identifier                      = "${local.name_prefix}-db"
      engine                          = var.db_engine
      engine_version                  = var.db_engine_version
      instance_class                  = var.db_instance_class
      allocated_storage               = var.db_allocated_storage
      max_allocated_storage           = var.db_max_allocated_storage
      storage_type                    = var.db_storage_type
      storage_encrypted               = var.db_storage_encrypted
      username                        = var.db_username
      password                        = var.db_password
      publicly_accessible             = var.db_publicly_accessible
      skip_final_snapshot             = var.db_skip_final_snapshot
      final_snapshot_identifier       = var.db_final_snapshot_identifier
      backup_retention_period         = var.db_backup_retention_period
      backup_window                   = var.db_backup_window
      maintenance_window              = var.db_maintenance_window
      multi_az                        = var.db_multi_az
      deletion_protection             = var.db_deletion_protection
      enabled_cloudwatch_logs_exports = var.db_enabled_cloudwatch_logs_exports
      parameter_group_name            = var.db_parameter_group_name
      tags                            = var.tags
    }
  }

  tags = var.tags
}

# =======================================================
# ECS Module
# =======================================================

module "ecs" {
  source = "./modules/ecs"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  ecs_sg_id         = module.security.ecs_sg_id
  aws_region        = var.aws_region
  environment       = var.environment

  cluster_config = {
    name               = "${local.name_prefix}-cluster"
    container_insights = var.ecs_container_insights
    tags               = var.tags
  }

  iam_roles = {
    task_execution = {
      name                = "ecs-execution-role"
      managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
      tags                = var.tags
    }
    task = {
      name = "ecs-task-role"
      tags = var.tags
    }
  }

  log_groups = {
    ecs = {
      name              = "/ecs/${local.name_prefix}-backend"
      retention_in_days = var.ecs_log_retention_days
      tags              = var.tags
    }
  }

  load_balancers = {
    main = {
      name                             = "${local.name_prefix}-alb"
      internal                         = var.alb_internal
      load_balancer_type               = var.alb_type
      idle_timeout                     = var.alb_idle_timeout
      enable_deletion_protection       = var.alb_enable_deletion_protection
      enable_http2                     = var.alb_enable_http2
      enable_cross_zone_load_balancing = var.alb_enable_cross_zone_load_balancing
      tags                             = var.tags
    }
  }

  target_groups = {
    backend = {
      name                 = "${local.name_prefix}-tg"
      port                 = var.app_port
      protocol             = var.alb_target_group_protocol
      vpc_id               = module.vpc.vpc_id
      target_type          = var.alb_target_group_type
      deregistration_delay = var.alb_target_group_deregistration_delay
      health_check = {
        enabled             = var.alb_health_check_enabled
        healthy_threshold   = var.alb_health_check_healthy_threshold
        unhealthy_threshold = var.alb_health_check_unhealthy_threshold
        timeout             = var.alb_health_check_timeout
        interval            = var.alb_health_check_interval
        path                = var.alb_health_check_path
        matcher             = var.alb_health_check_matcher
        port                = var.alb_health_check_port
        protocol            = var.alb_health_check_protocol
      }
      tags = var.tags
    }
  }

  listeners = {
    http = {
      load_balancer_key = "main"
      port              = var.alb_listener_port
      protocol          = var.alb_listener_protocol
      ssl_policy        = var.alb_listener_ssl_policy
      certificate_arn   = var.alb_listener_certificate_arn
      default_action = {
        type             = "forward"
        target_group_key = "backend"
      }
      tags = var.tags
    }
  }

  task_definitions = {
    backend = {
      family                   = "${local.name_prefix}-task"
      cpu                      = var.ecs_task_cpu
      memory                   = var.ecs_task_memory
      network_mode             = var.ecs_task_network_mode
      requires_compatibilities = var.ecs_task_requires_compatibilities
      execution_role_arn       = null # Will use task_execution role from iam_roles
      task_role_arn            = null # Will use task role from iam_roles
      container_definitions = [
        {
          name      = "backend"
          image     = var.container_image
          essential = true
          portMappings = [
            {
              containerPort = var.app_port
              hostPort      = var.app_port
              protocol      = "tcp"
            }
          ]
          environment = concat(
            [
              { name = "APP_ENV", value = var.environment },
              { name = "PORT", value = tostring(var.app_port) },
              { name = "DB_HOST", value = module.database.db_endpoints["postgres"] },
              { name = "DB_PORT", value = tostring(module.database.db_ports["postgres"]) },
            ],
            var.ecs_container_environment
          )
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "/ecs/${local.name_prefix}-backend"
              awslogs-region        = var.aws_region
              awslogs-stream-prefix = "ecs"
            }
          }
          healthCheck = var.ecs_container_health_check
          cpu         = var.ecs_container_cpu
          memory      = var.ecs_container_memory
        }
      ]
      tags = var.tags
    }
  }

  services = {
    backend = {
      name                = "${local.name_prefix}-service"
      task_definition_key = "backend"
      desired_count       = var.ecs_service_desired_count
      launch_type         = var.ecs_service_launch_type
      platform_version    = var.ecs_service_platform_version
      network_configuration = {
        subnets          = module.vpc.public_subnet_ids
        security_groups  = [module.security.ecs_sg_id]
        assign_public_ip = var.ecs_service_assign_public_ip
      }
      load_balancer = {
        target_group_key = "backend"
        container_name   = "backend"
        container_port   = var.app_port
      }
      deployment_configuration = {
        maximum_percent         = var.ecs_deployment_maximum_percent
        minimum_healthy_percent = var.ecs_deployment_minimum_healthy_percent
        deployment_circuit_breaker = {
          enable   = var.ecs_deployment_circuit_breaker_enable
          rollback = var.ecs_deployment_circuit_breaker_rollback
        }
      }
      enable_execute_command = var.ecs_service_enable_execute_command
      enable_logging         = true
      log_group_name         = "/ecs/${local.name_prefix}-backend"
      log_retention_days     = var.ecs_log_retention_days
      tags                   = var.tags
    }
  }

  tags = var.tags
}