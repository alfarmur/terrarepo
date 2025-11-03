module "rds_creation" {
  source   = "../day7-module"
  db_name  = var.db_name
  username = var.username
  password = var.password
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name               = var.vpc_name
  cidr               = var.vpc_cidr
  azs                = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = var.tags
}
