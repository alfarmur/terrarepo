#create VPc
resource "aws_vpc" "vpcname" {
    cidr_block = "192.68.0.0/16"
    tags = { Name="custom_VPC"}
}

resource "aws_subnet" "publicname" {
  vpc_id = aws_vpc.vpcname.id
  cidr_block = "192.68.1.0/24"
  availability_zone = "us-east-1a"
  tags = {Name="public-subnet"}
}

resource "aws_subnet" "privatename" {
  vpc_id = aws_vpc.vpcname.id
  cidr_block = "192.68.2.0/24"
  availability_zone = "us-east-1a"
  tags = {Name="private-subnet"}
}

resource "aws_internet_gateway" "igname" {
  vpc_id = aws_vpc.vpcname.id
  tags = {name="ig"}
}

resource "aws_route_table" "igrtname" {
  vpc_id = aws_vpc.vpcname.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igname.id
  }
  tags = {Name="igrt"}
}

resource "aws_route_table_association" "igrtassoname" {
route_table_id = aws_route_table.igrtname.id
subnet_id = aws_subnet.publicname.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "my-nat-eip"
  }
}

resource "aws_nat_gateway" "natname" {
allocation_id = aws_eip.nat.id
subnet_id = aws_subnet.privatename.id
tags = {Name="my-nat"}
}

resource "aws_route_table" "natrt" {
  vpc_id = aws_vpc.vpcname.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natname.id
  }
  tags = {Name="natrt"}
}

resource "aws_route_table_association" "natrtassociate" {
route_table_id = aws_route_table.natrt.id
subnet_id = aws_subnet.privatename.id
}

resource "aws_security_group" "sg" {
  name="allow"
  vpc_id = aws_vpc.vpcname.id
  tags = {Name="sg-ssh"}

  ingress {
    description = "allow all"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]  
      }
}

resource "aws_instance" "bastionec2" { 
    instance_type = var.type
     ami = var.ami_id
     subnet_id = aws_subnet.publicname.id
     vpc_security_group_ids = [aws_security_group.sg.id]

    associate_public_ip_address = true

     tags = {
        Name="bastion-ec2"
        }
}

resource "aws_instance" "ec2" { 
    instance_type = var.type
     ami = var.ami_id
     subnet_id = aws_subnet.privatename.id
     vpc_security_group_ids = [aws_security_group.sg.id]
     tags = {
        Name="terra-ec2"
        }

}
