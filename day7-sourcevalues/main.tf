module "rds_creation" {
  source = "../day7-module"
db_name  = "mydb"
username = "admin"
password = "irumporaI@13"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0" # Use the latest stable version

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "Development"
    Project     = "MyApplication"
  }
}