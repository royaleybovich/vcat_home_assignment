variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "db_subnet_ids" {
  description = "List of subnet IDs for database subnet group"
  type        = list(string)
}

variable "db_sg_id" {
  description = "Security group ID for database"
  type        = string
}

variable "databases" {
  description = "Map of databases to create"
  type = map(object({
    identifier              = string
    engine                  = string
    engine_version          = string
    instance_class          = string
    allocated_storage       = number
    max_allocated_storage   = optional(number)
    storage_type            = optional(string)
    storage_encrypted       = optional(bool)
    username                = string
    password                = string
    publicly_accessible     = optional(bool)
    skip_final_snapshot     = optional(bool)
    final_snapshot_identifier = optional(string)
    backup_retention_period = optional(number)
    backup_window           = optional(string)
    maintenance_window      = optional(string)
    multi_az                = optional(bool)
    deletion_protection     = optional(bool)
    enabled_cloudwatch_logs_exports = optional(list(string))
    parameter_group_name    = optional(string)
    tags                    = optional(map(string))
  }))
}

variable "subnet_group_name" {
  description = "Name for the DB subnet group (optional, will be auto-generated if not provided)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
