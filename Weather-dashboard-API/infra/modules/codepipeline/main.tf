# AWS CodeStar Connection for GitHub
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.environment}-github-connection"
  provider_type = "GitHub"

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# S3 Bucket for Pipeline Artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.environment}-weather-dashboard-pipeline-artifacts"

  tags = {
    Environment = var.environment
    Purpose     = "CodePipeline artifacts"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts_versioning" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts_encryption" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts_pab" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CodePipeline
resource "aws_codepipeline" "weather_dashboard" {
  name     = "${var.environment}-weather-dashboard-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy-API"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName                = var.codedeploy_application_name
        DeploymentGroupName           = var.codedeploy_deployment_group_api
        TaskDefinitionTemplateArtifact = "build_output"
        AppSpecTemplateArtifact       = "build_output"
        Image1ArtifactName            = "build_output"
        Image1ContainerName           = "weather-api"
      }
    }

    action {
      name            = "Deploy-Frontend"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName                = var.codedeploy_application_name
        DeploymentGroupName           = var.codedeploy_deployment_group_frontend
        TaskDefinitionTemplateArtifact = "build_output"
        AppSpecTemplateArtifact       = "build_output"
        Image1ArtifactName            = "build_output"
        Image1ContainerName           = "weather-frontend"
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.environment}-weather-dashboard-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
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

# IAM Policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = var.codebuild_project_arn
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# CloudWatch Event Rule for automatic pipeline triggers
resource "aws_cloudwatch_event_rule" "github_webhook" {
  count       = var.enable_webhook ? 1 : 0
  name        = "${var.environment}-weather-dashboard-github-webhook"
  description = "Trigger pipeline on GitHub push"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.pipeline_artifacts.bucket]
      }
    }
  })

  tags = {
    Environment = var.environment
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  count     = var.enable_webhook ? 1 : 0
  rule      = aws_cloudwatch_event_rule.github_webhook[0].name
  target_id = "TriggerPipeline"
  arn       = aws_codepipeline.weather_dashboard.arn
  role_arn  = aws_iam_role.events_role[0].arn
}

# IAM Role for CloudWatch Events
resource "aws_iam_role" "events_role" {
  count = var.enable_webhook ? 1 : 0
  name  = "${var.environment}-weather-dashboard-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
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

resource "aws_iam_role_policy" "events_policy" {
  count = var.enable_webhook ? 1 : 0
  role  = aws_iam_role.events_role[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Resource = aws_codepipeline.weather_dashboard.arn
      }
    ]
  })
}
