variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "ecr_api_repository_name" {
  description = "Name of the ECR repository for the API"
  type        = string
}

variable "ecr_frontend_repository_name" {
  description = "Name of the ECR repository for the frontend"
  type        = string
}

variable "source_bucket_name" {
  description = "S3 bucket name for pipeline artifacts"
  type        = string
}

variable "artifacts_bucket_name" {
  description = "S3 bucket name for CodePipeline artifacts"
  type        = string
}

variable "codebuild_cache_bucket_name" {
  default = "dev-weather-dashboard-codebuild-cache-2025"
}