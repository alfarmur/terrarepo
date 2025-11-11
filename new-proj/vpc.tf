###############################################
# VPC
###############################################

resource "aws_vpc" "three_tier" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "3-tier-vpc"
  }
}

###############################################
# PUBLIC SUBNETS (for ALB)
###############################################

resource "aws_subnet" "pub1" {
  vpc_id                  = aws_vpc.three_tier.id
  cidr_block              = "172.20.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "pub-1a" }
}

resource "aws_subnet" "pub2" {
  vpc_id                  = aws_vpc.three_tier.id
  cidr_block              = "172.20.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "pub-2b" }
}

###############################################
# PRIVATE SUBNETS
###############################################

# Frontend servers
resource "aws_subnet" "prvt3" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "172.20.3.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "prvt-3a" }
}

resource "aws_subnet" "prvt4" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "172.20.4.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "prvt-4b" }
}

# Backend servers
resource "aws_subnet" "prvt5" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "172.20.5.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "prvt-5a" }
}

resource "aws_subnet" "prvt6" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "172.20.6.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "prvt-6b" }
}

# RDS database
resource "aws_subnet" "prvt7" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "172.20.7.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "prvt-7a" }
}

resource "aws_subnet" "prvt8" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "172.20.8.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "prvt-8b" }
}

###############################################
# INTERNET GATEWAY & PUBLIC ROUTE TABLE
###############################################

resource "aws_internet_gateway" "three_tier_ig" {
  vpc_id = aws_vpc.three_tier.id

  tags = { Name = "3-tier-ig" }
}

resource "aws_route_table" "three_tier_pub_rt" {
  vpc_id = aws_vpc.three_tier.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three_tier_ig.id
  }

  tags = { Name = "3-tier-pub-rt" }
}

# Associate public subnets
resource "aws_route_table_association" "public_1a" {
  route_table_id = aws_route_table.three_tier_pub_rt.id
  subnet_id      = aws_subnet.pub1.id
}

resource "aws_route_table_association" "public_2b" {
  route_table_id = aws_route_table.three_tier_pub_rt.id
  subnet_id      = aws_subnet.pub2.id
}

###############################################
# NAT GATEWAY + PRIVATE ROUTE TABLE
###############################################

resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.three_tier_ig]
}

# NAT Gateway
resource "aws_nat_gateway" "cust_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.pub1.id

  tags = { Name = "3-tier-nat" }
}

# Private route table
resource "aws_route_table" "three_tier_prvt_rt" {
  vpc_id = aws_vpc.three_tier.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cust_nat.id
  }

  tags = { Name = "3-tier-prvt-rt" }
}

# Associate 
resource "aws_route_table_association" "prv_3a" {
  route_table_id = aws_route_table.three_tier_prvt_rt.id
  subnet_id      = aws_subnet.prvt3.id
}

resource "aws_route_table_association" "prv_4b" {
  route_table_id = aws_route_table.three_tier_prvt_rt.id
  subnet_id      = aws_subnet.prvt4.id
}

resource "aws_route_table_association" "prv_5a" {
  route_table_id = aws_route_table.three_tier_prvt_rt.id
  subnet_id      = aws_subnet.prvt5.id
}

resource "aws_route_table_association" "prv_6b" {
  route_table_id = aws_route_table.three_tier_prvt_rt.id
  subnet_id      = aws_subnet.prvt6.id
}

resource "aws_route_table_association" "prv_7a" {
  route_table_id = aws_route_table.three_tier_prvt_rt.id
  subnet_id      = aws_subnet.prvt7.id
}

resource "aws_route_table_association" "prv_8b" {
  route_table_id = aws_route_table.three_tier_prvt_rt.id
  subnet_id      = aws_subnet.prvt8.id
}
