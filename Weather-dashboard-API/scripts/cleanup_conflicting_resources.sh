#!/bin/bash

# This script cleans up existing AWS resources that are conflicting with Terraform
# Run this script before running Terraform apply to avoid "already exists" errors

set -e

echo "🧹 Cleaning up conflicting AWS resources..."

AWS_REGION="us-east-1"

# List of IAM roles to delete
ROLES=(
    "dev-weather-bastion-role"
    "dev-weather-ecs-task-execution-role"
    "dev-weather-ecs-task-role" 
    "dev-vpc-flow-log-role"
)

# List of CloudWatch log groups to delete
LOG_GROUPS=(
    "/ecs/dev-weather"
    "/aws/vpc/flow-logs-dev"
)

# List of EC2 Key Pairs to delete  
KEY_PAIRS=(
    "dev-weather-bastion-key"
)

echo "🗑️  Deleting conflicting IAM roles..."
for role in "${ROLES[@]}"; do
    echo "Checking IAM role: $role"
    if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
        echo "  Detaching policies from role: $role"
        # List and detach managed policies
        ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || echo "")
        if [ -n "$ATTACHED_POLICIES" ]; then
            for policy_arn in $ATTACHED_POLICIES; do
                echo "    Detaching policy: $policy_arn"
                aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn"
            done
        fi
        
        # List and delete inline policies
        INLINE_POLICIES=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames' --output text 2>/dev/null || echo "")
        if [ -n "$INLINE_POLICIES" ]; then
            for policy_name in $INLINE_POLICIES; do
                echo "    Deleting inline policy: $policy_name"
                aws iam delete-role-policy --role-name "$role" --policy-name "$policy_name"
            done
        fi
        
        echo "    Deleting role: $role"
        aws iam delete-role --role-name "$role"
        echo "  ✅ Deleted role: $role"
    else
        echo "  ℹ️  Role $role does not exist, skipping"
    fi
done

echo ""
echo "🗑️  Deleting conflicting CloudWatch log groups..."

# Delete log groups individually to avoid path conversion issues
echo "Checking log group: /ecs/dev-weather"
if MSYS_NO_PATHCONV=1 aws logs describe-log-groups --region "$AWS_REGION" --query "logGroups[?logGroupName=='/ecs/dev-weather'].logGroupName" --output text 2>/dev/null | grep -q "dev-weather"; then
    echo "  Deleting log group: /ecs/dev-weather"
    MSYS_NO_PATHCONV=1 aws logs delete-log-group --log-group-name "/ecs/dev-weather" --region "$AWS_REGION"
    echo "  ✅ Deleted log group: /ecs/dev-weather"
else
    echo "  ℹ️  Log group /ecs/dev-weather does not exist, skipping"
fi

echo "Checking log group: /aws/vpc/flow-logs-dev"
if MSYS_NO_PATHCONV=1 aws logs describe-log-groups --region "$AWS_REGION" --query "logGroups[?logGroupName=='/aws/vpc/flow-logs-dev'].logGroupName" --output text 2>/dev/null | grep -q "flow-logs-dev"; then
    echo "  Deleting log group: /aws/vpc/flow-logs-dev"
    MSYS_NO_PATHCONV=1 aws logs delete-log-group --log-group-name "/aws/vpc/flow-logs-dev" --region "$AWS_REGION"
    echo "  ✅ Deleted log group: /aws/vpc/flow-logs-dev"
else
    echo "  ℹ️  Log group /aws/vpc/flow-logs-dev does not exist, skipping"
fi

echo ""
echo "🗑️  Deleting conflicting EC2 Key Pairs..."
for key_pair in "${KEY_PAIRS[@]}"; do
    echo "Checking EC2 Key Pair: $key_pair"
    if aws ec2 describe-key-pairs --key-names "$key_pair" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "  Deleting EC2 Key Pair: $key_pair"
        aws ec2 delete-key-pair --key-name "$key_pair" --region "$AWS_REGION"
        echo "  ✅ Deleted EC2 Key Pair: $key_pair"
    else
        echo "  ℹ️  EC2 Key Pair $key_pair does not exist, skipping"
    fi
done

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run the updated setup_aws_oidc.sh script to update IAM permissions"
echo "2. Run your Terraform workflow again"
echo ""
echo "Note: VPC and other resources were not deleted as they might be in use."
echo "If you need to completely start over, delete those manually from AWS Console."
