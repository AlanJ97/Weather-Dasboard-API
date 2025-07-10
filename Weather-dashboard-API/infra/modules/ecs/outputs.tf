output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "api_task_definition_arn" {
  description = "ARN of the API task definition"
  value       = aws_ecs_task_definition.api.arn
}

output "frontend_task_definition_arn" {
  description = "ARN of the frontend task definition"
  value       = aws_ecs_task_definition.frontend.arn
}

output "api_service_name" {
  description = "Name of the API service"
  value       = aws_ecs_service.api.name
}

output "frontend_service_name" {
  description = "Name of the frontend service"
  value       = aws_ecs_service.frontend.name
}

output "api_service_arn" {
  description = "ARN of the API service"
  value       = aws_ecs_service.api.id
}

output "frontend_service_arn" {
  description = "ARN of the frontend service"
  value       = aws_ecs_service.frontend.id
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "service_names" {
  description = "Map of service names"
  value = {
    api      = aws_ecs_service.api.name
    frontend = aws_ecs_service.frontend.name
  }
}

output "task_definition_arns" {
  description = "Map of task definition ARNs"
  value = {
    api      = aws_ecs_task_definition.api.arn
    frontend = aws_ecs_task_definition.frontend.arn
  }
}

output "log_group_arns" {
  description = "ARNs of the CloudWatch log groups for the services"
  value = [
    "/ecs/${var.env}-weather-api",
    "/ecs/${var.env}-weather-frontend"
  ]
}
