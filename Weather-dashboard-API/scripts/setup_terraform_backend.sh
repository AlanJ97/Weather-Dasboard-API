#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables
BUCKET_NAME="weather-app-backend-terraform-bucket-2025"
AWS_REGION="us-east-1"

# Create the S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME..."
aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION

# Enable versioning on the S3 bucket
echo "Enabling versioning on S3 bucket: $BUCKET_NAME..."
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

echo "Terraform S3 backend setup complete."
