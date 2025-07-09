variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "repository_prefix" {
  description = "Prefix for ECR repository names"
  type        = string
  default     = "weather-dashboard"
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting for ECR repositories"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for ECR repositories"
  type        = string
  default     = "AES256"
}

variable "lifecycle_policy_enabled" {
  description = "Enable lifecycle policy for ECR repositories"
  type        = bool
  default     = true
}

variable "prod_image_count" {
  description = "Number of production images to keep"
  type        = number
  default     = 10
}

variable "dev_image_count" {
  description = "Number of development/staging images to keep"
  type        = number
  default     = 5
}

variable "untagged_image_days" {
  description = "Days after which untagged images expire"
  type        = number
  default     = 1
}
