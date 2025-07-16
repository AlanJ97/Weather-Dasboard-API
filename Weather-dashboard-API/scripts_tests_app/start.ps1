# Quick Start Script for Weather Dashboard API (PowerShell)

param(
    [Parameter(Position=0)]
    [ValidateSet("api", "frontend", "both", "docker", "test")]
    [string]$Mode = "both"
)

Write-Host "🌤️  Weather Dashboard API - Quick Start" -ForegroundColor Cyan

switch ($Mode) {
    "api" {
        Write-Host "🚀 Starting API only..." -ForegroundColor Yellow
        Set-Location "app/api"
        & ".\venv\Scripts\Activate.ps1"
        Write-Host "📡 Starting FastAPI server on http://localhost:8000" -ForegroundColor Green
        uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    }
    
    "frontend" {
        Write-Host "🎨 Starting Frontend only..." -ForegroundColor Yellow
        Set-Location "app/frontend"
        & ".\venv\Scripts\Activate.ps1"
        Write-Host "🌐 Starting Streamlit on http://localhost:8501" -ForegroundColor Green
        streamlit run main.py --server.port 8501 --server.address 0.0.0.0
    }
    
    "both" {
        Write-Host "🔄 Starting both applications..." -ForegroundColor Yellow
        Write-Host "⚠️  Note: This will start both in the same terminal. Use 'docker' mode for better separation." -ForegroundColor Yellow
        
        # Start API in background
        Write-Host "📡 Starting API..." -ForegroundColor Green
        Start-Process powershell -ArgumentList "-Command", "cd 'app/api'; .\venv\Scripts\Activate.ps1; uvicorn main:app --host 0.0.0.0 --port 8000"
        
        Start-Sleep -Seconds 3
        
        # Start Frontend
        Write-Host "🎨 Starting Frontend..." -ForegroundColor Green
        Set-Location "app/frontend"
        & ".\venv\Scripts\Activate.ps1"
        streamlit run main.py --server.port 8501 --server.address 0.0.0.0
    }
    
    "docker" {
        Write-Host "🐳 Starting with Docker Compose..." -ForegroundColor Yellow
        Write-Host "📡 API will be available at: http://localhost:8000" -ForegroundColor Green
        Write-Host "🎨 Frontend will be available at: http://localhost:8501" -ForegroundColor Green
        docker-compose up --build
    }
    
    "test" {
        Write-Host "🧪 Running application tests..." -ForegroundColor Yellow
        Write-Host "⚠️  Make sure both applications are running first!" -ForegroundColor Yellow
        python test_applications.py
    }
}

Write-Host ""
Write-Host "🌐 Quick Access URLs:" -ForegroundColor Cyan
Write-Host "   - API: http://localhost:8000" -ForegroundColor White
Write-Host "   - API Docs: http://localhost:8000/docs" -ForegroundColor White
Write-Host "   - Frontend: http://localhost:8501" -ForegroundColor White
