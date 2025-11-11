###############################################
# BASTION HOST
###############################################

resource "aws_instance" "bastion" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name      = aws_key_pair.example.key_name
  subnet_id              = aws_subnet.pub1.id
  vpc_security_group_ids = [aws_security_group.bastion_host.id]

  tags = {
    Name = "bastion-server"
  }
}

# 🔹 Create a key pair
resource "aws_key_pair" "example" {
  key_name   = "task"
  public_key = file("~/.ssh/id_ed25519.pub")
}

