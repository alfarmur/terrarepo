# ---------- VPC ----------
resource "aws_vpc" "name" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# ---------- Subnets ----------
resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.name.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.name.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2"
  }
}

# ---------- DB Subnet Group ----------
resource "aws_db_subnet_group" "sub_grp" {
  name       = "mypvtsub"
  subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  tags = {
    Name = "My DB subnet group"
  }

  # Explicit dependency on both subnets
  depends_on = [
    aws_subnet.subnet_1,
    aws_subnet.subnet_2
  ]
}

# ---------- RDS Instance ----------
resource "aws_db_instance" "default" {
  identifier                  = "users"
  db_name                     = "mydb"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  allocated_storage           = 10
  manage_master_user_password = true  # RDS + Secrets Manager manage this
  username                    = "admin"
  db_subnet_group_name        = aws_db_subnet_group.sub_grp.name
  parameter_group_name        = "default.mysql8.0"

  backup_retention_period     = 7
  backup_window               = "02:00-03:00"
  maintenance_window          = "sun:04:00-sun:05:00"
  deletion_protection         = true
  skip_final_snapshot         = true

  # Explicit dependency to ensure subnet group exists
  depends_on = [
    aws_db_subnet_group.sub_grp
  ]

  tags = {
    Name = "MyRDSInstance"
  }
}
