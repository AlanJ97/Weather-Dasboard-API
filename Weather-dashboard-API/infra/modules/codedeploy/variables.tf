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
variable "alb_api_listener_arn"         { type = string }
variable "alb_api_tg_blue_name"         { type = string }
variable "alb_api_tg_green_name"        { type = string }
variable "alb_front_listener_arn"       { type = string }
variable "alb_front_tg_blue_name"       { type = string }
variable "alb_front_tg_green_name"      { type = string }

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}