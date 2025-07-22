#!/bin/bash

# This script cleans up existing AWS resources that are conflicting with Terraform
# Run this script before running Terraform apply to avoid "already exists" errors

set -e

echo "🧹 Cleaning up conflicting AWS resources..."

AWS_REGION="us-east-2"

# List of IAM roles to delete
ROLES=(
    "dev-weather-bastion-role"
    "dev-weather-ecs-task-execution-role"
    "dev-weather-ecs-task-role" 
    "dev-vpc-flow-log-role"
    "dev-weather-dashboard-codebuild-role"
    "dev-weather-dashboard-codedeploy-role"
    "dev-weather-dashboard-codepipeline-role"
)

# List of IAM Instance Profiles to delete
INSTANCE_PROFILES=(
    "dev-weather-bastion-profile"
)

# List of CloudWatch log groups to delete
LOG_GROUPS=(
    "/ecs/dev-weather"
    "/aws/vpc/flow-logs-dev"
    "/aws/lambda/codedeploy-hook-after_allow_traffic-dev"
    "/aws/lambda/codedeploy-hook-after_install-dev"
    "/aws/lambda/codedeploy-hook-before_allow_traffic-dev"
    "/aws/lambda/codedeploy-hook-before_install-dev"
    "/aws/lambda/codedeploy-hook-after_allow_test_traffic-dev"
    "/aws/codebuild/dev-weather-dashboard-build"
    "/aws/codedeploy/dev-weather-dashboard"
)

# List of EC2 Key Pairs to delete  
KEY_PAIRS=(
    "dev-weather-bastion-key"
)

echo "🗑️  Deleting conflicting IAM Instance Profiles..."
for instance_profile in "${INSTANCE_PROFILES[@]}"; do
    echo "Checking IAM Instance Profile: $instance_profile"
    if aws iam get-instance-profile --instance-profile-name "$instance_profile" >/dev/null 2>&1; then
        echo "  Found instance profile: $instance_profile"
        
        # List roles attached to the instance profile
        ATTACHED_ROLES=$(aws iam get-instance-profile --instance-profile-name "$instance_profile" --query 'InstanceProfile.Roles[].RoleName' --output text 2>/dev/null || echo "")
        
        # Remove roles from instance profile
        if [ -n "$ATTACHED_ROLES" ]; then
            for role_name in $ATTACHED_ROLES; do
                echo "    Removing role $role_name from instance profile $instance_profile"
                aws iam remove-role-from-instance-profile --instance-profile-name "$instance_profile" --role-name "$role_name"
            done
        fi
        
        echo "    Deleting instance profile: $instance_profile"
        aws iam delete-instance-profile --instance-profile-name "$instance_profile"
        echo "  ✅ Deleted instance profile: $instance_profile"
    else
        echo "  ℹ️  Instance Profile $instance_profile does not exist, skipping"
    fi
done

echo ""
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

# Delete all log groups from the array
for log_group in "${LOG_GROUPS[@]}"; do
    echo "Checking log group: $log_group"
    # Use MSYS_NO_PATHCONV=1 to prevent Git Bash from converting Unix paths on Windows
    if MSYS_NO_PATHCONV=1 aws logs describe-log-groups --region "$AWS_REGION" --log-group-name-prefix "$log_group" --query "logGroups[?logGroupName=='$log_group'].logGroupName" --output text 2>/dev/null | grep -q "$(basename "$log_group")"; then
        echo "  Deleting log group: $log_group"
        MSYS_NO_PATHCONV=1 aws logs delete-log-group --log-group-name "$log_group" --region "$AWS_REGION"
        echo "  ✅ Deleted log group: $log_group"
    else
        echo "  ℹ️  Log group $log_group does not exist, skipping"
    fi
done

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
