variable "env" {
  description = "Environment name"
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# ECR Variables
variable "ecr_image_tag_mutability" {
  description = "Image tag mutability setting for ECR repositories"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "ecr_prod_image_count" {
  description = "Number of production images to keep"
  type        = number
  default     = 10
}

variable "ecr_dev_image_count" {
  description = "Number of development/staging images to keep"
  type        = number
  default     = 5
}

variable "ecr_untagged_image_days" {
  description = "Days after which untagged images expire"
  type        = number
  default     = 1
}

# ALB Variables
variable "api_port" {
  description = "Port for the API"
  type        = number
  default     = 8000
}

variable "frontend_port" {
  description = "Port for the frontend"
  type        = number
  default     = 8501
}

variable "alb_enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "alb_enable_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = null
}

# ECS Variables
variable "ecs_api_cpu" {
  description = "CPU units for the API task"
  type        = number
  default     = 256
}

variable "ecs_api_memory" {
  description = "Memory for the API task"
  type        = number
  default     = 512
}

variable "ecs_frontend_cpu" {
  description = "CPU units for the frontend task"
  type        = number
  default     = 256
}

variable "ecs_frontend_memory" {
  description = "Memory for the frontend task"
  type        = number
  default     = 512
}

variable "ecs_api_desired_count" {
  description = "Desired number of API tasks"
  type        = number
  default     = 1
}

variable "ecs_frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 1
}

variable "ecs_api_image_tag" {
  description = "Tag for the API Docker image"
  type        = string
  default     = "latest"
}

variable "ecs_frontend_image_tag" {
  description = "Tag for the frontend Docker image"
  type        = string
  default     = "latest"
}

variable "ecs_log_retention_days" {
  description = "Number of days to retain ECS logs"
  type        = number
  default     = 7
}

# Bastion Host Variables
variable "bastion_public_key" {
  description = "Public key for the bastion host key pair"
  type        = string
  # This should be provided as an environment variable or through terraform.tfvars
}

variable "bastion_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the bastion host via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # For dev environment - restrict this in production!
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "bastion_enable_termination_protection" {
  description = "Enable termination protection for the bastion host"
  type        = bool
  default     = false
}