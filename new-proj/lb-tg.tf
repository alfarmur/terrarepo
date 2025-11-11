###############################################
# LOAD BALANCERS & TARGET GROUPS
###############################################

# Backend ALB
resource "aws_lb_target_group" "back_end" {
  name     = "backend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.three_tier.id
}

resource "aws_lb" "back_end" {
  name               = "backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_backend_sg.id]
  subnets            = [aws_subnet.pub1.id, aws_subnet.pub2.id]

  tags = {
    Name = "ALB-backend"
  }
}

resource "aws_lb_listener" "back_end" {
  load_balancer_arn = aws_lb.back_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.back_end.arn
  }
}

# Frontend ALB
resource "aws_lb_target_group" "front_end" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.three_tier.id
}

resource "aws_lb" "front_end" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_frontend_sg.id]
  subnets            = [aws_subnet.pub1.id, aws_subnet.pub2.id]

  tags = {
    Name = "ALB-Frontend"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}
