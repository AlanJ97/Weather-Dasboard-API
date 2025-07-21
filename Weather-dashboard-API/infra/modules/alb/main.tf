terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.90"     # waiter bug fixed, available in registry
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}


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

  tags = merge(var.common_tags, {
    Name      = "${var.env}-weather-alb-sg"
    Type      = "security-group"
    Component = "networking"
  })

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

  tags = merge(var.common_tags, {
    Name      = "${var.env}-weather-alb"
    Type      = "load-balancer"
    Component = "networking"
  })
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

  tags = merge(var.common_tags, {
    Name      = "${var.env}-weather-api-tg"
    Type      = "target-group"
    Component = "api"
  })
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

  tags = merge(var.common_tags, {
    Name      = "${var.env}-weather-frontend-tg"
    Type      = "target-group"
    Component = "frontend"
  })
}

# Blue/Green Target Groups for API and Frontend
resource "aws_lb_target_group" "api_blue" {
  name        = "${var.env}-weather-api-tg-blue"
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

  tags = merge(var.common_tags, {
    Name      = "${var.env}-weather-api-tg-blue"
    Type      = "target-group"
    Component = "api"
    Color     = "blue"
  })
}

resource "aws_lb_target_group" "api_green" {
  name        = "${var.env}-weather-api-tg-green"
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

  tags = merge(var.common_tags, {
    Name      = "${var.env}-weather-api-tg-green"
    Type      = "target-group"
    Component = "api"
    Color     = "green"
  })
}

resource "aws_lb_target_group" "frontend_blue" {
  name        = "${var.env}-weather-frontend-tg-blue"
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

  tags = merge(var.common_tags, {
    Name      = "${var.env}-weather-frontend-tg-blue"
    Type      = "target-group"
    Component = "frontend"
    Color     = "blue"
  })
}

resource "aws_lb_target_group" "frontend_green" {
  name        = "${var.env}-weather-frontend-tg-green"
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

  tags = merge(var.common_tags, {
    Name      = "${var.env}-weather-frontend-tg-green"
    Type      = "target-group"
    Component = "frontend"
    Color     = "green"
  })
}

# HTTP Listener - Redirect to HTTPS (only when SSL certificate is available)
resource "aws_lb_listener" "http" {
  count             = var.ssl_certificate_arn != null ? 1 : 0
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

  tags = merge(var.common_tags, {
    Name = "${var.env}-weather-http-listener"
    Type = "alb-listener"
  })
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
    target_group_arn = aws_lb_target_group.frontend_green.arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.env}-weather-https-listener"
    Type = "alb-listener"
  })
}

# HTTP Listener for environments without SSL
resource "aws_lb_listener" "http_default" {
  count             = var.ssl_certificate_arn == null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_green.arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.env}-weather-http-default-listener"
    Type = "alb-listener"
  })
}

# Listener Rule for API paths
resource "aws_lb_listener_rule" "api" {
  listener_arn = var.ssl_certificate_arn != null ? aws_lb_listener.https[0].arn : aws_lb_listener.http_default[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_green.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/docs", "/redoc", "/openapi.json", "/health"]
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.env}-weather-api-rule"
    Type = "alb-listener-rule"
  })
}
