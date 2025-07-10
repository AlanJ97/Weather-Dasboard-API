variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "api_target_group_arn" {
  description = "ARN of the API target group"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  type        = string
}

# Container configuration
variable "api_port" {
  description = "Port for the API container"
  type        = number
  default     = 8000
}

variable "frontend_port" {
  description = "Port for the frontend container"
  type        = number
  default     = 8501
}

variable "api_cpu" {
  description = "CPU units for the API task"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memory for the API task"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "CPU units for the frontend task"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory for the frontend task"
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "Desired number of API tasks"
  type        = number
  default     = 1
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 1
}

# Container images
variable "api_image" {
  description = "Docker image for the API"
  type        = string
}

variable "api_image_tag" {
  description = "Tag for the API Docker image"
  type        = string
  default     = "latest"
}

variable "frontend_image" {
  description = "Docker image for the frontend"
  type        = string
}

variable "frontend_image_tag" {
  description = "Tag for the frontend Docker image"
  type        = string
  default     = "latest"
}

# Logging
variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 7
}

# Auto scaling
variable "enable_auto_scaling" {
  description = "Enable auto scaling for ECS services"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto scaling"
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "Target memory utilization for auto scaling"
  type        = number
  default     = 80
}
