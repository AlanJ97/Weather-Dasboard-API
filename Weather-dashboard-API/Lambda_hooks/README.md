# Lambda Hooks Configuration

## Overview
This directory contains CodeDeploy Lambda hooks with configurable deployment settings. All sensitive configuration has been moved to local files that are excluded from version control.

## First-Time Setup

1. **Copy the configuration template**:
   ```bash
   cp config.py.example config.py
   ```

2. **Edit `config.py`** with your specific values:
   ```python
   DEFAULT_CONFIG = {
       'aws_region': 'us-east-2',  # Your AWS region
       'lambda_runtime': 'python3.11',
       'lambda_timeout': 60,
       'lambda_memory': 128
   }
   ```

## Environment Variables (Recommended)
You can override configuration using environment variables:

```bash
export AWS_REGION="your-aws-region"
export LAMBDA_RUNTIME="python3.11"
export LAMBDA_TIMEOUT="60"
export LAMBDA_MEMORY="128"
```

## Configuration Files

### `config.py.example`
- **Purpose**: Template file safe for version control
- **Contains**: Placeholder values only
- **Security**: No sensitive information

### `config.py` (Local only)
- **Purpose**: Your actual configuration with real values
- **Contains**: Your AWS region and Lambda settings
- **Security**: Excluded from version control via `.gitignore`

## Security
✅ **No hardcoded AWS regions in version control**  
✅ **Template-based configuration system**  
✅ **Local configuration files excluded from Git**  
✅ **Environment variable support for CI/CD**
