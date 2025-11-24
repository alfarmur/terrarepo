// Terraform configuration: 3-tier architecture (VPC, public/private subnets, NAT, IGW, Bastion, EC2s, ALBs, Target Groups, RDS)
// Files combined into one for convenience. Split into separate files if you prefer.
# ----------------------
# DATA SOURCE: FRONTEND AMI
# ----------------------
data "aws_ami" "frontend" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["frontend-ami*"]  # <-- partial name match
  }
}

# ----------------------
# DATA SOURCE: BACKEND AMI
# ----------------------
data "aws_ami" "backend" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["backend-ami*"]
  }
}

// ----------------------
// providers.tf
// ----------------------
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

// ----------------------
// variables.tf
// ----------------------
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "three-tier"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "frontend_ami_id" {
  description = "AMI ID for frontend ASG"
  type        = string
}

variable "backend_ami_id" {
  description = "AMI ID for backend ASG"
  type        = string
}


variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24", "10.0.14.0/24"]
}

variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "instance_ami" {
  description = "AMI for EC2 (Amazon Linux 2). Change to an appropriate AMI ID for your region."
  type        = string
  default     = "ami-0157af9aea2eef346" // Amazon Linux 2 (us-east-1) — change if region differs
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_username" {
  type    = string
  default = "user"
}

variable "db_password" {
  type    = string
  default = "irumporaI"
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "test"
}

// ----------------------
// vpc, subnets, internet gateway, nat gateway
// ----------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

// Create public subnets
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[each.key]
  tags = {
    Name = "${var.project_name}-public-${each.key}"
  }
}

// Private subnets (application)
resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[each.key % length(data.aws_availability_zones.available.names)]
  tags = {
    Name = "${var.project_name}-private-${each.key}"
  }
}

// DB subnets (private)
resource "aws_subnet" "db" {
  for_each = { for idx, cidr in var.db_subnet_cidrs : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[each.key % length(data.aws_availability_zones.available.names)]
  tags = {
    Name = "${var.project_name}-db-${each.key}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-igw" }
}

// Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}


// Create a NAT Gateway in first public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = { Name = "${var.project_name}-nat" }
}

// Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

// Private route table (routes through NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

// DB subnet group (for RDS)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.db : s.id]
  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

// ----------------------
// Security Groups (user requested all traffic allowed anywhere)
// ----------------------
resource "aws_security_group" "all_open" {
  name        = "${var.project_name}-all-open"
  description = "All traffic allowed (insecure)"
  vpc_id      = aws_vpc.this.id

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

  tags = { Name = "${var.project_name}-sg-all-open" }
}

// RDS-specific SG (we'll also allow all for simplicity but restrict to VPC CIDR as an example)
resource "aws_security_group" "rds_sg" {
  name   = "${var.project_name}-rds-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ----------------------
// Key pair for Bastion (generated)
// ----------------------
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "${var.project_name}-bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

// ----------------------
// Data source for AZs
// ----------------------
data "aws_availability_zones" "available" {
  state = "available"
}

// ----------------------
// EC2: Bastion (in public subnet)
// ----------------------
resource "aws_instance" "bastion" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  key_name               = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.all_open.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

// ----------------------
// EC2: Frontend & Backend in private subnets
// We'll spin up one frontend and one backend instance; place them in separate private subnets
// ----------------------
resource "aws_instance" "frontend" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  key_name               = aws_key_pair.bastion_key.key_name // use key so you can ssh via bastion
  vpc_security_group_ids = [aws_security_group.all_open.id]
  associate_public_ip_address = false

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

resource "aws_instance" "backend" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[1].id
  key_name               = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.all_open.id]
  associate_public_ip_address = false

  tags = {
    Name = "${var.project_name}-backend"
  }
}

// ----------------------
// ALB for backend (internet-facing) -> target group port 3000, health check /books
// ----------------------
resource "aws_lb" "backend_alb" {
  name               = "${var.project_name}-backend-alb"
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.all_open.id]
  enable_deletion_protection = false
  internal           = false
  tags = { Name = "${var.project_name}-backend-alb" }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project_name}-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.this.id

  health_check {
    path                = "/books"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = { Name = "${var.project_name}-backend-tg" }
}

resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

// Register backend instance with backend target group
resource "aws_lb_target_group_attachment" "backend_attach" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend.id
  port             = 3000
}

// ----------------------
// ALB for frontend -> target group port 80
// ----------------------
resource "aws_lb" "frontend_alb" {
  name               = "${var.project_name}-frontend-alb"
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.all_open.id]
  internal           = false
  tags = { Name = "${var.project_name}-frontend-alb" }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.project_name}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.this.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = { Name = "${var.project_name}-frontend-tg" }
}

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "frontend_attach" {
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.frontend.id
  port             = 80
}
# ======================================================================
# LAUNCH TEMPLATES + AUTO SCALING GROUPS
# ======================================================================

