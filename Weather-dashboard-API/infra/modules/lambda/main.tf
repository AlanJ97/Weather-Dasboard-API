# Lambda functions for CodeDeploy ECS hooks
resource "aws_iam_role" "codedeploy_hooks_lambda_role" {
  name = "${var.environment}-codedeploy-hooks-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.codedeploy_hooks_lambda_role.name
}

resource "aws_iam_role_policy" "codedeploy_hooks_policy" {
  name = "${var.environment}-codedeploy-hooks-policy"
  role = aws_iam_role.codedeploy_hooks_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy:PutLifecycleEventHookExecutionStatus",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function for BeforeInstall hook
resource "aws_lambda_function" "before_install" {
  filename         = data.archive_file.before_install_zip.output_path
  function_name    = "${var.environment}-codedeploy-before-install"
  role            = aws_iam_role.codedeploy_hooks_lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.before_install_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Lambda function for AfterInstall hook
resource "aws_lambda_function" "after_install" {
  filename         = data.archive_file.after_install_zip.output_path
  function_name    = "${var.environment}-codedeploy-after-install"
  role            = aws_iam_role.codedeploy_hooks_lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.after_install_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Lambda function for BeforeAllowTraffic hook
resource "aws_lambda_function" "before_allow_traffic" {
  filename         = data.archive_file.before_allow_traffic_zip.output_path
  function_name    = "${var.environment}-codedeploy-before-allow-traffic"
  role            = aws_iam_role.codedeploy_hooks_lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.before_allow_traffic_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Lambda function for AfterAllowTraffic hook
resource "aws_lambda_function" "after_allow_traffic" {
  filename         = data.archive_file.after_allow_traffic_zip.output_path
  function_name    = "${var.environment}-codedeploy-after-allow-traffic"
  role            = aws_iam_role.codedeploy_hooks_lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.after_allow_traffic_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Create ZIP files for Lambda functions
data "archive_file" "before_install_zip" {
  type        = "zip"
  output_path = "${path.module}/before_install.zip"
  source {
    content = templatefile("${path.module}/lambda_code/before_install.py", {
      environment = var.environment
    })
    filename = "index.py"
  }
}

data "archive_file" "after_install_zip" {
  type        = "zip"
  output_path = "${path.module}/after_install.zip"
  source {
    content = templatefile("${path.module}/lambda_code/after_install.py", {
      environment = var.environment
    })
    filename = "index.py"
  }
}

data "archive_file" "before_allow_traffic_zip" {
  type        = "zip"
  output_path = "${path.module}/before_allow_traffic.zip"
  source {
    content = templatefile("${path.module}/lambda_code/before_allow_traffic.py", {
      environment = var.environment
    })
    filename = "index.py"
  }
}

data "archive_file" "after_allow_traffic_zip" {
  type        = "zip"
  output_path = "${path.module}/after_allow_traffic.zip"
  source {
    content = templatefile("${path.module}/lambda_code/after_allow_traffic.py", {
      environment = var.environment
    })
    filename = "index.py"
  }
}
