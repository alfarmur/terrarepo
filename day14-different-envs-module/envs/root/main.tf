provider "aws" {
  region = var.region
  #profile = "root"
}

# ------------------------------
# VPC MODULE (with 2 subnets)
# ------------------------------
module "vpc" {
  source = "../../modules/vpc"

  env = var.env

  cidr_block = var.vpc_cidr

  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr

  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr

  az1 = var.az1
  az2 = var.az2
}

# ------------------------------
# EC2 MODULE
# use 1 public subnet
# ------------------------------
module "ec2" {
  source        = "../../modules/ec2"

  ami_id        = var.ami_id
  instance_type = var.instance_type
  env           = var.env

  subnet_id     = module.vpc.public_subnet_ids[0]    # ✅ use public subnet 1
}

# ------------------------------
# RDS MODULE
# needs 2 private subnets
# ------------------------------
module "rds" {
  source = "../../modules/rds"

  env               = var.env
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_user           = var.db_user
  db_password       = var.db_password
  #db_sg_id          = aws_security_group.rds_sg.id

  subnet_ids = module.vpc.private_subnet_ids         # ✅ both private subnets
}
