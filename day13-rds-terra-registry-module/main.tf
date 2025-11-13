provider "aws" {
  region = "us-east-1"
}

# ---- VPC and Subnets ----
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---- RDS Module ----
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.3" # check latest version on the registry

  identifier = "my-rds-db"

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "userdb"
  username = "admin"
  password = "irumporaI!"
  port     = 3306
   major_engine_version  = "8.0"
  family = "mysql8.0" 
  # Networking
  vpc_security_group_ids = []
  subnet_ids             = data.aws_subnets.default.ids

  # Optionally create a subnet group automatically
  create_db_subnet_group = true

  # Backup and maintenance
  backup_retention_period = 7
  maintenance_window       = "Sun:00:00-Sun:03:00"
  backup_window            = "03:00-06:00"

  # Deletion protection
  deletion_protection = false
  skip_final_snapshot  = true

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}
