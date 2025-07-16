#!/bin/bash
# Development Setup Script for Weather Dashboard API

echo "🌤️  Setting up Weather Dashboard API Development Environment"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command_exists python; then
    echo "❌ Python is not installed or not in PATH"
    exit 1
fi

if ! command_exists docker; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Get the directory of the script itself to determine the project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Navigate to the project root (one level up from app_scripts)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit

echo "📂 Running from project root: $(pwd)"

# Setup API environment
echo "🔧 Setting up API environment..."
cd app/api

# Remove existing virtual environment if it exists
if [ -d "venv" ]; then
    echo "🗑️  Removing existing virtual environment..."
    rm -rf venv
fi

# Create new virtual environment
echo "📦 Creating virtual environment..."
python -m venv venv

# Activate virtual environment (Linux/Mac)
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
# Activate virtual environment (Windows with Git Bash)
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
# Windows PowerShell
elif [ -f "venv/Scripts/Activate.ps1" ]; then
    ./venv/Scripts/Activate.ps1
else
    echo "❌ Could not find virtual environment activation script"
    exit 1
fi

echo "📥 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "🧪 Testing API..."
python -c "
import uvicorn
from main import app
print('✅ FastAPI app loaded successfully')
print('📡 Testing basic import...')
try:
    from fastapi import FastAPI
    from pydantic import BaseModel
    print('✅ All imports successful')
except ImportError as e:
    print(f'❌ Import error: {e}')
    exit(1)
"

# Go back to root directory
cd ../..

# Setup Frontend environment
echo "🎨 Setting up Frontend environment..."
cd app/frontend

# Remove existing virtual environment if it exists
if [ -d "venv" ]; then
    echo "🗑️  Removing existing virtual environment..."
    rm -rf venv
fi

# Create new virtual environment
echo "📦 Creating virtual environment..."
python -m venv venv

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
elif [ -f "venv/Scripts/Activate.ps1" ]; then
    ./venv/Scripts/Activate.ps1
fi

echo "📥 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "🧪 Testing Frontend..."
python -c "
try:
    import streamlit
    import requests
    import pandas as pd
    import plotly.express as px
    print('✅ All frontend imports successful')
except ImportError as e:
    print(f'❌ Import error: {e}')
    exit(1)
"

# Go back to root
cd ../..

echo "🐳 Building Docker images..."

# Build API Docker image
echo "🔨 Building API Docker image..."
cd app/api
docker build -t weather-api:latest . || {
    echo "❌ Failed to build API Docker image"
    exit 1
}
cd ../..

# Build Frontend Docker image
echo "🔨 Building Frontend Docker image..."
cd app/frontend || exit
docker build -t weather-frontend:latest . || {
    echo "❌ Failed to build Frontend Docker image"
    exit 1
}
cd ../..

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Start the API: cd app/api && source venv/bin/activate && uvicorn main:app --host 0.0.0.0 --port 8000"
echo "   2. Start the Frontend: cd app/frontend && source venv/bin/activate && streamlit run main.py --server.port 8501"
echo "   3. Or use Docker: docker run -p 8000:8000 weather-api:latest"
echo "   4. And: docker run -p 8501:8501 weather-frontend:latest"
echo ""
echo "🌐 URLs:"
echo "   - API: http://localhost:8000"
echo "   - API Docs: http://localhost:8000/docs"
echo "   - Frontend: http://localhost:8501"
echo ""
