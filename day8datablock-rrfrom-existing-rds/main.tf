data "aws_db_instance" "master" {
  db_instance_identifier = "manual-db"
}

resource "aws_db_instance" "read_replica" {
  identifier               = "manual-db-replica"
  replicate_source_db      = data.aws_db_instance.master.db_instance_arn
  instance_class           = "db.t3.micro"
  publicly_accessible      = false
  skip_final_snapshot      = true
  backup_retention_period  = 0

  tags = {
    Name = "hotstar-ReadReplica"
  }
}
