variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "AlanJ97"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "Weather-Dasboard-API"
}

variable "github_branch" {
  description = "GitHub branch to trigger pipeline"
  type        = string
  default     = "main"
}

variable "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  type        = string
}

variable "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  type        = string
}

variable "codedeploy_application_name" {
  description = "Name of the CodeDeploy application"
  type        = string
}

variable "codedeploy_deployment_group_api" {
  description = "Name of the CodeDeploy deployment group for API"
  type        = string
}

variable "codedeploy_deployment_group_frontend" {
  description = "Name of the CodeDeploy deployment group for frontend"
  type        = string
}

variable "enable_webhook" {
  description = "Enable automatic pipeline triggers via CloudWatch Events"
  type        = bool
  default     = false
}

variable "artifacts_bucket_name" {
  description = "Name of the S3 bucket for pipeline artifacts (externally managed)"
  type        = string
}
