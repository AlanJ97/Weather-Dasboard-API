output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.weather_dashboard.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.weather_dashboard.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = aws_iam_role.codebuild_role.arn
}

output "cache_bucket_name" {
  description = "Name of the S3 bucket used for CodeBuild cache"
  value       = aws_s3_bucket.codebuild_cache.bucket
}
