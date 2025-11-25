variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "app_port" {
  description = "Application port for ECS tasks"
  type        = number
}

variable "security_groups" {
  description = "Map of security groups to create"
  type = map(object({
    name        = string
    description = string
    ingress_rules = list(object({
      description     = optional(string)
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string))
      security_groups = optional(list(string))
      self            = optional(bool)
    }))
    egress_rules = list(object({
      description = optional(string)
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string))
      security_groups = optional(list(string))
      self        = optional(bool)
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
