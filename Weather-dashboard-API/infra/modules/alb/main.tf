# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.env}-weather-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for the Weather Dashboard Application Load Balancer"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # The ALB needs to send health checks and traffic to the targets.
  # We restrict this to the ports used by the API and Frontend services.
  egress {
    description = "Allow outbound traffic to API target"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic to Frontend target"
    from_port   = var.frontend_port
    to_port     = var.frontend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-weather-alb-sg"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.env}-weather-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "${var.env}-weather-alb"
      enabled = var.enable_access_logs
    }
  }

  tags = {
    Name        = "${var.env}-weather-alb"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# Target Group for API
resource "aws_lb_target_group" "api" {
  name        = "${var.env}-weather-api-tg"
  port        = var.api_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.env}-weather-api-tg"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# Target Group for Frontend
resource "aws_lb_target_group" "frontend" {
  name        = "${var.env}-weather-frontend-tg"
  port        = var.frontend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.env}-weather-frontend-tg"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# HTTP Listener - Redirect to HTTPS
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

  tags = {
    Name        = "${var.env}-weather-http-listener"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count             = var.ssl_certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

}

# HTTP Listener for environments without SSL
resource "aws_lb_listener" "http_default" {
  count             = var.ssl_certificate_arn == null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name        = "${var.env}-weather-http-default-listener"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# Listener Rule for API paths
resource "aws_lb_listener_rule" "api" {
  listener_arn = var.ssl_certificate_arn != null ? aws_lb_listener.https[0].arn : aws_lb_listener.http_default[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/docs", "/redoc", "/openapi.json", "/health"]
    }
  }

  tags = {
    Name        = "${var.env}-weather-api-rule"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}
