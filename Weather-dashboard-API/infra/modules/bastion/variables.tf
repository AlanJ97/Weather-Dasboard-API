variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the bastion host will be created"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion host"
  type        = string
}

variable "public_key" {
  description = "Public key for the bastion host key pair"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the bastion host via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "enable_termination_protection" {
  description = "Enable termination protection for the bastion host"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for the bastion host"
  type        = bool
  default     = false
}

variable "enable_eip" {
  description = "Enable Elastic IP for the bastion host"
  type        = bool
  default     = true
}

variable "key_pair_name" {
  description = "Custom name for the key pair (if not provided, will use env-weather-bastion-key)"
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "Custom name for the security group (if not provided, will use env-weather-bastion-sg)"
  type        = string
  default     = null
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the bastion host"
  type        = list(string)
  default     = []
}

variable "user_data_script" {
  description = "Custom user data script (if not provided, will use default)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
