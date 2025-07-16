#!/bin/bash

# Set your region
REGION="us-east-2"

# Pipeline artifacts bucket
PIPELINE_BUCKET="dev-weather-dashboard-pipeline-artifacts-2025"

# CodeBuild cache bucket
CODEBUILD_BUCKET="dev-weather-dashboard-codebuild-cache-2025"

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

echo "Buckets created and configured: $PIPELINE_BUCKET, $CODEBUILD_BUCKET"
