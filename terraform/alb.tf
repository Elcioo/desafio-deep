# Application Load Balancer
resource "aws_alb" "this" {
  name                       = "alb-ecs-${terraform.workspace}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.this.id]
  subnets                    = [aws_subnet.subnet_public_one.id, aws_subnet.subnet_public_two.id]
  enable_deletion_protection = false
  enable_http2               = true
  tags                       = local.default_tags
  depends_on                 = [aws_security_group.this]
}

# ALB Listener
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }

  tags = local.default_tags
}

# ALB Target Group with target type ip
resource "aws_alb_target_group" "frontend" {
  name        = "frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.default_tags

  depends_on = [aws_vpc.this]
}

# ALB Target Group with target type ip
resource "aws_alb_target_group" "backend" {
  name        = "backend-tg"
  port        = 5500
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.default_tags

  depends_on = [aws_vpc.this]
}



resource "aws_alb_listener_rule" "backend" {
  listener_arn = aws_alb_listener.http.arn
  priority     = 1001

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.backend.arn
  }

  condition {


    path_pattern {
      values = ["/api"]
    }
  }
  tags = local.default_tags

  depends_on = [aws_alb_target_group.backend]
}

resource "aws_alb_listener_rule" "frontend" {
  listener_arn = aws_alb_listener.http.arn
  priority     = 1000

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.frontend.arn
  }

  condition {


    path_pattern {
      values = ["*"]
    }
  }
  tags = local.default_tags
}
# Security Group for ALB
resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.default_tags
}


