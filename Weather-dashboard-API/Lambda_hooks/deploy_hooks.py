#!/usr/bin/env python3
"""
Easy deployment wrapper for Lambda hooks
Handles environment setup and provides user-friendly interface
"""

import os
import sys
import subprocess
from pathlib import Path

def show_usage():
    """Display usage information"""
    print("🚀 Lambda Hooks Deployment Tool")
    print("=" * 50)
    print("Usage:")
    print("  python deploy_hooks.py <action> <environment> [options]")
    print()
    print("Actions:")
    print("  create    - Create Lambda functions")
    print("  destroy   - Delete Lambda functions") 
    print("  list      - List existing functions")
    print()
    print("Environments:")
    print("  dev       - Development environment")
    print("  staging   - Staging environment")
    print("  prod      - Production environment")
    print()
    print("Options:")
    print("  --region=<region>    - AWS region (default: us-east-2)")
    print("  --profile=<profile>  - AWS profile (default: default)")
    print()
    print("Examples:")
    print("  python deploy_hooks.py create dev")
    print("  python deploy_hooks.py create prod --region=us-west-2")
    print("  python deploy_hooks.py destroy staging")
    print("  python deploy_hooks.py list dev")

def parse_args():
    """Parse command line arguments"""
    if len(sys.argv) < 3:
        return None, None, {}
    
    action = sys.argv[1]
    environment = sys.argv[2]
    options = {}
    
    # Parse options
    for arg in sys.argv[3:]:
        if arg.startswith('--region='):
            options['region'] = arg.split('=', 1)[1]
        elif arg.startswith('--profile='):
            options['profile'] = arg.split('=', 1)[1]
    
    return action, environment, options

def set_environment_vars(options):
    """Set environment variables from options"""
    if 'region' in options:
        os.environ['AWS_REGION'] = options['region']
    
    if 'profile' in options:
        os.environ['AWS_PROFILE'] = options['profile']
    
    # Set default region if not specified
    if 'AWS_REGION' not in os.environ:
        os.environ['AWS_REGION'] = 'us-east-2'

def run_script(script_name, environment):
    """Run the specified script with environment"""
    script_path = Path(__file__).parent / script_name
    
    if not script_path.exists():
        print(f"❌ Script not found: {script_path}")
        return False
    
    try:
        result = subprocess.run([
            sys.executable, str(script_path), environment
        ], check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Script failed with exit code: {e.returncode}")
        return False

def list_functions(environment, region):
    """List existing Lambda functions for the environment"""
    import boto3
    
    try:
        lambda_client = boto3.client('lambda', region_name=region)
        
        print(f"🔍 Listing Lambda functions for environment: {environment}")
        print(f"📍 Region: {region}")
        print("-" * 50)
        
        # List functions with our naming pattern
        functions = lambda_client.list_functions()
        hook_functions = [
            f for f in functions['Functions'] 
            if f['FunctionName'].startswith(f'codedeploy-hook-') and 
               f['FunctionName'].endswith(f'-{environment}')
        ]
        
        if hook_functions:
            print(f"📦 Found {len(hook_functions)} Lambda hook functions:")
            for func in hook_functions:
                print(f"  ✅ {func['FunctionName']}")
                print(f"     Runtime: {func['Runtime']}")
                print(f"     Last Modified: {func['LastModified']}")
                print()
        else:
            print(f"❌ No Lambda hook functions found for environment: {environment}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error listing functions: {str(e)}")
        return False

def main():
    """Main function"""
    action, environment, options = parse_args()
    
    if not action or not environment:
        show_usage()
        sys.exit(1)
    
    # Validate action
    valid_actions = ['create', 'destroy', 'list']
    if action not in valid_actions:
        print(f"❌ Invalid action: {action}")
        print(f"Valid actions: {', '.join(valid_actions)}")
        sys.exit(1)
    
    # Validate environment
    valid_environments = ['dev', 'staging', 'prod']
    if environment not in valid_environments:
        print(f"❌ Invalid environment: {environment}")
        print(f"Valid environments: {', '.join(valid_environments)}")
        sys.exit(1)
    
    # Set environment variables
    set_environment_vars(options)
    region = os.environ.get('AWS_REGION', 'us-east-2')
    
    print(f"🎯 Action: {action}")
    print(f"🌍 Environment: {environment}")
    print(f"📍 Region: {region}")
    print()
    
    # Execute action
    if action == 'create':
        success = run_script('create_lambda_hooks.py', environment)
    elif action == 'destroy':
        success = run_script('destroy_lambda_hooks.py', environment)
    elif action == 'list':
        success = list_functions(environment, region)
    
    if success:
        print(f"\n✅ Action '{action}' completed successfully!")
    else:
        print(f"\n❌ Action '{action}' failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
