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
POLICY_NAME="GitHubActions-Terraform-S3-Policy"
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

# --- Define Permissions Policy ---
echo "Defining IAM permissions policy for Terraform S3 backend..."
PERMISSIONS_POLICY=$(cat <<EOF
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
                "iam:CreateRole",
                "iam:GetRole",
                "iam:PutRolePolicy",
                "iam:AttachRolePolicy",
                "iam:PassRole",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeNatGateways",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

# --- Create/Update Role and Policy ---

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

POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
echo "Checking for IAM policy: ${POLICY_NAME}..."
if ! aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
    echo "Policy not found. Creating new policy..."
    aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "$PERMISSIONS_POLICY"
    echo "Policy created successfully."
else
    echo "Policy already exists. Creating new version..."
    aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document "$PERMISSIONS_POLICY" --set-as-default
    echo "Policy updated with new version successfully."
    
    echo "Cleaning up old policy versions..."
    # Get all non-default versions and delete them
    OLD_VERSIONS=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query 'Versions[?!IsDefaultVersion].VersionId' --output text)
    if [ -n "$OLD_VERSIONS" ]; then
        for version in $OLD_VERSIONS; do
            echo "Deleting old policy version: $version"
            aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$version"
        done
        echo "Old policy versions cleaned up."
    else
        echo "No old versions to clean up."
    fi
fi

echo "Attaching policy to role..."
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"

echo "IAM role and policy have been attached."
echo ""
echo "--- SETUP COMPLETE ---"
echo "The IAM Role ARN is: ${ROLE_ARN}"
echo ""
echo "Next Step: Add this ARN as a secret in your GitHub repository."
echo "  1. Go to your repository > Settings > Secrets and variables > Actions."
echo "  2. Create a new repository secret named 'AWS_ROLE_TO_ASSUME'."
echo "  3. Paste the ARN above as the value."

