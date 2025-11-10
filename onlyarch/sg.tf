
# ===============================
# SECURITY GROUPS
# ===============================
resource "aws_security_group" "all_open" {
  name        = "${var.project_name}-all-open"
  description = "All traffic allowed (insecure)"
  vpc_id      = aws_vpc.this.id

  ingress {
     from_port = 0
   to_port = 0
    protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"] 
   }

  egress  { 
    from_port = 0
   to_port = 0 
  protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
    }

  tags = { Name = "${var.project_name}-sg-all-open" }
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.project_name}-rds-sg"
  vpc_id = aws_vpc.this.id

  ingress { 
    from_port = 3306
   to_port = 3306
    protocol = "tcp"
     cidr_blocks = [aws_vpc.this.cidr_block] 
     }

  egress { 
    from_port = 0
   to_port = 0
    protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
      }
}
