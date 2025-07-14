# Development Setup Script for Weather Dashboard API (PowerShell)
Write-Host "Weather Dashboard API - Development Environment Setup" -ForegroundColor Cyan

# Function to check if command exists
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

if (-not (Test-Command python)) {
    Write-Host "ERROR: Python is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

if (-not (Test-Command docker)) {
    Write-Host "WARNING: Docker is not installed or not in PATH" -ForegroundColor Yellow
}

Write-Host "Prerequisites check passed" -ForegroundColor Green

# Setup API environment
Write-Host "Setting up API environment..." -ForegroundColor Yellow
Set-Location "app\api"

# Remove existing virtual environment if it exists
if (Test-Path "venv") {
    Write-Host "Removing existing virtual environment..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "venv"
}

# Create new virtual environment
Write-Host "Creating virtual environment..." -ForegroundColor Yellow
python -m venv venv

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

Write-Host "Testing API imports..." -ForegroundColor Yellow
python -c "import fastapi, pydantic, uvicorn; print('API dependencies OK')"

# Deactivate virtual environment
deactivate

# Go back to root directory
Set-Location "..\..\"

# Setup Frontend environment
Write-Host "Setting up Frontend environment..." -ForegroundColor Yellow
Set-Location "app\frontend"

# Remove existing virtual environment if it exists
if (Test-Path "venv") {
    Write-Host "Removing existing virtual environment..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "venv"
}

# Create new virtual environment
Write-Host "Creating virtual environment..." -ForegroundColor Yellow
python -m venv venv

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

Write-Host "Testing Frontend imports..." -ForegroundColor Yellow
python -c "import streamlit, requests, pandas, plotly; print('Frontend dependencies OK')"

# Deactivate virtual environment
deactivate

# Go back to root
Set-Location "..\..\"

Write-Host "Building Docker images..." -ForegroundColor Yellow

# Build API Docker image
Write-Host "Building API Docker image..." -ForegroundColor Yellow
Set-Location "app\api"
docker build -t weather-api:latest .
Set-Location "..\..\"

# Build Frontend Docker image
Write-Host "Building Frontend Docker image..." -ForegroundColor Yellow
Set-Location "app\frontend"
docker build -t weather-frontend:latest .
Set-Location "..\..\"

Write-Host ""
Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "   1. Start API: .\start.ps1 api" -ForegroundColor White
Write-Host "   2. Start Frontend: .\start.ps1 frontend" -ForegroundColor White
Write-Host "   3. Start Both: .\start.ps1 both" -ForegroundColor White
Write-Host "   4. Use Docker: .\start.ps1 docker" -ForegroundColor White
Write-Host ""
Write-Host "URLs:" -ForegroundColor Cyan
Write-Host "   - API: http://localhost:8000" -ForegroundColor White
Write-Host "   - API Docs: http://localhost:8000/docs" -ForegroundColor White
Write-Host "   - Frontend: http://localhost:8501" -ForegroundColor White
Write-Host ""
