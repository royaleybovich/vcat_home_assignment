resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = "${var.name_prefix}-${each.value.name}"
  description = each.value.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [
      for rule in each.value.ingress_rules : rule
      if length(coalesce(lookup(rule, "security_groups", []), [])) == 0
    ]

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      self        = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = [
      for rule in each.value.egress_rules : rule
      if length(coalesce(lookup(rule, "security_groups", []), [])) == 0
    ]

    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      self        = egress.value.self
    }
  }

  tags = merge(
    {
      Name = "${var.name_prefix}-${each.value.name}"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "ingress_with_sg" {
  for_each = {
    for idx, rule in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_idx, rule in sg.ingress_rules : {
          key    = "${sg_key}-ingress-${rule_idx}"
          sg_key = sg_key
          rule   = rule
        }
        if length(coalesce(lookup(rule, "security_groups", []), [])) > 0
      ]
    ]) : rule.key => rule
  }

  type        = "ingress"
  description = each.value.rule.description
  from_port   = each.value.rule.from_port
  to_port     = each.value.rule.to_port
  protocol    = each.value.rule.protocol

  source_security_group_id = aws_security_group.this[
    each.value.rule.security_groups[0]
  ].id

  security_group_id = aws_security_group.this[
    each.value.sg_key
  ].id
}

resource "aws_security_group_rule" "egress_with_sg" {
  for_each = {
    for idx, rule in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_idx, rule in sg.egress_rules : {
          key    = "${sg_key}-egress-${rule_idx}"
          sg_key = sg_key
          rule   = rule
        }
        if length(coalesce(lookup(rule, "security_groups", []), [])) > 0
      ]
    ]) : rule.key => rule
  }

  type        = "egress"
  description = each.value.rule.description
  from_port   = each.value.rule.from_port
  to_port     = each.value.rule.to_port
  protocol    = each.value.rule.protocol

  source_security_group_id = aws_security_group.this[
    each.value.rule.security_groups[0]
  ].id

  security_group_id = aws_security_group.this[
    each.value.sg_key
  ].id
}

# =======================================================
# OUTPUTS
# =======================================================

output "security_group_ids" {
  description = "Map of security group IDs by key"
  value       = { for k, v in aws_security_group.this : k => v.id }
}

output "security_group_arns" {
  description = "Map of security group ARNs by key"
  value       = { for k, v in aws_security_group.this : k => v.arn }
}

output "alb_sg_id" {
  description = "ALB security group ID (if 'alb' key exists)"
  value       = try(aws_security_group.this["alb"].id, null)
}

output "ecs_sg_id" {
  description = "ECS security group ID (if 'ecs' key exists)"
  value       = try(aws_security_group.this["ecs"].id, null)
}

output "db_sg_id" {
  description = "Database security group ID (if 'db' key exists)"
  value       = try(aws_security_group.this["db"].id, null)
}