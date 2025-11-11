###############################################
# VARIABLES
###############################################

variable "rds_password" {
  description = "RDS password"
  type        = string
  default     = "irumporaI"
}

variable "rds_username" {
  description = "RDS username"
  type        = string
  default     = "admin"
}

variable "ami" {
  description = "AMI ID"
  type        = string
  default     = "ami-0157af9aea2eef346"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name_asg" {
  description = "Key pair name"
  type        = string
  default     = "mykey-asg"
}

variable "backup_retention" {
  description = "RDS backup retention days"
  type        = number
  default     = 7
}

