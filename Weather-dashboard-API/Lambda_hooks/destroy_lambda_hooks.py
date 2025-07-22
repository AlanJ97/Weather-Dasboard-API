#!/usr/bin/env python3
"""
Lambda Hook Functions Destroyer for CodeDeploy
Removes the 5 Lambda functions and IAM role created for CodeDeploy hooks in AWS Ohio region.
"""

import boto3
import sys
import time
from pathlib import Path

# Configuration
AWS_REGION = 'us-east-2'  # Ohio region

# Lambda function configurations (same as creation script)
LAMBDA_FUNCTIONS = [
    {
        'name': 'before_install',
        'file': 'before_install.py',
        'description': 'CodeDeploy hook - executed before install phase'
    },
    {
        'name': 'after_install',
        'file': 'after_install.py',
        'description': 'CodeDeploy hook - executed after install phase'
    },
    {
        'name': 'after_allow_test_traffic',
        'file': 'after_allow_test_traffic.py',
        'description': 'CodeDeploy hook - executed after allowing test traffic'
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

class LambdaHooksDestroyer:
    def __init__(self, environment='dev'):
        self.environment = environment
        self.lambda_client = boto3.client('lambda', region_name=AWS_REGION)
        self.iam_client = boto3.client('iam', region_name=AWS_REGION)
        
    def delete_lambda_function(self, func_config):
        """Delete a single Lambda function"""
        function_name = f"codedeploy-hook-{func_config['name']}-{self.environment}"
        
        try:
            # Check if function exists
            self.lambda_client.get_function(FunctionName=function_name)
            
            # Delete the function
            print(f"🗑️  Deleting Lambda function '{function_name}'...")
            self.lambda_client.delete_function(FunctionName=function_name)
            print(f"✅ Successfully deleted Lambda function '{function_name}'")
            return True
            
        except self.lambda_client.exceptions.ResourceNotFoundException:
            print(f"⚠️  Lambda function '{function_name}' not found, skipping...")
            return False
        except Exception as e:
            print(f"❌ Error deleting Lambda function '{function_name}': {str(e)}")
            return False
    
    def delete_iam_role(self):
        """Delete IAM role and its policies"""
        role_name = f'lambda-codedeploy-hooks-role-{self.environment}'
        policy_name = f'LambdaCodeDeployHooksPolicy-{self.environment}'
        
        try:
            # Check if role exists
            self.iam_client.get_role(RoleName=role_name)
            
            print(f"🗑️  Deleting IAM role '{role_name}'...")
            
            # First, delete the inline policy
            try:
                self.iam_client.delete_role_policy(
                    RoleName=role_name,
                    PolicyName=policy_name
                )
                print(f"✅ Deleted inline policy '{policy_name}'")
            except self.iam_client.exceptions.NoSuchEntityException:
                print(f"⚠️  Inline policy '{policy_name}' not found, skipping...")
            
            # List and detach any managed policies
            try:
                attached_policies = self.iam_client.list_attached_role_policies(RoleName=role_name)
                for policy in attached_policies['AttachedPolicies']:
                    print(f"🔗 Detaching managed policy '{policy['PolicyName']}'...")
                    self.iam_client.detach_role_policy(
                        RoleName=role_name,
                        PolicyArn=policy['PolicyArn']
                    )
                    print(f"✅ Detached managed policy '{policy['PolicyName']}'")
            except Exception as e:
                print(f"⚠️  Error detaching managed policies: {str(e)}")
            
            # Wait a moment for policies to detach
            if attached_policies.get('AttachedPolicies'):
                print("⏳ Waiting for policies to detach...")
                time.sleep(3)
            
            # Delete the role
            self.iam_client.delete_role(RoleName=role_name)
            print(f"✅ Successfully deleted IAM role '{role_name}'")
            return True
            
        except self.iam_client.exceptions.NoSuchEntityException:
            print(f"⚠️  IAM role '{role_name}' not found, skipping...")
            return False
        except Exception as e:
            print(f"❌ Error deleting IAM role '{role_name}': {str(e)}")
            return False
    
    def list_existing_resources(self):
        """List existing Lambda functions and IAM role before deletion"""
        print(f"🔍 Checking existing resources for environment: {self.environment}")
        print("-" * 60)
        
        # Check Lambda functions
        existing_functions = []
        for func_config in LAMBDA_FUNCTIONS:
            function_name = f"codedeploy-hook-{func_config['name']}-{self.environment}"
            try:
                self.lambda_client.get_function(FunctionName=function_name)
                existing_functions.append(function_name)
                print(f"📋 Found Lambda function: {function_name}")
            except self.lambda_client.exceptions.ResourceNotFoundException:
                print(f"❌ Lambda function not found: {function_name}")
        
        # Check IAM role
        role_name = f'lambda-codedeploy-hooks-role-{self.environment}'
        role_exists = False
        try:
            self.iam_client.get_role(RoleName=role_name)
            role_exists = True
            print(f"📋 Found IAM role: {role_name}")
        except self.iam_client.exceptions.NoSuchEntityException:
            print(f"❌ IAM role not found: {role_name}")
        
        print()
        return existing_functions, role_exists
    
    def destroy_all_resources(self):
        """Delete all Lambda functions and IAM role"""
        print(f"🚨 AWS Lambda Hook Functions Destroyer")
        print(f"Environment: {self.environment}")
        print(f"📍 Region: {AWS_REGION}")
        print("=" * 60)
        
        # List existing resources
        existing_functions, role_exists = self.list_existing_resources()
        
        if not existing_functions and not role_exists:
            print("✨ No Lambda hook resources found for this environment.")
            return True
        
        # Confirmation prompt
        print(f"⚠️  WARNING: This will permanently delete the following resources:")
        if existing_functions:
            print(f"   📦 Lambda functions ({len(existing_functions)}):")
            for func_name in existing_functions:
                print(f"      • {func_name}")
        if role_exists:
            print(f"   🔐 IAM role: lambda-codedeploy-hooks-role-{self.environment}")
        
        print()
        confirmation = input("Are you sure you want to proceed? Type 'DELETE' to confirm: ")
        
        if confirmation != 'DELETE':
            print("❌ Operation cancelled. No resources were deleted.")
            return False
        
        print()
        print("🧹 Starting cleanup process...")
        print("-" * 40)
        
        # Delete Lambda functions
        deleted_functions = []
        for func_config in LAMBDA_FUNCTIONS:
            if self.delete_lambda_function(func_config):
                deleted_functions.append(f"codedeploy-hook-{func_config['name']}-{self.environment}")
        
        print()
        
        # Delete IAM role (after Lambda functions to avoid dependency issues)
        role_deleted = self.delete_iam_role()
        
        print()
        print("🎯 Cleanup Summary:")
        print("-" * 30)
        print(f"Environment: {self.environment}")
        print(f"Region: {AWS_REGION}")
        print(f"Deleted Lambda functions: {len(deleted_functions)}")
        for func_name in deleted_functions:
            print(f"  ✅ {func_name}")
        
        if role_deleted:
            print(f"  ✅ IAM role: lambda-codedeploy-hooks-role-{self.environment}")
        
        if deleted_functions or role_deleted:
            print("\n🎉 Cleanup completed successfully!")
            return True
        else:
            print("\n⚠️  No resources were deleted.")
            return False

def main():
    """Main function"""
    environment = 'dev'
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        environment = sys.argv[1]
    elif len(sys.argv) == 1:
        print("Usage: python destroy_lambda_hooks.py <environment>")
        print("Example: python destroy_lambda_hooks.py dev")
        print("         python destroy_lambda_hooks.py staging")
        print("         python destroy_lambda_hooks.py prod")
        print()
        environment = input("Enter environment (dev/staging/prod): ").strip()
        if not environment:
            print("❌ Environment is required.")
            sys.exit(1)
    
    try:
        destroyer = LambdaHooksDestroyer(environment)
        success = destroyer.destroy_all_resources()
        
        if success:
            print("\n✅ All Lambda hook resources cleaned up successfully!")
        else:
            print("\n❌ Cleanup process failed or was cancelled.")
            sys.exit(1)
            
    except Exception as e:
        print(f"\n❌ Error during cleanup: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
