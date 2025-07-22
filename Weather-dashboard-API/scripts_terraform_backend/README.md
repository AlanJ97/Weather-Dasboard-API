# Terraform Backend Scripts Configuration

## Overview
This directory contains scripts for managing the Terraform backend S3 bucket with Object Lock enabled. All previously hardcoded values have been moved to a centralized configuration system.

## ⚠️ CRITICAL SECURITY NOTE
These scripts manage your **Terraform state bucket** - the most critical component of your infrastructure. The backend bucket contains all your infrastructure state files and should be handled with extreme care.

## First-Time Setup

### 1. Copy Configuration Template
```bash
cp config.sh.example config.sh
cp config.py.example config.py
```

### 2. Configure Your Values
Edit both config files with your specific values:

**`config.sh`**:
```bash
DEFAULT_AWS_REGION="us-east-2"          # Your AWS region
DEFAULT_PROJECT_NAME="weather-app"      # Your project name (no spaces)
DEFAULT_LOCATION_SUFFIX="ohio"          # Your location/datacenter identifier
```

**`config.py`**:
```python
DEFAULT_CONFIG = {
    'aws_region': 'us-east-2',
    'project_name': 'weather-app',
    'location_suffix': 'ohio'
}
```

## Environment Variables (Recommended)
Override configuration using environment variables:

```bash
export AWS_REGION="your-aws-region"
export PROJECT_NAME="your-project-name"
export LOCATION_SUFFIX="your-location"
```

## Scripts

### 1. `setup_terraform_backend.sh`
**Purpose**: Creates S3 bucket for Terraform state with Object Lock enabled

**Security Improvements**:
- ✅ No hardcoded AWS regions
- ✅ No hardcoded bucket names
- ✅ Configurable project naming
- ✅ Dynamic year-based naming
- ✅ Object Lock with governance mode (1-day retention)

**Features**:
- Automatically handles bucket recreation if exists
- Enables versioning (required for Object Lock)
- Configures default Object Lock retention
- Supports all AWS regions correctly

**Usage**:
```bash
./setup_terraform_backend.sh
```

### 2. `destroy_terraform_backend.py`
**Purpose**: ⚠️ **DESTRUCTIVE** - Completely removes Terraform backend bucket and ALL state files

**Security Improvements**:
- ✅ No hardcoded AWS regions
- ✅ No hardcoded bucket names
- ✅ Configuration-driven operation
- ✅ Enhanced confirmation process
- ✅ Object Lock bypass capabilities

**Critical Safety Features**:
- Multiple confirmation prompts
- Object Lock governance bypass
- State file detection and warnings
- Comprehensive cleanup (versions, markers, uploads)
- Detailed progress reporting

**Usage**:
```bash
python destroy_terraform_backend.py
```
**WARNING**: This script requires typing `DELETE_BACKEND` to confirm deletion!

## Generated Resources

With default configuration, creates:
- **Bucket Name**: `weather-app-backend-terraform-bucket-2025-ohio`
- **Region**: `us-east-2`
- **Object Lock**: Enabled with 1-day governance retention
- **Versioning**: Enabled
- **Encryption**: AWS managed (S3 default)

## Security Features

### Configuration Management
- ✅ **Template-based configuration** (`.example` files)
- ✅ **Local config files excluded** from version control
- ✅ **Environment variable support** for CI/CD
- ✅ **No sensitive data in repository**
- ✅ **Dynamic bucket naming** with current year

### Bucket Security
- ✅ **Object Lock enabled** (prevents accidental deletion)
- ✅ **Versioning enabled** (state file history)
- ✅ **Governance retention** (1-day minimum retention)
- ✅ **Region-specific creation** (proper location constraints)

### Operational Safety
- ✅ **Confirmation prompts** for destructive operations
- ✅ **State file detection** and warnings
- ✅ **Object Lock bypass** for emergency cleanup
- ✅ **Comprehensive error handling**

## Object Lock Protection

The backend bucket uses **Object Lock in governance mode** with 1-day retention:
- **Protection**: Prevents accidental deletion of state files
- **Flexibility**: Can be bypassed with proper permissions (`s3:BypassGovernanceRetention`)
- **Safety**: State files are protected for minimum 1 day
- **Recovery**: Allows emergency cleanup when needed

## Troubleshooting

### Config File Missing
```
❌ Config file not found. Please copy config.sh.example to config.sh and configure it.
```
**Solution**: Copy and configure the template files as shown in setup section.

### Object Lock Issues
```
❌ Failed to delete bucket: Access denied due to Object Lock
```
**Solution**: 
1. Wait for retention period to expire (1 day)
2. Use governance bypass if you have permissions
3. The script automatically attempts governance bypass

### AWS Credentials
```
❌ AWS credentials not found. Please configure your credentials.
```
**Solution**: Configure AWS CLI with `aws configure` or set environment variables.

### Region Configuration
The script automatically handles region-specific bucket creation:
- `us-east-1`: No location constraint needed
- All other regions: Requires `LocationConstraint` parameter

## Best Practices

### For Production
1. **Backup State**: Always backup `.tfstate` files before destruction
2. **Team Coordination**: Ensure no one is running Terraform during backend changes
3. **Access Control**: Limit who can run the destroy script
4. **Monitoring**: Set up CloudTrail logging for bucket operations

### For Development
1. **Use Environment Variables**: Override config for different environments
2. **Separate Buckets**: Use different projects/suffixes for dev/staging/prod
3. **Regular Cleanup**: Clean up test backend buckets regularly

## Migration Notes
- Configuration files (`config.sh`, `config.py`) are in `.gitignore`
- Template files are safe for version control
- Environment variables take precedence over local configuration
- Bucket names now include current year automatically
- All project-specific metadata is configurable
- Object Lock configuration is optional but recommended for production
