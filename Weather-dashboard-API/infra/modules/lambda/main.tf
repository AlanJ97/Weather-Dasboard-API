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
  filename         = "${path.module}/before_install.zip"
  function_name    = "${var.environment}-codedeploy-before-install"
  role             = aws_iam_role.codedeploy_hooks_lambda_role.arn
  handler          = "before_install.handler"
  runtime          = "python3.9"
  timeout          = 60

  source_code_hash = filebase64sha256("${path.module}/before_install.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Lambda function for AfterInstall hook
resource "aws_lambda_function" "after_install" {
  filename         = "${path.module}/after_install.zip"
  function_name    = "${var.environment}-codedeploy-after-install"
  role             = aws_iam_role.codedeploy_hooks_lambda_role.arn
  handler          = "after_install.handler"
  runtime          = "python3.9"
  timeout          = 60

  source_code_hash = filebase64sha256("${path.module}/after_install.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Lambda function for BeforeAllowTraffic hook
resource "aws_lambda_function" "before_allow_traffic" {
  filename         = "${path.module}/before_allow_traffic.zip"
  function_name    = "${var.environment}-codedeploy-before-allow-traffic"
  role             = aws_iam_role.codedeploy_hooks_lambda_role.arn
  handler          = "before_allow_traffic.handler"
  runtime          = "python3.9"
  timeout          = 60

  source_code_hash = filebase64sha256("${path.module}/before_allow_traffic.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Lambda function for AfterAllowTraffic hook
resource "aws_lambda_function" "after_allow_traffic" {
  filename         = "${path.module}/after_allow_traffic.zip"
  function_name    = "${var.environment}-codedeploy-after-allow-traffic"
  role             = aws_iam_role.codedeploy_hooks_lambda_role.arn
  handler          = "after_allow_traffic.handler"
  runtime          = "python3.9"
  timeout          = 60

  source_code_hash = filebase64sha256("${path.module}/after_allow_traffic.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}
