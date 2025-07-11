#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables
BUCKET_NAME="weather-app-backend-terraform-bucket-2025"
AWS_REGION="us-east-1"

# Check AWS CLI version and object-lock parameter support
echo "Checking AWS CLI version and object-lock parameter support..."
aws --version
aws s3api create-bucket help | grep -i "object-lock" || echo "Object lock parameter not found in current AWS CLI version"

# Check if bucket exists and delete it if it does
echo "Checking if S3 bucket exists: $BUCKET_NAME..."
if aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
    echo "Bucket exists. Removing all objects and versions..."
    
    # Remove all objects and versions from the bucket
    aws s3api delete-objects --bucket $BUCKET_NAME --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null || true
    aws s3api delete-objects --bucket $BUCKET_NAME --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null || true
    
    echo "Deleting S3 bucket: $BUCKET_NAME..."
    aws s3api delete-bucket --bucket $BUCKET_NAME
    echo "Bucket deleted successfully."
else
    echo "Bucket does not exist. Proceeding with creation."
fi

# Create the S3 bucket with Object Lock enabled
echo "Creating S3 bucket with Object Lock: $BUCKET_NAME..."
if [ "$AWS_REGION" = "us-east-1" ]; then
    # us-east-1 doesn't need CreateBucketConfiguration
    aws s3api create-bucket --bucket $BUCKET_NAME --object-lock-enabled-for-bucket
else
    # Other regions need CreateBucketConfiguration
    aws s3api create-bucket --bucket $BUCKET_NAME --create-bucket-configuration LocationConstraint=$AWS_REGION --object-lock-enabled-for-bucket
fi

# Enable versioning on the S3 bucket (required for Object Lock)
echo "Enabling versioning on S3 bucket: $BUCKET_NAME..."
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# Configure Object Lock retention (optional but recommended)
echo "Configuring Object Lock retention policy..."
aws s3api put-object-lock-configuration --bucket $BUCKET_NAME --object-lock-configuration '{
    "ObjectLockEnabled": "Enabled",
    "Rule": {
        "DefaultRetention": {
            "Mode": "GOVERNANCE",
            "Days": 1
        }
    }
}'

echo "Terraform S3 backend setup complete with Object Lock enabled."
