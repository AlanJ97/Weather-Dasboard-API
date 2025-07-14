# CodeBuild Project for Weather Dashboard API
resource "aws_codebuild_project" "weather_dashboard" {
  name          = "${var.environment}-weather-dashboard-build"
  description   = "Build project for Weather Dashboard API and Frontend"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true  # Required for Docker builds

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.aws_account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME_API"
      value = var.ecr_api_repository_name
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME_FRONTEND"
      value = var.ecr_frontend_repository_name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "Weather-dashboard-API/buildspec.yml"
  }

  cache {
    type  = "S3"
    location = "${aws_s3_bucket.codebuild_cache.bucket}/build-cache"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild_logs.name
      stream_name = "build-log"
    }
  }

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# S3 Bucket for CodeBuild cache
resource "aws_s3_bucket" "codebuild_cache" {
  bucket = "${var.environment}-weather-dashboard-codebuild-cache"

  tags = {
    Environment = var.environment
    Purpose     = "CodeBuild cache"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "codebuild_cache_versioning" {
  bucket = aws_s3_bucket.codebuild_cache.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codebuild_cache_encryption" {
  bucket = aws_s3_bucket.codebuild_cache.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/aws/codebuild/${var.environment}-weather-dashboard-build"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.environment}-weather-dashboard-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
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

# IAM Policy for CodeBuild
resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_cloudwatch_log_group.codebuild_logs.arn,
          "${aws_cloudwatch_log_group.codebuild_logs.arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.codebuild_cache.arn}",
          "${aws_s3_bucket.codebuild_cache.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ]
        Resource = "*"
      }
    ]
  })
}
