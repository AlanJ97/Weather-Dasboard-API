output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "api_target_group_arn" {
  description = "ARN of the API target group"
  value       = aws_lb_target_group.api.arn
}

output "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend.arn
}

output "api_target_group_name" {
  description = "Name of the API target group"
  value       = aws_lb_target_group.api.name
}

output "frontend_target_group_name" {
  description = "Name of the frontend target group"
  value       = aws_lb_target_group.frontend.name
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = var.ssl_certificate_arn == null ? aws_lb_listener.http_default[0].arn : aws_lb_listener.http[0].arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.ssl_certificate_arn != null ? aws_lb_listener.https[0].arn : null
}

output "target_group_arns" {
  description = "Map of target group ARNs"
  value = {
    api      = aws_lb_target_group.api.arn
    frontend = aws_lb_target_group.frontend.arn
  }
}

output "frontend_listener_arn" {
  description = "The ARN of the default listener for the frontend"
  value       = var.ssl_certificate_arn == null ? aws_lb_listener.http_default[0].arn : aws_lb_listener.http[0].arn
}

output "api_listener_rule_arn" {
  description = "The ARN of the listener rule for the API"
  value       = aws_lb_listener_rule.api.arn
}
