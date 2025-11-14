# ---------------------------
# General / Provider
# ---------------------------
region = "us-east-1"
env    = "user1"

# ---------------------------
# VPC
# ---------------------------
vpc_cidr = "10.0.0.0/16"

public_subnet_1_cidr  = "10.0.1.0/24"
public_subnet_2_cidr  = "10.0.2.0/24"

private_subnet_1_cidr = "10.0.3.0/24"
private_subnet_2_cidr = "10.0.4.0/24"

az1 = "us-east-1a"
az2 = "us-east-1b"

# ---------------------------
# EC2
# ---------------------------
ami_id        = "ami-0157af9aea2eef346"
instance_type = "t2.micro"

# ---------------------------
# RDS
# ---------------------------
db_instance_class = "db.t3.micro"
db_name           = "mydb"
db_user           = "admin"
db_password       = "irumporaI!"
