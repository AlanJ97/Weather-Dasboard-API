"""
Configuration for Terraform backend Python scripts
Copy this file to config.py and update with your values
DO NOT commit config.py to version control
"""
import os
from datetime import datetime

# Default configuration - REPLACE WITH YOUR VALUES
DEFAULT_CONFIG = {
    'aws_region': 'us-east-2',  # e.g., 'us-east-2'
    'project_name': 'dashboard-weather-app',  # e.g., 'weather-app'
    'location_suffix': 'ohio'  # e.g., 'ohio', 'virginia'
}

def get_config():
    """
    Get configuration from environment variables with fallback to defaults
    """
    return {
        'aws_region': os.getenv('AWS_REGION', DEFAULT_CONFIG['aws_region']),
        'project_name': os.getenv('PROJECT_NAME', DEFAULT_CONFIG['project_name']),
        'location_suffix': os.getenv('LOCATION_SUFFIX', DEFAULT_CONFIG['location_suffix'])
    }

def get_terraform_backend_bucket(config: dict = None) -> str:
    """Generate Terraform backend bucket name."""
    if config is None:
        config = get_config()
    
    current_year = datetime.now().year
    project_name = config['project_name']
    location_suffix = config['location_suffix']
    
    return f"{project_name}-backend-terraform-bucket-{current_year}-{location_suffix}"
