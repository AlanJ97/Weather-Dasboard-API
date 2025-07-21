variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "api_port" {
  description = "Port for the API target group"
  type        = number
  default     = 8000
}

variable "frontend_port" {
  description = "Port for the frontend target group"
  type        = number
  default     = 8501
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = null
}

variable "enable_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "health_check_path_api" {
  description = "Health check path for API"
  type        = string
  default     = "/health"
}

variable "health_check_path_frontend" {
  description = "Health check path for frontend"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive health checks before marking target healthy"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health checks before marking target unhealthy"
  type        = number
  default     = 2
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
