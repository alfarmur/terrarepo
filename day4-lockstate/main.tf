# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create a new SSH key pair
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = "bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

# Save private key locally (for connecting later)
resource "local_file" "private_key_pem" {
  content  = tls_private_key.bastion_key.private_key_pem
  filename = "${path.module}/bastion-key.pem"
}

# Create security group for SSH
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # Allow from anywhere (restrict in prod)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# Create the Bastion EC2 instance
resource "aws_instance" "bastion" {
  ami           = "ami-0c02fb55956c7d316"  # Amazon Linux 2 (us-east-1)
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name      = aws_key_pair.bastion_keypair.key_name

  tags = {
    Name = "bastion-host"
  }
}
