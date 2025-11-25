resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    {
      Name = "${var.name_prefix}-vpc"
    },
    var.tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.name_prefix}-igw"
    },
    var.tags
  )
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, var.public_subnet_newbits, each.value.subnet_number)
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  availability_zone       = "${var.aws_region}${each.value.availability_zone_suffix}"

  tags = merge(
    {
      Name = "${var.name_prefix}-public-${each.key}"
      Type = "public"
    },
    var.tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    {
      Name = "${var.name_prefix}-public-rt"
    },
    var.tags
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, var.private_subnet_newbits, each.value.subnet_number)
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  availability_zone       = "${var.aws_region}${each.value.availability_zone_suffix}"

  tags = merge(
    {
      Name = "${var.name_prefix}-private-${each.key}"
      Type = "private"
    },
    var.tags
  )
}

# =======================================================
# OUTPUTS
# =======================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = [for subnet in aws_subnet.public : subnet.cidr_block]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = [for subnet in aws_subnet.private : subnet.cidr_block]
}

# Backward compatibility - alias for db_subnet_ids
output "db_subnet_ids" {
  description = "List of private subnet IDs (alias for private_subnet_ids)"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}