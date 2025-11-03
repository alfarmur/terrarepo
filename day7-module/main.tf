
resource "aws_db_instance" "rds" {
  identifier        = var.db_name
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = var.username
  password          = var.password
  skip_final_snapshot = true
}
