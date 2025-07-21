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
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.env}-weather-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.env}-weather-cluster"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.env}-weather"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.env}-weather-ecs-logs"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "ecs_api" {
  name              = "/ecs/dev-weather-api"
  retention_in_days = 7

  tags = {
    Name        = "${var.env}-weather-ecs-logs"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "ecs_frontend" {
  name              = "/ecs/dev-weather-frontend"
  retention_in_days = 7

  tags = {
    Name        = "${var.env}-weather-ecs-logs"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.env}-weather-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.env}-weather-ecs-task-execution-role"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# Attach the ECS Task Execution Role Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.env}-weather-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.env}-weather-ecs-task-role"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# Custom policy for ECS tasks (if needed for specific permissions)
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.env}-weather-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/${var.env}/weather/*"
        ]
      }
    ]
  })
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.env}-weather-ecs-tasks-"
  vpc_id      = var.vpc_id
  description = "Security group for ECS tasks in the Weather Dashboard application"
  ingress {
    description     = "HTTP from ALB"
    from_port       = var.api_port
    to_port         = var.api_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    description     = "HTTP from ALB"
    from_port       = var.frontend_port
    to_port         = var.frontend_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-weather-ecs-tasks-sg"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Task Definition for API
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.env}-weather-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "weather-api"
      image = "${var.api_image}:${var.api_image_tag}"
      
      portMappings = [
        {
          containerPort = var.api_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENV"
          value = var.env
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_api.name 
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "api"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.api_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      essential = true
    }
  ])

  tags = {
    Name        = "${var.env}-weather-api-task"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# ECS Task Definition for Frontend
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.env}-weather-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "weather-frontend"
      image = "${var.frontend_image}:${var.frontend_image_tag}"
      
      portMappings = [
        {
          containerPort = var.frontend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENV"
          value = var.env
        },
        {
          name  = "API_URL"
          value = "http://${var.alb_dns_name}/api"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_frontend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.frontend_port}/_stcore/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      essential = true
    }
  ])

  tags = {
    Name        = "${var.env}-weather-frontend-task"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# ECS Service for API
resource "aws_ecs_service" "api" {
  name            = "${var.env}-weather-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count
  launch_type     = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.api_target_group_arn
    container_name   = "weather-api"
    container_port   = var.api_port
  }

  depends_on = [var.alb_api_listener_rule_arn]

  # Ignore changes to task_definition and desired_count when using CODE_DEPLOY
  # CodeDeploy will manage these during blue/green deployments
  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      load_balancer,
    ]
  }

  tags = {
    Name        = "${var.env}-weather-api-service"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# ECS Service for Frontend
resource "aws_ecs_service" "frontend" {
  name            = "${var.env}-weather-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "weather-frontend"
    container_port   = var.frontend_port
  }

  depends_on = [var.alb_api_listener_rule_arn]

  # Ignore changes to task_definition and desired_count when using CODE_DEPLOY
  # CodeDeploy will manage these during blue/green deployments
  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      load_balancer,
    ]
  }

  tags = {
    Name        = "${var.env}-weather-frontend-service"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}
