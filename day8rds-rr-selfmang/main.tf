resource "aws_db_instance" "default" {
  allocated_storage       = 10
   identifier =             "database-1"
  db_name                 = "a"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  #manage_master_user_password = true #rds and secret manager manage this password
  username                    = "admin"
password = "irumporaI13"

  db_subnet_group_name    = aws_db_subnet_group.sub-grp.id
  parameter_group_name    = "default.mysql8.0"
  backup_retention_period  = 7   # Retain backups for 7 days
  backup_window            = "02:00-03:00" # Daily backup window (UTC)

  # Enable performance insights
#   performance_insights_enabled          = true
#   performance_insights_retention_period = 7  # Retain insights for 7 days
  maintenance_window = "sun:04:00-sun:05:00"  # Maintenance every Sunday (UTC)
  deletion_protection = false
  skip_final_snapshot = true
 #depends_on = [ aws_db_subnet_group.sub-grp.id ]
}

resource "aws_vpc" "name" {
    cidr_block = "192.68.0.0/16"
    tags = {
      Name = "My-vpc"
    }
  
}
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.name.id
    cidr_block = "192.68.1.0/24"
    availability_zone = "us-east-1a"
  
}
resource "aws_subnet" "subnet-2" {
    vpc_id = aws_vpc.name.id
    cidr_block = "192.68.2.0/24"
    availability_zone = "us-east-1b"
  
}
resource "aws_db_subnet_group" "sub-grp" {
  name       = "mypvtsubgrp"
  subnet_ids = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "read_replica" {
  identifier               = "database-1-replica"
  replicate_source_db      = aws_db_instance.default.arn   
  instance_class           = "db.t3.micro"
  db_subnet_group_name     = aws_db_subnet_group.sub-grp.name
  publicly_accessible      = false
  skip_final_snapshot      = true

  # Optional: same maintenance and backup settings as source
  maintenance_window        = "sun:05:00-sun:06:00"
  backup_retention_period   = 0  # Usually replicas have no backups

  tags = {
    Name = "hotstar-ReadReplica"
  }
}
