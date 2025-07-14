# CodeDeploy Application
resource "aws_codedeploy_app" "weather_dashboard" {
  compute_platform = "ECS"
  name             = "${var.environment}-weather-dashboard-app"

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# CodeDeploy Deployment Group for API
resource "aws_codedeploy_deployment_group" "api" {
  app_name              = aws_codedeploy_app.weather_dashboard.name
  deployment_group_name = "${var.environment}-weather-api-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_api_service_name
  }

  deployment_config_name = "CodeDeployDefault.ECSAllAtOne"

  load_balancer_info {
    target_group_info {
      name = var.alb_api_target_group_name
    }
  }

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    Component   = "api"
    ManagedBy   = "terraform"
  }
}

# CodeDeploy Deployment Group for Frontend
resource "aws_codedeploy_deployment_group" "frontend" {
  app_name              = aws_codedeploy_app.weather_dashboard.name
  deployment_group_name = "${var.environment}-weather-frontend-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_frontend_service_name
  }

  deployment_config_name = "CodeDeployDefault.ECSAllAtOne"

  load_balancer_info {
    target_group_info {
      name = var.alb_frontend_target_group_name
    }
  }

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    Component   = "frontend"
    ManagedBy   = "terraform"
  }
}

# IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.environment}-weather-dashboard-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# Attach AWS managed policy for ECS deployments
resource "aws_iam_role_policy_attachment" "codedeploy_ecs_role" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy_role.name
}

# Additional IAM Policy for CodeDeploy
resource "aws_iam_role_policy" "codedeploy_policy" {
  role = aws_iam_role.codedeploy_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateTaskSet",
          "ecs:DeleteTaskSet",
          "ecs:DescribeServices",
          "ecs:UpdateServicePrimaryTaskSet"
        ]
        Resource = [
          "arn:aws:ecs:*:*:cluster/${var.ecs_cluster_name}",
          "arn:aws:ecs:*:*:service/${var.ecs_cluster_name}/*",
          "arn:aws:ecs:*:*:task-set/${var.ecs_cluster_name}/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/${var.alb_api_target_group_name}/*",
          "arn:aws:elasticloadbalancing:*:*:targetgroup/${var.alb_frontend_target_group_name}/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "arn:aws:cloudwatch:*:*:alarm:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "arn:aws:sns:*:*:codedeploy-*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::*-pipeline-artifacts/*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::*:role/*-ecs-task-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for CodeDeploy
resource "aws_cloudwatch_log_group" "codedeploy_logs" {
  name              = "/aws/codedeploy/${var.environment}-weather-dashboard"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}
