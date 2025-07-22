#!/bin/bash

# Configuration file for IAM permission scripts
# This file centralizes all configurable values to avoid hardcoding

# Default values - can be overridden by environment variables
DEFAULT_GITHUB_ORG="${GITHUB_ORG:-AlanJ97}"
DEFAULT_REPO_NAME="${REPO_NAME:-Weather-Dasboard-API}"
DEFAULT_AWS_REGION="${AWS_REGION:-us-east-2}"
DEFAULT_ENVIRONMENT="${ENVIRONMENT:-dev}"
DEFAULT_BUCKET_NAME="${BUCKET_NAME:-weather-app-backend-terraform-bucket-2025-ohio}"

# Export configuration for use by other scripts
export CONFIGURED_GITHUB_ORG="$DEFAULT_GITHUB_ORG"
export CONFIGURED_REPO_NAME="$DEFAULT_REPO_NAME"
export CONFIGURED_AWS_REGION="$DEFAULT_AWS_REGION"
export CONFIGURED_ENVIRONMENT="$DEFAULT_ENVIRONMENT"
export CONFIGURED_BUCKET_NAME="$DEFAULT_BUCKET_NAME"

# IAM Role Configuration
export CONFIGURED_ROLE_NAME="GitHubActions-Terraform-Backend-Role"
export CONFIGURED_POLICY_NAMES=(
    "GitHubActions-Terraform-S3-Policy"
    "GitHubActions-Terraform-EC2-Policy"
    "GitHubActions-Terraform-ECS-Policy"
    "GitHubActions-Terraform-Monitoring-Policy"
    "GitHubActions-Terraform-CICD-Policy"
)

# Resource naming patterns (environment-specific)
export CONFIGURED_ROLES=(
    "${CONFIGURED_ENVIRONMENT}-weather-bastion-role"
    "${CONFIGURED_ENVIRONMENT}-weather-ecs-task-execution-role"
    "${CONFIGURED_ENVIRONMENT}-weather-ecs-task-role"
    "${CONFIGURED_ENVIRONMENT}-vpc-flow-log-role"
    "${CONFIGURED_ENVIRONMENT}-weather-dashboard-codebuild-role"
    "${CONFIGURED_ENVIRONMENT}-weather-dashboard-codedeploy-role"
    "${CONFIGURED_ENVIRONMENT}-weather-dashboard-codepipeline-role"
)

export CONFIGURED_INSTANCE_PROFILES=(
    "${CONFIGURED_ENVIRONMENT}-weather-bastion-profile"
)

export CONFIGURED_LOG_GROUPS=(
    "/ecs/${CONFIGURED_ENVIRONMENT}-weather"
    "/aws/vpc/flow-logs-${CONFIGURED_ENVIRONMENT}"
    "/aws/lambda/codedeploy-hook-after_allow_traffic-${CONFIGURED_ENVIRONMENT}"
    "/aws/lambda/codedeploy-hook-after_install-${CONFIGURED_ENVIRONMENT}"
    "/aws/lambda/codedeploy-hook-before_allow_traffic-${CONFIGURED_ENVIRONMENT}"
    "/aws/lambda/codedeploy-hook-before_install-${CONFIGURED_ENVIRONMENT}"
    "/aws/lambda/codedeploy-hook-after_allow_test_traffic-${CONFIGURED_ENVIRONMENT}"
    "/aws/codebuild/${CONFIGURED_ENVIRONMENT}-weather-dashboard-build"
    "/aws/codedeploy/${CONFIGURED_ENVIRONMENT}-weather-dashboard"
)

export CONFIGURED_KEY_PAIRS=(
    "${CONFIGURED_ENVIRONMENT}-weather-bastion-key"
)

# OIDC Provider Configuration
export CONFIGURED_OIDC_PROVIDER_URL="token.actions.githubusercontent.com"
export CONFIGURED_AUDIENCE="sts.amazonaws.com"

echo "✅ Configuration loaded:"
echo "  GitHub Org: $CONFIGURED_GITHUB_ORG"
echo "  Repository: $CONFIGURED_REPO_NAME"
echo "  AWS Region: $CONFIGURED_AWS_REGION"
echo "  Environment: $CONFIGURED_ENVIRONMENT"
echo "  Bucket Name: $CONFIGURED_BUCKET_NAME"
