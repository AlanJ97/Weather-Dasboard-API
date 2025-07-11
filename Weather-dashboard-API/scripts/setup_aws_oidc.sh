#!/bin/bash

# This script automates the setup of an AWS IAM OIDC provider for GitHub Actions
# and creates an IAM role that can be assumed by a specific GitHub repository.
#
# Prerequisites:
# - AWS CLI installed and configured with necessary permissions (iam:Create*, iam:Get*, sts:Get*).
# - Git Bash or WSL to run the script on Windows.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
# Please verify these values before running the script.
GITHUB_ORG="AlanJ97"
REPO_NAME="Weather-Dasboard-API"
ROLE_NAME="GitHubActions-Terraform-Backend-Role"
# We'll create multiple smaller policies instead of one large one
POLICY_NAMES=("GitHubActions-Terraform-S3-Policy" "GitHubActions-Terraform-EC2-Policy" "GitHubActions-Terraform-ECS-Policy" "GitHubActions-Terraform-Monitoring-Policy")
BUCKET_NAME="weather-app-backend-terraform-bucket-2025"
AWS_REGION="us-east-1"


# --- OIDC Provider Details ---
OIDC_PROVIDER_URL="token.actions.githubusercontent.com"
AUDIENCE="sts.amazonaws.com"

echo "Fetching AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$ACCOUNT_ID" ]; then
    echo "Error: Could not retrieve AWS Account ID. Please ensure AWS CLI is configured correctly."
    exit 1
fi
echo "AWS Account ID: $ACCOUNT_ID"

OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER_URL}"

echo "Checking for existing OIDC provider..."
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" >/dev/null 2>&1; then
    echo "OIDC provider already exists."
else
    echo "OIDC provider not found. Creating a new one..."
    aws iam create-open-id-connect-provider --url "https://${OIDC_PROVIDER_URL}" --client-id-list "$AUDIENCE" --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" # Standard thumbprint for GitHub OIDC
    echo "OIDC provider created successfully."
fi

# --- Define Trust Policy ---
echo "Defining IAM role trust policy..."
TRUST_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${OIDC_PROVIDER_ARN}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${OIDC_PROVIDER_URL}:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "${OIDC_PROVIDER_URL}:sub": "repo:${GITHUB_ORG}/${REPO_NAME}:*"
                }
            }
        }
    ]
}
EOF
)

# --- Define Permissions Policies (Split into smaller policies) ---
echo "Defining IAM permissions policies for Terraform..."

# Policy 1: S3 Backend and Basic IAM
S3_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:DescribeLogGroups",
                "logs:TagResource",
                "logs:PutRetentionPolicy",
                "logs:ListTagsForResource",
                "iam:CreateRole",
                "iam:GetRole",
                "iam:TagRole",
                "iam:PutRolePolicy",
                "iam:AttachRolePolicy",
                "iam:PassRole",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:GetRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:TagInstanceProfile",
                "iam:ListInstanceProfiles",
                "iam:DeleteRole",
                "iam:DeleteRolePolicy",
                "iam:DetachRolePolicy",
                "iam:ListInstanceProfilesForRole"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

# Policy 2: EC2 and VPC
EC2_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AllocateAddress",
                "ec2:AssociateAddress",
                "ec2:AssociateRouteTable",
                "ec2:AttachInternetGateway",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateFlowLogs",
                "ec2:CreateInternetGateway",
                "ec2:CreateNatGateway",
                "ec2:CreateRoute",
                "ec2:CreateRouteTable",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSubnet",
                "ec2:CreateTags",
                "ec2:CreateVpc",
                "ec2:DeleteFlowLogs",
                "ec2:DeleteInternetGateway",
                "ec2:DeleteKeyPair",
                "ec2:DeleteNatGateway",
                "ec2:DeleteRoute",
                "ec2:DeleteRouteTable",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSubnet",
                "ec2:DeleteVpc",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeAddressesAttribute",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeFlowLogs",
                "ec2:DescribeImages",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeNatGateways",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSecurityGroupRules",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeTags",
                "ec2:DescribeVpcAttribute",
                "ec2:DetachInternetGateway",
                "ec2:DisassociateRouteTable",
                "ec2:ImportKeyPair",
                "ec2:ModifySubnetAttribute",
                "ec2:ModifyVpcAttribute",
                "ec2:ReleaseAddress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RunInstances",
                "ec2:TerminateInstances",
                "ec2:StopInstances",
                "ec2:StartInstances",
                "ec2:CreateLaunchTemplate",
                "ec2:DeleteLaunchTemplate",
                "ec2:DescribeLaunchTemplates"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

# Policy 3: ECS, ECR, and Load Balancing
ECS_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:CreateRepository",
                "ecr:TagResource",
                "ecr:DescribeRepositories",
                "ecr:ListTagsForResource",
                "ecr:PutLifecyclePolicy",
                "ecr:GetLifecyclePolicy",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:GetAuthorizationToken",
                "ecs:CreateCluster",
                "ecs:TagResource",
                "ecs:DescribeClusters",
                "ecs:ListTagsForResource",
                "ecs:PutClusterCapacityProviders",
                "ecs:RegisterTaskDefinition",
                "ecs:CreateService",
                "ecs:UpdateService",
                "ecs:DescribeServices",
                "ecs:ListServices",
                "ecs:ListTaskDefinitions",
                "ecs:ListTasks",
                "ecs:DescribeTaskDefinition",
                "ecs:DeregisterTaskDefinition",
                "ecs:DeleteCluster",
                "ecs:DeleteService",
                "ecs:DescribeTasks",
                "ecs:StopTask",
                "ecs:ListClusters",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListenerAttributes",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:RemoveTags",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DeleteRule",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

