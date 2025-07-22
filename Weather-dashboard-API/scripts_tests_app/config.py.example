"""
Configuration for application test scripts
Copy this file to config.py and update with your values
DO NOT commit config.py to version control
"""
import os

# Default configuration - REPLACE WITH YOUR VALUES
DEFAULT_CONFIG = {
    'api_host': 'localhost',
    'api_port': 8000,
    'frontend_host': 'localhost',
    'frontend_port': 8501,
    'project_name': 'weather-dashboard',
    'environment': 'dev'
}

def get_config():
    """
    Get configuration from environment variables with fallback to defaults
    """
    return {
        'api_host': os.getenv('API_HOST', DEFAULT_CONFIG['api_host']),
        'api_port': int(os.getenv('API_PORT', DEFAULT_CONFIG['api_port'])),
        'frontend_host': os.getenv('FRONTEND_HOST', DEFAULT_CONFIG['frontend_host']),
        'frontend_port': int(os.getenv('FRONTEND_PORT', DEFAULT_CONFIG['frontend_port'])),
        'project_name': os.getenv('PROJECT_NAME', DEFAULT_CONFIG['project_name']),
        'environment': os.getenv('ENVIRONMENT', DEFAULT_CONFIG['environment'])
    }

def get_api_base_url(config: dict = None) -> str:
    """Generate API base URL from configuration."""
    if config is None:
        config = get_config()
    return f"http://{config['api_host']}:{config['api_port']}"

def get_frontend_url(config: dict = None) -> str:
    """Generate frontend URL from configuration."""
    if config is None:
        config = get_config()
    return f"http://{config['frontend_host']}:{config['frontend_port']}"

def get_docker_image_names(config: dict = None) -> dict:
    """Generate Docker image names from configuration."""
    if config is None:
        config = get_config()
    
    project_name = config['project_name']
    environment = config['environment']
    
    return {
        'api': f"{project_name}-api:{environment}",
        'frontend': f"{project_name}-frontend:{environment}"
    }
