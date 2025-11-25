# DB subnet group
resource "aws_db_subnet_group" "db" {
  name       = var.subnet_group_name != "" ? var.subnet_group_name : "${var.name_prefix}-db-subnets"
  subnet_ids = var.db_subnet_ids

  tags = merge(
    {
      Name = var.subnet_group_name != "" ? var.subnet_group_name : "${var.name_prefix}-db-subnets"
    },
    var.tags
  )
}

resource "aws_db_instance" "this" {
  for_each = var.databases

  identifier              = each.value.identifier
  engine                  = each.value.engine
  engine_version          = each.value.engine_version
  instance_class          = each.value.instance_class
  allocated_storage       = each.value.allocated_storage
  max_allocated_storage   = each.value.max_allocated_storage
  storage_type            = each.value.storage_type != null ? each.value.storage_type : "gp3"
  storage_encrypted        = each.value.storage_encrypted != null ? each.value.storage_encrypted : true
  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [var.db_sg_id]
  publicly_accessible     = each.value.publicly_accessible != null ? each.value.publicly_accessible : false
  skip_final_snapshot     = each.value.skip_final_snapshot != null ? each.value.skip_final_snapshot : false
  final_snapshot_identifier = each.value.final_snapshot_identifier
  backup_retention_period = each.value.backup_retention_period
  backup_window           = each.value.backup_window
  maintenance_window      = each.value.maintenance_window
  multi_az                = each.value.multi_az != null ? each.value.multi_az : false
  deletion_protection     = each.value.deletion_protection != null ? each.value.deletion_protection : false
  enabled_cloudwatch_logs_exports = each.value.enabled_cloudwatch_logs_exports
  parameter_group_name    = each.value.parameter_group_name

  username = each.value.username
  password = each.value.password

  tags = merge(
    {
      Name = each.value.identifier
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

# =======================================================
# OUTPUTS
# =======================================================

output "db_endpoints" {
  description = "Map of database endpoints by key"
  value       = { for k, v in aws_db_instance.this : k => v.endpoint }
}

output "db_ports" {
  description = "Map of database ports by key"
  value       = { for k, v in aws_db_instance.this : k => v.port }
}

output "db_addresses" {
  description = "Map of database addresses by key"
  value       = { for k, v in aws_db_instance.this : k => v.address }
}

output "db_ids" {
  description = "Map of database IDs by key"
  value       = { for k, v in aws_db_instance.this : k => v.id }
}

output "db_endpoint" {
  description = "Database endpoint (first database if multiple)"
  value       = try(values(aws_db_instance.this)[0].endpoint, null)
}

output "db_port" {
  description = "Database port (first database if multiple)"
  value       = try(values(aws_db_instance.this)[0].port, null)
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.db.name
}