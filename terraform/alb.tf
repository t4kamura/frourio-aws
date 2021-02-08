resource "aws_lb" "service" {
  name                       = "${var.basename}-alb"
  load_balancer_type         = "application"
  internal                   = false
  ip_address_type            = "ipv4"
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.service.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.frourio.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  lifecycle {
    ignore_changes = [default_action]
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${var.basename}-service-tg"
  vpc_id      = aws_vpc.vpc.id
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path                = "/api/tasks"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = 8080
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.service]
}

resource "aws_acm_certificate" "frourio" {
  domain_name       = "frourio.example.com"
  validation_method = "EMAIL"
}
