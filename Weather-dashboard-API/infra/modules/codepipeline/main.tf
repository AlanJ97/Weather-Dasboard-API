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

# CodePipeline
resource "aws_codepipeline" "weather_dashboard" {
  name     = "${var.environment}-weather-dashboard-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.artifacts_bucket_name
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
        TaskDefinitionTemplatePath    = "taskdef-api.json"   
        AppSpecTemplateArtifact       = "build_output"
        AppSpecTemplatePath           = "appspec-api.yml"       
        Image1ArtifactName            = "build_output"
        Image1ContainerName           = "IMAGE1_NAME"        
        ImageDefinitionsArtifactName  = "build_output"              # ADD THIS
        ImageDefinitionsFileName      = "imagedefinitions.json"     # ADD THIS   
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
        TaskDefinitionTemplatePath    = "taskdef-frontend.json"  
        AppSpecTemplateArtifact       = "build_output"
        AppSpecTemplatePath           = "appspec-frontend.yml"   
        Image1ArtifactName            = "build_output"
        Image1ContainerName           = "IMAGE1_NAME"            
        ImageDefinitionsArtifactName  = "build_output"      
        ImageDefinitionsFileName      = "imagedefinitions.json"     
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
          "arn:aws:s3:::${var.artifacts_bucket_name}",
          "arn:aws:s3:::${var.artifacts_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
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
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision"

        ]
        Resource = [
        "arn:aws:codedeploy:us-east-2:622233144821:application/${var.codedeploy_application_name}",
        "arn:aws:codedeploy:us-east-2:622233144821:application:${var.codedeploy_application_name}",
        "arn:aws:codedeploy:us-east-2:622233144821:deploymentgroup:${var.codedeploy_application_name}/*",
        "arn:aws:codedeploy:us-east-2:622233144821:deploymentconfig:*"
        ]
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
        Resource = [
          "arn:aws:ecs:*:*:cluster/*",
          "arn:aws:ecs:*:*:service/*/*",
          "arn:aws:ecs:*:*:task-definition/*:*",
          "arn:aws:ecs:*:*:task/*/*/*"
        ]
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
        name = [var.artifacts_bucket_name]
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
