variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_api_service_name" {
  description = "Name of the ECS service for the API"
  type        = string
}

variable "ecs_frontend_service_name" {
  description = "Name of the ECS service for the frontend"
  type        = string
}

variable "alb_api_target_group_name" {
  description = "Name of the ALB target group for the API"
  type        = string
}

variable "alb_frontend_target_group_name" {
  description = "Name of the ALB target group for the frontend"
  type        = string
}
