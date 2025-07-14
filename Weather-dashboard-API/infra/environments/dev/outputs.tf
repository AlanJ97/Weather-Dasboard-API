# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_names" {
  description = "ECR repository names"
  value       = module.ecr.repository_names
}

# ALB Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = module.alb.alb_zone_id
}

output "api_target_group_arn" {
  description = "API target group ARN"
  value       = module.alb.api_target_group_arn
}

output "frontend_target_group_arn" {
  description = "Frontend target group ARN"
  value       = module.alb.frontend_target_group_arn
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

output "ecs_service_names" {
  description = "ECS service names"
  value       = module.ecs.service_names
}

output "ecs_task_definition_arns" {
  description = "ECS task definition ARNs"
  value       = module.ecs.task_definition_arns
}

# Bastion Host Outputs
output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = module.bastion.bastion_public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = module.bastion.ssh_command
}

output "bastion_connection_info" {
  description = "Bastion host connection information"
  value       = module.bastion.bastion_connection_info
}

# Application URLs
output "application_urls" {
  description = "Application URLs"
  value = {
    alb_dns              = module.alb.alb_dns_name
    api_url              = "http://${module.alb.alb_dns_name}/api"
    frontend_url         = "http://${module.alb.alb_dns_name}"
    api_docs_url         = "http://${module.alb.alb_dns_name}/docs"
    api_health_url       = "http://${module.alb.alb_dns_name}/health"
  }
}

# CI/CD Pipeline Outputs
output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = module.codebuild.codebuild_project_name
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = module.codepipeline.pipeline_name
}

output "codedeploy_application_name" {
  description = "CodeDeploy application name"
  value       = module.codedeploy.application_name
}

output "pipeline_artifacts_bucket" {
  description = "S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.pipeline_artifacts.bucket
}

# Enhanced Deployment Summary
output "deployment_summary" {
  description = "Complete deployment summary including CI/CD"
  value = {
    environment          = var.env
    region              = var.aws_region
    vpc_id              = module.vpc.vpc_id
    alb_dns             = module.alb.alb_dns_name
    ecs_cluster         = module.ecs.cluster_name
    bastion_ip          = module.bastion.bastion_public_ip
    ecr_repositories    = module.ecr.repository_names
    codebuild_project   = module.codebuild.codebuild_project_name
    codepipeline_name   = module.codepipeline.pipeline_name
    codedeploy_app      = module.codedeploy.application_name
    artifacts_bucket    = aws_s3_bucket.pipeline_artifacts.bucket
  }
}
