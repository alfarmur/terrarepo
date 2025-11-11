###############################################
# RDS
###############################################

resource "aws_db_subnet_group" "sub_grp" {
  name       = "main"
  subnet_ids = [aws_subnet.prvt7.id, aws_subnet.prvt8.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage      = 20
  identifier             = "book-rds"
  db_subnet_group_name   = aws_db_subnet_group.sub_grp.id
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  multi_az               = true
  db_name                = "db"
  username               = var.rds_username
  password               = var.rds_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.book_rds_sg.id]
  publicly_accessible    = false
  backup_retention_period = var.backup_retention

  tags = {
    DB_identifier = "book-rds"
  }
}
