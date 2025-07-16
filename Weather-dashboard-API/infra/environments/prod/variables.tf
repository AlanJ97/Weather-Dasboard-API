variable "env" {
  description = "Environment name"
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.3.0/24", "10.2.4.0/24"]
}
