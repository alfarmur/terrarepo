resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_1_id
  associate_public_ip_address = true

  tags = {
    Name = "web-instance"
  }
}
