############################################
# Provider
############################################
provider "aws" {
    # change if needed
}

############################################
# VPC
############################################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# Security Group (Allow ALL Traffic)
############################################
resource "aws_security_group" "allow_all" {
  name        = "allow_all_sg"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################
# EC2 Instance (t2.medium, NO key)
############################################
resource "aws_instance" "public_server" {
  ami                    = "ami-0fa3fe0fa7920f68e"  # Amazon Linux 2 (Mumbai) — update if needed
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  associate_public_ip_address = true

  key_name = "" # no key

  tags = {
    Name = "Public-Server"
  }
}

############################################
# RDS MySQL
############################################
resource "aws_db_subnet_group" "db_subnet" {
  name       = "db-subnet"
  subnet_ids = [aws_subnet.public.id]    # Using public subnet (NOT recommended for prod)
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "mydb"
  username               = "admin"
  password               = "irumporaI"
  skip_final_snapshot    = true

  vpc_security_group_ids = [aws_security_group.allow_all.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  publicly_accessible    = true

  tags = {
    Name = "MySQL-DB"
  }
}