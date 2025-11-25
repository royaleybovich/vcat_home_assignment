variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "repositories" {
  description = "Map of ECR repositories to create"
  type = map(object({
    name                 = string
    image_tag_mutability = optional(string)
    scan_on_push         = optional(bool)
    encryption_configuration = optional(object({
      encryption_type = string
      kms_key         = optional(string)
    }))
    lifecycle_policy = optional(string)
    tags            = optional(map(string))
  }))
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
