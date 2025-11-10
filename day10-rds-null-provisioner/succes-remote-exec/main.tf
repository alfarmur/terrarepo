resource "aws_db_instance" "mydb" {
  identifier             = "mydb-instance"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "irumporaI!"
  db_name                = "mydatabase"
  allocated_storage      = 20
  skip_final_snapshot    = true
  publicly_accessible    = true
}

resource "aws_key_pair" "keypair" {
  key_name   = "my-key-pair"
  public_key = file("C:/Users/yamar/.ssh/id_ed25519.pub")
}

resource "aws_instance" "app_server" {
  ami                         = "ami-0157af9aea2eef346"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.keypair.key_name
  associate_public_ip_address = true
  tags = {
    Name = "provisionserver"
  }
}

resource "null_resource" "init" {
  depends_on = [
    aws_db_instance.mydb,
    aws_instance.app_server
  ]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/yamar/.ssh/id_ed25519")
    host        = aws_instance.app_server.public_ip
  }

  # Step 1: Copy SQL file
  provisioner "file" {
    source      = "${path.module}/init.sql"
    destination = "/tmp/init.sql"
  }

  # Step 2: Run commands on remote EC2
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y mysql || sudo yum install -y mariadb",
      # Use a temporary credentials file to handle special characters in password
      "echo '[client]' > /tmp/my.cnf",
      "echo 'user=${aws_db_instance.mydb.username}' >> /tmp/my.cnf",
      "echo 'password=${aws_db_instance.mydb.password}' >> /tmp/my.cnf",
      "echo 'host=${aws_db_instance.mydb.address}' >> /tmp/my.cnf",
      "mysql --defaults-extra-file=/tmp/my.cnf ${aws_db_instance.mydb.db_name} < /tmp/init.sql",
      "rm -f /tmp/my.cnf"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}
