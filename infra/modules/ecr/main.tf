resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = each.value.name
  image_tag_mutability = each.value.image_tag_mutability != null ? each.value.image_tag_mutability : "MUTABLE"

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push != null ? each.value.scan_on_push : true
  }

  dynamic "encryption_configuration" {
    for_each = each.value.encryption_configuration != null ? [each.value.encryption_configuration] : []
    content {
      encryption_type = encryption_configuration.value.encryption_type
      kms_key         = encryption_configuration.value.kms_key
    }
  }

  tags = merge(
    {
      Environment = var.environment
      Name        = each.value.name
    },
    each.value.tags != null ? each.value.tags : {},
    var.tags
  )
}

# Lifecycle policies
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = { for k, v in var.repositories : k => v if v.lifecycle_policy != null }

  repository = aws_ecr_repository.this[each.key].name
  policy     = each.value.lifecycle_policy
}

# =======================================================
# OUTPUTS
# =======================================================

output "repository_urls" {
  description = "Map of repository URLs by key"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository ARNs by key"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_names" {
  description = "Map of repository names by key"
  value       = { for k, v in aws_ecr_repository.this : k => v.name }
}

output "repository_url" {
  description = "Repository URL (first repository if multiple)"
  value       = try(values(aws_ecr_repository.this)[0].repository_url, null)
}
