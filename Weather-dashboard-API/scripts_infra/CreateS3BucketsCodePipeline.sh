#!/bin/bash

# Check if environment is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    echo "         $0 staging"
    echo "         $0 prod"
    exit 1
fi

# Set environment from command line argument
ENVIRONMENT="$1"

# Set your region
REGION="us-east-2"

# Pipeline artifacts bucket
PIPELINE_BUCKET="${ENVIRONMENT}-weather-dashboard-pipeline-artifacts-2025"

# CodeBuild cache bucket
CODEBUILD_BUCKET="${ENVIRONMENT}-weather-dashboard-codebuild-cache-2025"

echo "🚀 Creating S3 buckets for environment: $ENVIRONMENT"
echo "   - Pipeline bucket: $PIPELINE_BUCKET"
echo "   - CodeBuild bucket: $CODEBUILD_BUCKET"
echo ""

# Create pipeline artifacts bucket
aws s3api create-bucket \
  --bucket "$PIPELINE_BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Create CodeBuild cache bucket
aws s3api create-bucket \
  --bucket "$CODEBUILD_BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Enable versioning on both buckets
aws s3api put-bucket-versioning \
  --bucket "$PIPELINE_BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning \
  --bucket "$CODEBUILD_BUCKET" \
  --versioning-configuration Status=Enabled

# Enable default encryption on both buckets
aws s3api put-bucket-encryption \
  --bucket "$PIPELINE_BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-bucket-encryption \
  --bucket "$CODEBUILD_BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block public access on both buckets
aws s3api put-public-access-block \
  --bucket "$PIPELINE_BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-public-access-block \
  --bucket "$CODEBUILD_BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Add tags to pipeline artifacts bucket
aws s3api put-bucket-tagging \
  --bucket "$PIPELINE_BUCKET" \
  --tagging "TagSet=[
    {Key=Environment,Value=$ENVIRONMENT},
    {Key=Project,Value=weather-dashboard},
    {Key=Application,Value=weather-dashboard-api},
    {Key=Owner,Value=DevOps-Team},
    {Key=Purpose,Value=pipeline-artifacts},
    {Key=CostCenter,Value=Engineering},
    {Key=ManagedBy,Value=terraform}
  ]"

# Add tags to CodeBuild cache bucket
aws s3api put-bucket-tagging \
  --bucket "$CODEBUILD_BUCKET" \
  --tagging "TagSet=[
    {Key=Environment,Value=$ENVIRONMENT},
    {Key=Project,Value=weather-dashboard},
    {Key=Application,Value=weather-dashboard-api},
    {Key=Owner,Value=DevOps-Team},
    {Key=Purpose,Value=codebuild-cache},
    {Key=CostCenter,Value=Engineering},
    {Key=ManagedBy,Value=terraform}
  ]"

echo "✅ Buckets created and configured successfully!"
echo "   - $PIPELINE_BUCKET"
echo "   - $CODEBUILD_BUCKET"
echo ""
echo "🏷️  Tags applied:"
echo "   - Environment: $ENVIRONMENT"
echo "   - Project: weather-dashboard"
echo "   - Application: weather-dashboard-api"
echo "   - Owner: DevOps-Team"
echo "   - CostCenter: Engineering"
