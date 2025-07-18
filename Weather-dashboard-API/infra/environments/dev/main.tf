terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.90" # waiter bug fixed, available in registry
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  env                  = var.env
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  env                  = var.env
  aws_region           = var.aws_region
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  prod_image_count     = var.ecr_prod_image_count
  dev_image_count      = var.ecr_dev_image_count
  untagged_image_days  = var.ecr_untagged_image_days
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  env                        = var.env
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  api_port                   = var.api_port
  frontend_port              = var.frontend_port
  enable_deletion_protection = var.alb_enable_deletion_protection
  ssl_certificate_arn        = var.ssl_certificate_arn
  enable_access_logs         = var.alb_enable_access_logs
  access_logs_bucket         = var.alb_access_logs_bucket
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  env                       = var.env
  aws_region                = var.aws_region
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  alb_security_group_id     = module.alb.alb_security_group_id
  alb_dns_name              = module.alb.alb_dns_name
  api_target_group_arn      = module.alb.api_blue_tg_arn
  frontend_target_group_arn = module.alb.front_blue_tg_arn
  alb_frontend_listener_arn = module.alb.frontend_listener_arn
  alb_api_listener_rule_arn = module.alb.api_listener_rule_arn

  # Container configuration
  api_port               = var.api_port
  frontend_port          = var.frontend_port
  api_cpu                = var.ecs_api_cpu
  api_memory             = var.ecs_api_memory
  frontend_cpu           = var.ecs_frontend_cpu
  frontend_memory        = var.ecs_frontend_memory
  api_desired_count      = var.ecs_api_desired_count
  frontend_desired_count = var.ecs_frontend_desired_count

  # Container images
  api_image          = module.ecr.weather_api_repository_url
  api_image_tag      = var.ecs_api_image_tag
  frontend_image     = module.ecr.weather_frontend_repository_url
  frontend_image_tag = var.ecs_frontend_image_tag

  # Logging
  log_retention_days = var.ecs_log_retention_days
}


# Bastion Host Module
module "bastion" {
  source = "../../modules/bastion"

  env                 = var.env
  aws_region          = var.aws_region
  vpc_id              = module.vpc.vpc_id
  public_subnet_id    = module.vpc.public_subnet_ids[0]
  public_key          = var.bastion_public_key
  allowed_cidr_blocks = var.bastion_allowed_cidr_blocks
  ecs_cluster_arn     = module.ecs.cluster_arn
  log_group_arns      = module.ecs.log_group_arns
}


# CodeBuild Module
module "codebuild" {
  source = "../../modules/codebuild"

  environment                  = var.env
  aws_region                   = var.aws_region
  aws_account_id               = var.aws_account_id
  ecr_api_repository_name      = module.ecr.weather_api_repository_name
  ecr_frontend_repository_name = module.ecr.weather_frontend_repository_name
  source_bucket_name = "dev-weather-dashboard-codebuild-cache-2025"
  artifacts_bucket_name = "dev-weather-dashboard-pipeline-artifacts-2025"

  depends_on = [module.ecr]
}
/*
# Lambda Module (for CodeDeploy hooks)
module "lambda" {
  source = "../../modules/lambda"

  environment = var.env
  tags = {
    Environment = var.env
    Project     = "weather-dashboard"
  }
}
*/
# CodeDeploy Module
module "codedeploy" {
  source = "../../modules/codedeploy"

  environment                    = var.env
  ecs_cluster_name               = module.ecs.cluster_name
  ecs_api_service_name           = module.ecs.api_service_name
  ecs_frontend_service_name      = module.ecs.frontend_service_name
  alb_api_target_group_name      = module.alb.api_target_group_name
  alb_frontend_target_group_name = module.alb.frontend_target_group_name
  alb_api_listener_arn           = module.alb.https_listener_arn != null ? module.alb.https_listener_arn : module.alb.http_listener_arn
  alb_api_tg_blue_name           = module.alb.api_blue_tg_name
  alb_api_tg_green_name          = module.alb.api_green_tg_name

  alb_front_listener_arn         = module.alb.frontend_listener_arn != null ? module.alb.frontend_listener_arn : module.alb.http_listener_arn
  alb_front_tg_blue_name         = module.alb.front_blue_tg_name
  alb_front_tg_green_name        = module.alb.front_green_tg_name
  depends_on = [module.ecs, module.alb]
}


# CodePipeline Module
module "codepipeline" {
  source = "../../modules/codepipeline"

  environment                          = var.env
  github_owner                         = var.github_owner
  github_repo                          = var.github_repo
  github_branch                        = var.github_branch
  codebuild_project_name               = module.codebuild.codebuild_project_name
  codebuild_project_arn                = module.codebuild.codebuild_project_arn
  codedeploy_application_name          = module.codedeploy.application_name
  codedeploy_deployment_group_api      = module.codedeploy.api_deployment_group_name
  codedeploy_deployment_group_frontend = module.codedeploy.frontend_deployment_group_name
  artifacts_bucket_name                = "dev-weather-dashboard-pipeline-artifacts-2025"
  enable_webhook                       = var.enable_pipeline_webhook

  depends_on = [module.codebuild, module.codedeploy]
}