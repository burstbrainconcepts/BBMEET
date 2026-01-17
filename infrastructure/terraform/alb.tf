# Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group for Media Server
resource "aws_lb_target_group" "media" {
  name     = "${var.project_name}-media-tg-v2" # v2 to avoid conflicts if any
  port     = 5998
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/health-check"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Data Source to find Media Server
data "aws_instance" "media" {
  filter {
    name   = "tag:Name"
    values = ["bb-sdk-media-server"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Attachment
resource "aws_lb_target_group_attachment" "media" {
  target_group_arn = aws_lb_target_group.media.arn
  target_id        = data.aws_instance.media.id
  port             = 5998
}

# Listener HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.media.arn
  }
}

# Listener HTTP Redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
