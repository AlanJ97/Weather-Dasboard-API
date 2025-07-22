# IAM Permissions Scripts Configuration

## Overview
This directory contains scripts for managing AWS IAM permissions and GitHub OIDC setup. All previously hardcoded values have been moved to a centralized configuration system.

## Configuration
All values are now configurable through environment variables or local configuration files:

### First-Time Setup
1. **Copy the template files**:
   ```bash
   cp config.sh.example config.sh
   ```

2. **Edit `config.sh`** with your specific values:
   ```bash
   # Replace these placeholders with your actual values
   DEFAULT_GITHUB_ORG="your-github-org"
   DEFAULT_REPO_NAME="your-repo-name"
   DEFAULT_AWS_REGION="your-aws-region"
   DEFAULT_BUCKET_NAME="your-terraform-backend-bucket"
   ```

### Environment Variables (Recommended)
Set these before running the scripts to override defaults:

```bash
export GITHUB_ORG="your-github-org"
export REPO_NAME="your-repo-name"
export AWS_REGION="your-aws-region"
export ENVIRONMENT="dev|staging|prod"
export BUCKET_NAME="your-terraform-backend-bucket"
```

### Default Values
Configuration files are not committed to version control for security. Use the `.example` templates:
- **Template Files**: `config.sh.example`, available in respective directories
- **Local Files**: `config.sh` (create from template, add your values)
- **Security**: All local config files are in `.gitignore`

## Scripts

### 1. `config.sh.example` / `config.sh`
Template and local configuration files that:
- **Template**: Safe placeholder values for version control
- **Local**: Contains your actual sensitive configuration (not committed)
- Loads environment variables or local defaults
- Exports configuration for other scripts
- Generates environment-specific resource names

### 2. `cleanup_conflicting_resources.sh`
- **Purpose**: Removes existing AWS resources before Terraform deployment
- **Security**: Now uses environment-configurable resource names
- **Usage**: Automatically loads configuration from `config.sh`

### 3. `setup_aws_oidc.sh`
- **Purpose**: Sets up GitHub OIDC provider and IAM roles
- **Security**: All repository and AWS details now configurable
- **Usage**: Automatically loads configuration from `config.sh`

### 4. `fix_aws_permissions.bat`
- **Purpose**: Windows batch wrapper for the cleanup and setup process
- **Security**: Unchanged (just calls other scripts)

## Usage Examples

### For Development Environment
```bash
# Use defaults (dev environment)
./cleanup_conflicting_resources.sh
./setup_aws_oidc.sh
```

### For Production Environment
```bash
export ENVIRONMENT="prod"
export AWS_REGION="us-west-2"
./cleanup_conflicting_resources.sh
./setup_aws_oidc.sh
```

### For Different Organization/Repository
```bash
export GITHUB_ORG="MyOrg"
export REPO_NAME="MyRepo"
export BUCKET_NAME="my-terraform-backend-bucket"
./setup_aws_oidc.sh
```

## Security Improvements
✅ **Eliminated hardcoded GitHub organization and repository names**
✅ **Eliminated hardcoded AWS regions**
✅ **Eliminated hardcoded S3 bucket names**
✅ **Eliminated hardcoded resource names**
✅ **Added environment-specific resource naming**
✅ **Centralized configuration management**
✅ **Configuration files excluded from version control**
✅ **Template-based configuration system**

## Migration Notes
- Configuration files (`config.sh`, `config.py`) are now in `.gitignore`
- Use template files (`.example`) to create local configuration
- Environment variables take precedence over local configuration
- Resource names are now dynamically generated based on environment
- No breaking changes to script interfaces