# ----------------------
# FRONTEND USER DATA
# ----------------------
# FRONTEND USER DATA
data "template_file" "frontend_userdata" {
  template = file("${path.module}/userdata-frontend.sh")

  vars = {
    BACKEND_API = "http://backend.threetier.internal"
     }
}

# ----------------------
# BACKEND USER DATA
# ----------------------
data "template_file" "backend_userdata" {
  template = file("${path.module}/userdata-backend.sh")
}

# ----------------------
# FRONTEND LAUNCH TEMPLATE
# ----------------------
   resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "${var.project_name}-frontend-lt-"
  image_id      = data.aws_ami.frontend.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.all_open.id]

  user_data = base64encode(data.template_file.frontend_userdata.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-frontend-instance"
      Tier = "frontend"
    }
  }
}

resource "aws_launch_template" "backend_lt" {
  name_prefix   = "${var.project_name}-backend-lt-"
  image_id      = data.aws_ami.backend.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.all_open.id]

  user_data = base64encode(data.template_file.backend_userdata.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-backend-instance"
      Tier = "backend"
    }
  }
}


# ----------------------
# FRONTEND AUTO SCALING GROUP
# ----------------------
resource "aws_autoscaling_group" "frontend_asg" {
  name                      = "${var.project_name}-frontend-asg"
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  vpc_zone_identifier       = [for s in aws_subnet.private : s.id] # private subnets
  target_group_arns         = [aws_lb_target_group.frontend_tg.arn]
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-frontend-asg"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# ----------------------
# BACKEND AUTO SCALING GROUP
# ----------------------
resource "aws_autoscaling_group" "backend_asg" {
  name                      = "${var.project_name}-backend-asg"
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  vpc_zone_identifier       = [for s in aws_subnet.private : s.id] # backend private subnets
  target_group_arns         = [aws_lb_target_group.backend_tg.arn]
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend-asg"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}


# ----------------------
# ROUTE53 PRIVATE HOSTED ZONE
# ----------------------
resource "aws_route53_zone" "private_zone" {
  name = "threetier.internal"   # private domain name
  vpc {
    vpc_id = aws_vpc.this.id
  }
  comment = "Private hosted zone for internal DB resolution"
}


// ----------------------
// RDS (MySQL) instance in private subnets
// ----------------------
resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-db"
  allocated_storage    = var.db_allocated_storage
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  db_name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
  multi_az             = false
  tags = { Name = "${var.project_name}-rds" }
}

# ----------------------
# ROUTE53 RECORD FOR RDS ENDPOINT
# ----------------------
resource "aws_route53_record" "db_record" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "database.${aws_route53_zone.private_zone.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.mysql.address]
}



// ----------------------
// Outputs
// ----------------------
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "db_subnet_ids" {
  value = [for s in aws_subnet.db : s.id]
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_key_pem" {
  description = "PEM private key for bastion (sensitive)"
  value       = tls_private_key.bastion_key.private_key_pem
  sensitive   = true
}

output "backend_alb_dns" {
  value = aws_lb.backend_alb.dns_name
}

output "frontend_alb_dns" {
  value = aws_lb.frontend_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
  sensitive = true
}

output "rds_address" {
  value = aws_db_instance.mysql.address
}
output "rds_private_dns" {
  value = "database.${aws_route53_zone.private_zone.name}"
}


// ----------------------
// NOTES / Guidance
// ----------------------
// 1) This example intentionally keeps security wide open (security group allowing all). That is insecure for production — restrict to required ports and sources.
// 2) The AMI ID provided is for Amazon Linux 2 in us-east-1. Change var.instance_ami for other regions.
// 3) You will likely want to add user_data for EC2 instances to bootstrap your Node.js project, install dependencies, and start the app. Use cloud-init / user_data to write environment variables (e.g., DB endpoint) and start services.
// 4) To SSH into private instances (frontend/backend), first SSH to the bastion (public IP) and then from there use the private key or agent forwarding.
// 5) Consider creating IAM roles for EC2 and RDS, backup/monitoring, and enabling encryption at rest for RDS (skip here for brevity).
// 6) This config creates single AZ RDS and NAT — for HA, create NAT gateways in multiple AZs and enable multi-az RDS.
// 7) Terraform state contains sensitive values (DB password, private key). Protect state (remote backend, e.g., S3 with encryption and locking).

// End of combined terraform file
