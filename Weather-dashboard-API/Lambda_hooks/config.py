"""
Configuration file for Lambda hooks deployment
Environment-specific settings that can be overridden
"""
import os

# Default configuration - can be overridden by environment variables
DEFAULT_CONFIG = {
    'aws_region': 'us-east-2',
    'lambda_runtime': 'python3.11',
    'lambda_timeout': 60,
    'lambda_memory': 128
}

def get_config():
    """
    Get configuration from environment variables with fallback to defaults
    """
    return {
        'aws_region': os.getenv('AWS_REGION', DEFAULT_CONFIG['aws_region']),
        'lambda_runtime': os.getenv('LAMBDA_RUNTIME', DEFAULT_CONFIG['lambda_runtime']),
        'lambda_timeout': int(os.getenv('LAMBDA_TIMEOUT', DEFAULT_CONFIG['lambda_timeout'])),
        'lambda_memory': int(os.getenv('LAMBDA_MEMORY', DEFAULT_CONFIG['lambda_memory']))
    }

# Lambda function configurations
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