# Policy 4: Monitoring and Auto Scaling
MONITORING_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "application-autoscaling:RegisterScalableTarget",
                "application-autoscaling:DeregisterScalableTarget",
                "application-autoscaling:DescribeScalableTargets",
                "application-autoscaling:PutScalingPolicy",
                "application-autoscaling:DescribeScalingPolicies",
                "application-autoscaling:DeleteScalingPolicy",
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:TagResource",
                "cloudwatch:UntagResource",
                "cloudwatch:ListTagsForResource",
                "autoscaling:CreateAutoScalingGroup",
                "autoscaling:DeleteAutoScalingGroup",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:CreateLaunchConfiguration",
                "autoscaling:DeleteLaunchConfiguration",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:PutScalingPolicy",
                "autoscaling:DeletePolicy",
                "autoscaling:DescribePolicies",
                "autoscaling:CreateOrUpdateTags",
                "autoscaling:DeleteTags",
                "autoscaling:DescribeTags"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

# --- Create/Update Role and Policies ---

echo "Checking for IAM role: ${ROLE_NAME}..."
if ! ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query "Role.Arn" --output text 2>/dev/null); then
    echo "Role not found. Creating new role..."
    ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "$TRUST_POLICY" --query "Role.Arn" --output text)
    echo "Role created successfully with ARN: ${ROLE_ARN}"
else
    echo "Role already exists. Updating trust policy..."
    aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document "$TRUST_POLICY"
    echo "Trust policy updated successfully."
fi

# Array of policies to create/update
declare -A POLICIES
POLICIES["${POLICY_NAMES[0]}"]="$S3_POLICY"
POLICIES["${POLICY_NAMES[1]}"]="$EC2_POLICY" 
POLICIES["${POLICY_NAMES[2]}"]="$ECS_POLICY"
POLICIES["${POLICY_NAMES[3]}"]="$MONITORING_POLICY"

# Create/update each policy with guaranteed cleanup and attachment
for POLICY_NAME in "${POLICY_NAMES[@]}"; do
    POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
    echo ""
    echo "🔄 Processing IAM policy: ${POLICY_NAME}..."
    
    if ! aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
        echo "  📄 Policy ${POLICY_NAME} not found. Creating new policy..."
        aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "${POLICIES[$POLICY_NAME]}"
        echo "  ✅ Policy ${POLICY_NAME} created successfully."
    else
        echo "  📄 Policy ${POLICY_NAME} already exists. Updating with new version..."
        
        # Create new version and set as default
        NEW_VERSION=$(aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document "${POLICIES[$POLICY_NAME]}" --set-as-default --query 'PolicyVersion.VersionId' --output text)
        echo "  🆕 Created new policy version: ${NEW_VERSION} (now default)"
        
        # Wait a moment for AWS to propagate the change
        sleep 2
        
        # Clean up ALL old versions (keeping only the new default version)
        echo "  🧹 Cleaning up old policy versions for ${POLICY_NAME}..."
        OLD_VERSIONS=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query 'Versions[?!IsDefaultVersion].VersionId' --output text)
        
        if [ -n "$OLD_VERSIONS" ] && [ "$OLD_VERSIONS" != "None" ]; then
            for version in $OLD_VERSIONS; do
                echo "    🗑️  Deleting old policy version: $version"
                aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$version"
            done
            echo "  ✅ Old policy versions cleaned up for ${POLICY_NAME}."
        else
            echo "  ℹ️  No old versions to clean up for ${POLICY_NAME}."
        fi
    fi
    
    # Ensure policy is attached to role (idempotent - won't fail if already attached)
    echo "  🔗 Ensuring policy ${POLICY_NAME} is attached to role..."
    if aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN" 2>/dev/null; then
        echo "  ✅ Policy ${POLICY_NAME} attached to role successfully."
    else
        # Policy might already be attached, check if it's already there
        if aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[?PolicyArn=='$POLICY_ARN'].PolicyName" --output text | grep -q "$POLICY_NAME"; then
            echo "  ℹ️  Policy ${POLICY_NAME} already attached to role."
        else
            echo "  ❌ Failed to attach policy ${POLICY_NAME} to role."
            exit 1
        fi
    fi
done

echo "IAM role and policy have been attached."
echo ""
echo "--- SETUP COMPLETE ---"
echo "The IAM Role ARN is: ${ROLE_ARN}"
echo ""
echo "Next Step: Add this ARN as a secret in your GitHub repository."
echo "  1. Go to your repository > Settings > Secrets and variables > Actions."
echo "  2. Create a new repository secret named 'AWS_ROLE_TO_ASSUME'."
echo "  3. Paste the ARN above as the value."

