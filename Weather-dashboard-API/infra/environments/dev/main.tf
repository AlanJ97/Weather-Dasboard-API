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

  env                    = var.env
  aws_region             = var.aws_region
  image_tag_mutability   = var.ecr_image_tag_mutability
  scan_on_push           = var.ecr_scan_on_push
  prod_image_count       = var.ecr_prod_image_count
  dev_image_count        = var.ecr_dev_image_count
  untagged_image_days    = var.ecr_untagged_image_days
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
  api_target_group_arn      = module.alb.api_target_group_arn
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  
  # Container configuration
  api_port             = var.api_port
  frontend_port        = var.frontend_port
  api_cpu              = var.ecs_api_cpu
  api_memory           = var.ecs_api_memory
  frontend_cpu         = var.ecs_frontend_cpu
  frontend_memory      = var.ecs_frontend_memory
  api_desired_count    = var.ecs_api_desired_count
  frontend_desired_count = var.ecs_frontend_desired_count
  
  # Container images
  api_image           = module.ecr.weather_api_repository_url
  api_image_tag       = var.ecs_api_image_tag
  frontend_image      = module.ecr.weather_frontend_repository_url
  frontend_image_tag  = var.ecs_frontend_image_tag
  
  # Logging
  log_retention_days = var.ecs_log_retention_days
}

# Bastion Host Module
module "bastion" {
  source = "../../modules/bastion"

  env                   = var.env
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  public_key            = var.bastion_public_key
  allowed_cidr_blocks   = var.bastion_allowed_cidr_blocks
}
