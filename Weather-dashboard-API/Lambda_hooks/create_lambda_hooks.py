#!/usr/bin/env python3
"""
Lambda Hook Functions Creator for CodeDeploy
Creates the 4 Lambda functions needed for CodeDeploy hooks in AWS Ohio region.
"""

import boto3
import zipfile
import os
import json
import sys
import time
from pathlib import Path

# Configuration
AWS_REGION = 'us-east-2'  # Ohio region
LAMBDA_RUNTIME = 'python3.11'
LAMBDA_TIMEOUT = 60
LAMBDA_MEMORY = 128

# Lambda function configurations
LAMBDA_FUNCTIONS = [
    {
        'name': 'before_install',
        'file': 'before_install.py',
        'description': 'CodeDeploy hook - executed before install phase'
    },
    {
        'name': 'install',
        'file': 'install.py',
        'description': 'CodeDeploy hook - executed during install phase'
    },
    {
        'name': 'after_install',
        'file': 'after_install.py',
        'description': 'CodeDeploy hook - executed after install phase'
    },
    {
        'name': 'before_allow_traffic',
        'file': 'before_allow_traffic.py',
        'description': 'CodeDeploy hook - executed before allowing traffic'
    },
    {
        'name': 'after_allow_traffic',
        'file': 'after_allow_traffic.py',
        'description': 'CodeDeploy hook - executed after allowing traffic'
    }
]

class LambdaHooksCreator:
    def __init__(self, environment='dev'):
        self.environment = environment
        self.lambda_client = boto3.client('lambda', region_name=AWS_REGION)
        self.iam_client = boto3.client('iam', region_name=AWS_REGION)
        self.script_dir = Path(__file__).parent
        
    def create_execution_role(self):
        """Create IAM role for Lambda execution"""
        role_name = f'lambda-codedeploy-hooks-role-{self.environment}'
        
        # Trust policy for Lambda
        trust_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "lambda.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
        
        # Policy for CodeDeploy hooks
        policy_document = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Resource": "arn:aws:logs:*:*:*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "codedeploy:PutLifecycleEventHookExecutionStatus",
                        "codedeploy:GetDeployment",
                        "codedeploy:GetApplication",
                        "codedeploy:GetDeploymentGroup",
                        "codedeploy:GetDeploymentConfig",
                        "codedeploy:GetApplicationRevision"
                    ],
                    "Resource": "*"
                }
            ]
        }
        
        try:
            # Check if role already exists
            self.iam_client.get_role(RoleName=role_name)
            print(f"✓ IAM role '{role_name}' already exists")
            
            # Update the policy even if role exists to ensure it has latest permissions
            print(f"🔄 Updating IAM policy with latest permissions...")
            self.iam_client.put_role_policy(
                RoleName=role_name,
                PolicyName=f'LambdaCodeDeployHooksPolicy-{self.environment}',
                PolicyDocument=json.dumps(policy_document)
            )
            print(f"✓ Updated IAM policy with latest permissions")
            
        except self.iam_client.exceptions.NoSuchEntityException:
            # Create role
            print(f"Creating IAM role '{role_name}'...")
            self.iam_client.create_role(
                RoleName=role_name,
                AssumeRolePolicyDocument=json.dumps(trust_policy),
                Description=f'Lambda execution role for CodeDeploy hooks - {self.environment}'
            )
            
            # Attach inline policy
            self.iam_client.put_role_policy(
                RoleName=role_name,
                PolicyName=f'LambdaCodeDeployHooksPolicy-{self.environment}',
                PolicyDocument=json.dumps(policy_document)
            )
            print(f"✓ IAM role '{role_name}' created successfully")
            
            # Wait for role to propagate
            print("⏳ Waiting for IAM role to propagate...")
            time.sleep(10)
        
        # Get role ARN
        role_response = self.iam_client.get_role(RoleName=role_name)
        return role_response['Role']['Arn']
    
    def create_zip_file(self, python_file):
        """Create a zip file for the Lambda function"""
        zip_path = self.script_dir / f"{python_file.stem}.zip"
        
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            zipf.write(python_file, python_file.name)
        
        print(f"✓ Created zip file: {zip_path}")
        return zip_path
    
    def create_lambda_function(self, func_config, role_arn):
        """Create a single Lambda function"""
        function_name = f"codedeploy-hook-{func_config['name']}-{self.environment}"
        python_file = self.script_dir / func_config['file']
        
        # Check if Python file exists
        if not python_file.exists():
            print(f"⚠️  Warning: {python_file} not found, skipping...")
            return None
        
        # Create zip file
        zip_path = self.create_zip_file(python_file)
        
        try:
            # Check if function already exists
            self.lambda_client.get_function(FunctionName=function_name)
            print(f"⚠️  Lambda function '{function_name}' already exists, updating...")
            
            # Update function code
            with open(zip_path, 'rb') as zip_file:
                self.lambda_client.update_function_code(
                    FunctionName=function_name,
                    ZipFile=zip_file.read()
                )
            print(f"✓ Updated Lambda function '{function_name}'")
            
        except self.lambda_client.exceptions.ResourceNotFoundException:
            # Create new function
            print(f"Creating Lambda function '{function_name}'...")
            
            with open(zip_path, 'rb') as zip_file:
                response = self.lambda_client.create_function(
                    FunctionName=function_name,
                    Runtime=LAMBDA_RUNTIME,
                    Role=role_arn,
                    Handler=f"{func_config['name']}.lambda_handler",
                    Code={'ZipFile': zip_file.read()},
                    Description=func_config['description'],
                    Timeout=LAMBDA_TIMEOUT,
                    MemorySize=LAMBDA_MEMORY,
                    Tags={
                        'Environment': self.environment,
                        'Project': 'weather-dashboard',
                        'Purpose': 'codedeploy-hook'
                    }
                )
            print(f"✓ Created Lambda function '{function_name}'")
        
        # Clean up zip file
        zip_path.unlink()
        return function_name
    
    def create_all_functions(self):
        """Create all Lambda functions"""
        print(f"🚀 Creating Lambda hooks for environment: {self.environment}")
        print(f"📍 Region: {AWS_REGION}")
        print("-" * 50)
        
        # Create IAM role
        role_arn = self.create_execution_role()
        print(f"✓ Using IAM role: {role_arn}")
        print()
        
        # Create Lambda functions
        created_functions = []
        for func_config in LAMBDA_FUNCTIONS:
            function_name = self.create_lambda_function(func_config, role_arn)
            if function_name:
                created_functions.append(function_name)
        
        print()
        print("🎉 Deployment Summary:")
        print("-" * 30)
        print(f"Environment: {self.environment}")
        print(f"Region: {AWS_REGION}")
        print(f"Created functions: {len(created_functions)}")
        for func_name in created_functions:
            print(f"  • {func_name}")
        
        return created_functions

def main():
    """Main function"""
    environment = 'dev'
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        environment = sys.argv[1]
    
    print(f"AWS Lambda Hook Functions Creator")
    print(f"Environment: {environment}")
    print("=" * 50)
    
    try:
        creator = LambdaHooksCreator(environment)
        created_functions = creator.create_all_functions()
        
        if created_functions:
            print("\n✅ All Lambda functions created successfully!")
        else:
            print("\n❌ No Lambda functions were created.")
            sys.exit(1)
            
    except Exception as e:
        print(f"\n❌ Error creating Lambda functions: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
