# Application Test Scripts Configuration

## Overview
This directory contains scripts for setting up, testing, and running the Weather Dashboard API applications in development mode. All previously hardcoded values have been moved to a centralized configuration system.

## First-Time Setup

### 1. Copy Configuration Templates
```bash
# For Unix/Linux/Mac (bash)
cp config.sh.example config.sh

# For Python scripts
cp config.py.example config.py

# For Windows PowerShell
cp config.ps1.example config.ps1
```

### 2. Configure Your Values
Edit the config files with your specific values:

**`config.sh` (Unix/Linux/Mac)**:
```bash
DEFAULT_API_HOST="localhost"          # API host
DEFAULT_API_PORT="8000"              # API port
DEFAULT_FRONTEND_HOST="localhost"     # Frontend host
DEFAULT_FRONTEND_PORT="8501"         # Frontend port
DEFAULT_PROJECT_NAME="weather-dashboard"  # Project name for Docker images
DEFAULT_ENVIRONMENT="dev"            # Environment (dev, staging, prod)
```

**`config.py` (Python)**:
```python
DEFAULT_CONFIG = {
    'api_host': 'localhost',
    'api_port': 8000,
    'frontend_host': 'localhost',
    'frontend_port': 8501,
    'project_name': 'weather-dashboard',
    'environment': 'dev'
}
```

**`config.ps1` (Windows PowerShell)**:
```powershell
$env:API_HOST = "localhost"
$env:API_PORT = "8000"
$env:FRONTEND_HOST = "localhost"
$env:FRONTEND_PORT = "8501"
$env:PROJECT_NAME = "weather-dashboard"
$env:ENVIRONMENT = "dev"
```

## Environment Variables (Recommended)
Override configuration using environment variables:

```bash
export API_HOST="your-api-host"
export API_PORT="8000"
export FRONTEND_HOST="your-frontend-host"
export FRONTEND_PORT="8501"
export PROJECT_NAME="your-project-name"
export ENVIRONMENT="dev"
```

## Scripts

### 1. `setup-dev.sh` / `setup-dev.ps1`
**Purpose**: Sets up development environment with virtual environments and Docker images

**Security Improvements**:
- ✅ No hardcoded Docker image names
- ✅ Configurable project naming
- ✅ Environment-specific image tagging
- ✅ Configuration-driven setup

**Features**:
- Creates Python virtual environments for API and Frontend
- Installs dependencies from requirements.txt
- Tests imports to verify setup
- Builds Docker images with configurable names
- Cross-platform support (Linux/Mac/Windows)

**Usage**:
```bash
# Unix/Linux/Mac
./setup-dev.sh

# Windows
.\setup-dev.ps1
```

### 2. `start.sh` / `start.ps1`
**Purpose**: Quick start script for running applications in different modes

**Security Improvements**:
- ✅ Configuration-driven URLs
- ✅ No hardcoded ports or hosts
- ✅ Flexible deployment options

**Modes**:
- `api` - Start API only
- `frontend` - Start Frontend only
- `both` - Start both applications
- `docker` - Use Docker Compose
- `test` - Run test suite

**Usage**:
```bash
# Unix/Linux/Mac
./start.sh api          # Start API only
./start.sh frontend     # Start Frontend only
./start.sh docker       # Use Docker Compose
./start.sh test         # Run tests

# Windows
.\start.ps1 api
.\start.ps1 frontend
.\start.ps1 docker
.\start.ps1 test
```

### 3. `test_applications.py`
**Purpose**: Comprehensive test suite for API and Frontend functionality

**Security Improvements**:
- ✅ No hardcoded URLs or ports
- ✅ Configuration-driven endpoint testing
- ✅ Environment-specific testing

**Tests Performed**:
- API health endpoint verification
- Weather data endpoints functionality
- API documentation accessibility
- CORS configuration validation
- Frontend availability check

**Usage**:
```bash
python test_applications.py
```

## Generated Resources

With default configuration:
- **API URL**: `http://localhost:8000`
- **Frontend URL**: `http://localhost:8501`
- **API Image**: `weather-dashboard-api:dev`
- **Frontend Image**: `weather-dashboard-frontend:dev`
- **API Documentation**: `http://localhost:8000/docs`

## Security Features

### Configuration Management
- ✅ **Template-based configuration** (`.example` files)
- ✅ **Local config files excluded** from version control
- ✅ **Environment variable support** for CI/CD
- ✅ **No sensitive data in repository**
- ✅ **Cross-platform compatibility**

### Application Security
- ✅ **Configurable endpoints** (no hardcoded URLs)
- ✅ **Environment-specific Docker images**
- ✅ **Flexible host/port configuration**
- ✅ **CORS testing and validation**

### Development Safety
- ✅ **Isolated virtual environments**
- ✅ **Dependency verification**
- ✅ **Comprehensive test coverage**
- ✅ **Error handling and reporting**

## Configuration Examples

### For Local Development
```bash
export API_HOST="localhost"
export FRONTEND_HOST="localhost"
export ENVIRONMENT="dev"
./setup-dev.sh
```

### For Remote Testing
```bash
export API_HOST="test-server.company.com"
export FRONTEND_HOST="test-server.company.com"
export ENVIRONMENT="staging"
python test_applications.py
```

### For Production Build
```bash
export PROJECT_NAME="weather-app"
export ENVIRONMENT="prod"
./setup-dev.sh
```

## Troubleshooting

### Config File Missing
```
⚠️ Config file not found. Using default localhost URLs.
   To customize: cp config.py.example config.py
```
**Solution**: Copy and configure the appropriate template file for your platform.

### Port Conflicts
```
❌ API Health check failed: Connection refused
```
**Solution**: 
1. Check if ports are already in use
2. Update configuration with different ports
3. Restart applications with new configuration

### Docker Build Issues
```
❌ Failed to build API Docker image
```
**Solution**:
1. Ensure Docker is running
2. Check if base images are available
3. Verify Dockerfile exists in app directories

### Import Errors
```
❌ Import error: No module named 'fastapi'
```
**Solution**:
1. Ensure virtual environment is activated
2. Run setup script to install dependencies
3. Check requirements.txt files

## Migration Notes
- Configuration files (`config.sh`, `config.py`, `config.ps1`) are in `.gitignore`
- Template files are safe for version control
- Environment variables take precedence over local configuration
- Docker image names now include environment tags
- All URLs and ports are configurable
- Cross-platform support maintained
