output "weather_api_repository_url" {
  description = "URL of the weather API ECR repository"
  value       = aws_ecr_repository.weather_api.repository_url
}

output "weather_api_repository_name" {
  description = "Name of the weather API ECR repository"
  value       = aws_ecr_repository.weather_api.name
}

output "weather_api_repository_arn" {
  description = "ARN of the weather API ECR repository"
  value       = aws_ecr_repository.weather_api.arn
}

output "weather_frontend_repository_url" {
  description = "URL of the weather frontend ECR repository"
  value       = aws_ecr_repository.weather_frontend.repository_url
}

output "weather_frontend_repository_name" {
  description = "Name of the weather frontend ECR repository"
  value       = aws_ecr_repository.weather_frontend.name
}

output "weather_frontend_repository_arn" {
  description = "ARN of the weather frontend ECR repository"
  value       = aws_ecr_repository.weather_frontend.arn
}

output "repository_urls" {
  description = "Map of all ECR repository URLs"
  value = {
    weather_api      = aws_ecr_repository.weather_api.repository_url
    weather_frontend = aws_ecr_repository.weather_frontend.repository_url
  }
}

output "repository_names" {
  description = "Map of all ECR repository names"
  value = {
    weather_api      = aws_ecr_repository.weather_api.name
    weather_frontend = aws_ecr_repository.weather_frontend.name
  }
}
