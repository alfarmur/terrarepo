provider "aws" {
  region = "us-east-1"
}

# Get your local public IP
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-allow-local"
  description = "Allow MySQL access from local system"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   lifecycle {
    # Prevent Terraform from trying to delete SG before RDS is ready
    prevent_destroy = false
    create_before_destroy = false
  }
}

# RDS instance
resource "aws_db_instance" "mysql_rds" {
  identifier              = "my-mysql-db"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "irumporaI!"
  db_name                 = "dev"
  allocated_storage       = 20
  skip_final_snapshot     = true
  publicly_accessible     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]

  # Optional but recommended
  deletion_protection     = false
}

# Run local SQL script after RDS is ready
resource "null_resource" "local_sql_exec" {
  depends_on = [aws_db_instance.mysql_rds]

  provisioner "local-exec" {
    command = "powershell -Command \"& 'C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin\\mysql.exe' -h ${aws_db_instance.mysql_rds.address} -u admin -pirumporaI! dev < 'D:\\terraform\\terrarepo\\rds\\init.sql'\""
  #command = "mysql -h ${aws_db_instance.mydb.address} -u admin -pirumporaI! < ./init.sql"
  }

  triggers = {
    always_run = timestamp()
  }
}





