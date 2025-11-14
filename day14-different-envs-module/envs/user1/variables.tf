# -------------------------
# General / Provider
# -------------------------
variable "region" {
  description = "AWS region"
  type        = string
}

variable "env" {
  description = "Environment name (dev/prod)"
  type        = string
}

# -------------------------
# VPC Variables
# -------------------------
variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
}

variable "public_subnet_1_cidr" {
  description = "CIDR for Public Subnet 1"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "CIDR for Public Subnet 2"
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "CIDR for Private Subnet 1"
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR for Private Subnet 2"
  type        = string
}

variable "az1" {
  description = "Availability zone 1"
  type        = string
}

variable "az2" {
  description = "Availability zone 2"
  type        = string
}

# -------------------------
# EC2 Variables
# -------------------------
variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# -------------------------
# RDS Variables
# -------------------------
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
