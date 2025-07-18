output "before_install_function_name" {
  description = "Name of the BeforeInstall Lambda function"
  value       = aws_lambda_function.before_install.function_name
}

output "after_install_function_name" {
  description = "Name of the AfterInstall Lambda function"
  value       = aws_lambda_function.after_install.function_name
}

output "before_allow_traffic_function_name" {
  description = "Name of the BeforeAllowTraffic Lambda function"
  value       = aws_lambda_function.before_allow_traffic.function_name
}

output "after_allow_traffic_function_name" {
  description = "Name of the AfterAllowTraffic Lambda function"
  value       = aws_lambda_function.after_allow_traffic.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.codedeploy_hooks_lambda_role.arn
}
