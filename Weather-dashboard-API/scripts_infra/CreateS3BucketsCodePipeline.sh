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

# Load configuration from Python config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/config.py" ]; then
    echo "❌ config.py not found in $SCRIPT_DIR"
    echo "Please copy config.py.example to config.py and update with your values"
    exit 1
fi

# Function to find available Python command
find_python() {
    for cmd in python python3 py; do
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "$cmd"
            return 0
        fi
    done
    return 1
}

# Find Python command
PYTHON_CMD=$(find_python)
if [ $? -ne 0 ]; then
    echo "❌ Python not found. Please install Python or ensure it's in your PATH"
    echo "Available commands checked: python, python3, py"
    exit 1
fi

echo "Using Python command: $PYTHON_CMD"

# Get bucket names using Python config
BUCKET_NAMES=$($PYTHON_CMD -c "
import sys
sys.path.append('$SCRIPT_DIR')
from config import get_bucket_names
buckets = get_bucket_names('$ENVIRONMENT')
print(f\"{buckets['pipeline']}|{buckets['codebuild']}\")
" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$BUCKET_NAMES" ]; then
    echo "❌ Failed to load configuration from config.py"
    echo "Falling back to default naming convention..."
    # Fallback to default naming (matching config.py logic)
    CURRENT_YEAR=$(date +%Y)
    PIPELINE_BUCKET="${ENVIRONMENT}-dashboard-weather-app-pipeline-artifacts-${CURRENT_YEAR}"
    CODEBUILD_BUCKET="${ENVIRONMENT}-dashboard-weather-app-codebuild-cache-${CURRENT_YEAR}"
    REGION="us-east-2"
    PROJECT_NAME="dashboard-weather-app"
    ORGANIZATION="PersonalProject"
    COST_CENTER="Engineering"
    TEAM_NAME="DevOps-Team"
    echo "Using fallback values:"
    echo "   - Pipeline bucket: $PIPELINE_BUCKET"
    echo "   - CodeBuild bucket: $CODEBUILD_BUCKET"
else
    # Parse bucket names from Python output
    IFS='|' read -r PIPELINE_BUCKET CODEBUILD_BUCKET <<< "$BUCKET_NAMES"
    
    # Get region from config
    REGION=$($PYTHON_CMD -c "
import sys
sys.path.append('$SCRIPT_DIR')
from config import get_config
config = get_config()
print(config['aws_region'])
" 2>/dev/null)
    
    # Get project configuration for tagging
    PROJECT_CONFIG=$($PYTHON_CMD -c "
import sys
sys.path.append('$SCRIPT_DIR')
from config import get_config
config = get_config()
print(f\"{config['project_name']}|{config['organization']}|{config['cost_center']}|{config['team_name']}\")
" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$PROJECT_CONFIG" ]; then
        IFS='|' read -r PROJECT_NAME ORGANIZATION COST_CENTER TEAM_NAME <<< "$PROJECT_CONFIG"
    else
        echo "⚠️  Failed to load project config, using defaults"
        PROJECT_NAME="dashboard-weather-app"
        ORGANIZATION="PersonalProject"
        COST_CENTER="Engineering"
        TEAM_NAME="DevOps-Team"
    fi
    
    # Default region if not loaded
    if [ -z "$REGION" ]; then
        REGION="us-east-2"
    fi
fi

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
    {Key=Project,Value=$PROJECT_NAME},
    {Key=Application,Value=$PROJECT_NAME},
    {Key=Owner,Value=$TEAM_NAME},
    {Key=Purpose,Value=pipeline-artifacts},
    {Key=CostCenter,Value=$COST_CENTER},
    {Key=ManagedBy,Value=bash-script}
  ]"

# Add tags to CodeBuild cache bucket
aws s3api put-bucket-tagging \
  --bucket "$CODEBUILD_BUCKET" \
  --tagging "TagSet=[
    {Key=Environment,Value=$ENVIRONMENT},
    {Key=Project,Value=$PROJECT_NAME},
    {Key=Application,Value=$PROJECT_NAME},
    {Key=Owner,Value=$TEAM_NAME},
    {Key=Purpose,Value=codebuild-cache},
    {Key=CostCenter,Value=$COST_CENTER},
    {Key=ManagedBy,Value=bash-script}
  ]"

echo "✅ Buckets created and configured successfully!"
echo "   - $PIPELINE_BUCKET"
echo "   - $CODEBUILD_BUCKET"
echo ""
echo "🏷️  Tags applied:"
echo "   - Environment: $ENVIRONMENT"
echo "   - Project: $PROJECT_NAME"
echo "   - Application: $PROJECT_NAME"
echo "   - Owner: $TEAM_NAME"
echo "   - CostCenter: $COST_CENTER"
