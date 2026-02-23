variable "dk_aws_region" {
  description = "AWS region for dk production infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "dk_vpc_cidr_block" {
  description = "CIDR block for dk production VPC"
  type        = string
}
variable "dk_public_subnet_az_a_cidr" {
  type = string
}

variable "dk_public_subnet_az_b_cidr" {
  type = string
}

variable "dk_private_subnet_az_a_cidr" {
  type = string
}

variable "dk_private_subnet_az_b_cidr" {
  type = string
}
variable "dk_db_username" {
  type = string
}

variable "dk_db_password" {
  type      = string
  sensitive = true
}
