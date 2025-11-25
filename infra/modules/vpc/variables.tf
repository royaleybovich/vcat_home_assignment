variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "public_subnets" {
  description = "Map of public subnets with keys as availability zone suffix and values as subnet config. CIDR blocks are calculated using cidrsubnet() function."
  type = map(object({
    subnet_number            = number  # Subnet number for cidrsubnet() calculation
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
  description = "Map of private subnets with keys as availability zone suffix and values as subnet config. CIDR blocks are calculated using cidrsubnet() function."
  type = map(object({
    subnet_number            = number  # Subnet number for cidrsubnet() calculation
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

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}