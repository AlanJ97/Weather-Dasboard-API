# Key Pair for Bastion Host
resource "aws_key_pair" "bastion" {
  key_name   = "${var.env}-weather-bastion-key"
  public_key = var.public_key

  tags = {
    Name        = "${var.env}-weather-bastion-key"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name_prefix = "${var.env}-weather-bastion-"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-weather-bastion-sg"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for Bastion Host
resource "aws_iam_role" "bastion" {
  name = "${var.env}-weather-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.env}-weather-bastion-role"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Bastion Host
resource "aws_iam_role_policy" "bastion" {
  name = "${var.env}-weather-bastion-policy"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/${var.env}/weather/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:ListTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.env}-weather-bastion-profile"
  role = aws_iam_role.bastion.name

  tags = {
    Name        = "${var.env}-weather-bastion-profile"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script for bastion host
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    env        = var.env
    aws_region = var.aws_region
  }))
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.bastion.key_name
  vpc_security_group_ids  = [aws_security_group.bastion.id]
  subnet_id               = var.public_subnet_id
  iam_instance_profile    = aws_iam_instance_profile.bastion.name
  user_data               = local.user_data
  disable_api_termination = var.enable_termination_protection

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.env}-weather-bastion"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
    Role        = "bastion"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name        = "${var.env}-weather-bastion-eip"
    Environment = var.env
    Project     = "weather-dashboard"
    ManagedBy   = "terraform"
  }

  depends_on = [aws_instance.bastion]
}
