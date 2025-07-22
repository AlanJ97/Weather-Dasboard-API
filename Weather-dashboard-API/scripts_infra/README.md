# Infrastructure Scripts Configuration

## Overview
This directory contains scripts for managing AWS S3 buckets for CI/CD pipeline artifacts and CodeBuild caching. All previously hardcoded values have been moved to a centralized configuration system.

## First-Time Setup

### 1. Copy Configuration Templates
```bash
# Copy shell script config
cp config.sh.example config.sh

# Copy Python script config  
cp config.py.example config.py
```

### 2. Configure Your Values
Edit both config files with your specific values:

**`config.sh`**:
```bash
DEFAULT_AWS_REGION="us-east-2"           # Your AWS region
DEFAULT_PROJECT_NAME="weather-dashboard" # Your project name
DEFAULT_ORGANIZATION="your-company"      # Your organization
DEFAULT_COST_CENTER="Engineering"       # Your cost center
DEFAULT_TEAM_NAME="DevOps-Team"         # Your team name
```

**`config.py`**:
```python
DEFAULT_CONFIG = {
    'aws_region': 'us-east-2',
    'project_name': 'weather-dashboard',
    'organization': 'your-company',
    'cost_center': 'Engineering',
    'team_name': 'DevOps-Team'
}
```

## Environment Variables (Recommended)
Override configuration using environment variables:

```bash
export AWS_REGION="your-aws-region"
export PROJECT_NAME="your-project-name"
export ORGANIZATION="your-organization"
export COST_CENTER="your-cost-center"
export TEAM_NAME="your-team-name"
```

## Scripts

### 1. `CreateS3BucketsCodePipeline.sh`
**Purpose**: Creates S3 buckets for pipeline artifacts and CodeBuild cache

**Security Improvements**:
- ✅ No hardcoded AWS regions
- ✅ Configurable project names and metadata
- ✅ Dynamic bucket naming with current year
- ✅ Environment-specific tagging

**Usage**:
```bash
./CreateS3BucketsCodePipeline.sh dev
./CreateS3BucketsCodePipeline.sh staging
./CreateS3BucketsCodePipeline.sh prod
```

### 2. `destroy_s3_buckets_CodePipeline.py`
**Purpose**: Completely removes S3 buckets including all versions and content

**Security Improvements**:
- ✅ No hardcoded AWS regions
- ✅ Configurable bucket naming patterns
- ✅ Configuration-driven operation
- ✅ Dynamic year-based naming

**Usage**:
```bash
python destroy_s3_buckets_CodePipeline.py dev
python destroy_s3_buckets_CodePipeline.py staging
python destroy_s3_buckets_CodePipeline.py prod
```

## Generated Resources

With environment `dev` and default configuration, creates:
- **Pipeline Bucket**: `dev-weather-dashboard-pipeline-artifacts-2025`
- **CodeBuild Bucket**: `dev-weather-dashboard-codebuild-cache-2025`

## Security Features

### Configuration Management
- ✅ **Template-based configuration** (`.example` files)
- ✅ **Local config files excluded** from version control
- ✅ **Environment variable support** for CI/CD
- ✅ **No sensitive data in repository**

### Bucket Security
- ✅ **Versioning enabled** on all buckets
- ✅ **Default encryption (AES256)** applied
- ✅ **Public access blocked** completely
- ✅ **Comprehensive tagging** for governance

### Dynamic Features
- ✅ **Year-based naming** (automatically uses current year)
- ✅ **Environment-specific** bucket names
- ✅ **Configurable project metadata**
- ✅ **Organization-specific tagging**

## Troubleshooting

### Config File Missing
```
❌ Config file not found. Please copy config.sh.example to config.sh and configure it.
```
**Solution**: Copy and configure the template files as shown in setup section.

### AWS Credentials
```
❌ AWS credentials not found. Please configure your credentials.
```
**Solution**: Configure AWS CLI with `aws configure` or set environment variables.

### Bucket Already Exists
The scripts handle existing buckets gracefully and will update configurations as needed.

## Migration Notes
- Configuration files (`config.sh`, `config.py`) are in `.gitignore`
- Template files are safe for version control
- Environment variables take precedence over local configuration
- Bucket names now include current year automatically
- All organizational metadata is configurable
