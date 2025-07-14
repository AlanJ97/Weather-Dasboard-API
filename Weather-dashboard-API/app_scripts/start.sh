#!/bin/bash
# Quick Start Script for Weather Dashboard API (Bash)

# Default to "docker" if no argument is provided, as it's the most robust method
MODE=${1:-"docker"}

echo "🌤️  Weather Dashboard API - Quick Start (Bash)"

# Function to activate virtual environment
activate_venv() {
    if [ -f "venv/bin/activate" ]; then
        source "venv/bin/activate"
    elif [ -f "venv/Scripts/activate" ]; then
        source "venv/Scripts/activate"
    else
        echo "❌ Could not find virtual environment activation script in $(pwd)"
        exit 1
    fi
}

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Go to project root (one level up from app_scripts)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit

case "$MODE" in
    api)
        echo "🚀 Starting API only..."
        cd "app/api" || exit
        activate_venv
        echo "📡 Starting FastAPI server on http://localhost:8000"
        python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
        ;;
    frontend)
        echo "🎨 Starting Frontend only..."
        cd "app/frontend" || exit
        activate_venv
        echo "🌐 Starting Streamlit on http://localhost:8501"
        python -m streamlit run main.py --server.port 8501 --server.address 0.0.0.0
        ;;
    docker)
        echo "🐳 Starting with Docker Compose..."
        echo "📡 API will be available at: http://localhost:8000"
        echo "🎨 Frontend will be available at: http://localhost:8501"
        docker-compose up --build
        ;;
    test)
        echo "🧪 Running application tests..."
        echo "⚠️  Make sure both applications are running first (e.g., in 'docker' mode)!"
        # Use the frontend virtual environment since it has requests installed
        cd "app/frontend" || exit
        activate_venv
        cd "$PROJECT_ROOT" || exit
        python app_scripts/test_applications.py
        ;;
    *)
        echo "❌ Invalid mode: $MODE"
        echo "Usage: $0 {api|frontend|docker|test}"
        exit 1
        ;;
esac
