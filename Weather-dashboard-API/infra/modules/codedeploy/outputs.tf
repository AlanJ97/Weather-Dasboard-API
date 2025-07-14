output "application_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.weather_dashboard.name
}

output "application_id" {
  description = "ID of the CodeDeploy application"
  value       = aws_codedeploy_app.weather_dashboard.id
}

output "api_deployment_group_name" {
  description = "Name of the API deployment group"
  value       = aws_codedeploy_deployment_group.api.deployment_group_name
}

output "frontend_deployment_group_name" {
  description = "Name of the frontend deployment group"
  value       = aws_codedeploy_deployment_group.frontend.deployment_group_name
}

output "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy service role"
  value       = aws_iam_role.codedeploy_role.arn
}
