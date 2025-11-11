###############################################
# FRONTEND
###############################################

data "aws_ami" "frontend" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["frontend-ami*"]
  }
}

resource "aws_launch_template" "frontend" {
  name_prefix            = "frontend-terraform-"
  image_id               = data.aws_ami.frontend.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.frontend_server_sg.id]
  key_name      = aws_key_pair.example.key_name
  user_data              = base64encode(file("userdata-frontend.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "frontend-server"
    }
  }

  depends_on = [data.aws_ami.frontend]
}

###############################################
# BACKEND
###############################################

data "aws_ami" "backend" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["backend-ami*"]
  }
}

resource "aws_launch_template" "backend" {
  name_prefix            = "backend-terraform-"
  image_id               = data.aws_ami.backend.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.backend_server_sg.id]
  key_name      = aws_key_pair.example.key_name
  user_data              = filebase64("userdata-backend.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "backend-server"
    }
  }

  depends_on = [data.aws_ami.backend]
}



