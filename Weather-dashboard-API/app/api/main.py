"""
Weather Dashboard API - FastAPI Backend
A simple weather API for DevOps training purposes.
"""

import os
import logging
from datetime import datetime
from typing import Dict, List, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Weather Dashboard API",
    description="A DevOps training project - Weather API backend",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class WeatherData(BaseModel):
    city: str
    temperature: float
    humidity: int
    description: str
    timestamp: datetime

class WeatherResponse(BaseModel):
    success: bool
    data: Optional[WeatherData] = None
    message: str

# Mock weather data for training purposes
MOCK_WEATHER_DATA = {
    "madrid": {
        "city": "Madrid",
        "temperature": 22.5,
        "humidity": 65,
        "description": "Partly cloudy"
    },
    "barcelona": {
        "city": "Barcelona", 
        "temperature": 25.0,
        "humidity": 70,
        "description": "Sunny"
    },
    "valencia": {
        "city": "Valencia",
        "temperature": 24.2,
        "humidity": 68,
        "description": "Clear sky"
    },
    "sevilla": {
        "city": "Sevilla",
        "temperature": 28.0,
        "humidity": 55,
        "description": "Hot and sunny"
    }
}

@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "message": "Weather Dashboard API",
        "version": "1.0.0",
        "status": "running",
        "environment": os.getenv("ENV", "development")
    }

@app.get("/health")
async def health_check():
    """Health check endpoint for load balancer"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }

@app.get("/api/weather/cities", response_model=List[str])
async def get_available_cities():
    """Get list of available cities"""
    logger.info("Getting available cities")
    return list(MOCK_WEATHER_DATA.keys())

@app.get("/api/weather/{city}", response_model=WeatherResponse)
async def get_weather(city: str):
    """Get weather data for a specific city"""
    logger.info(f"Getting weather data for city: {city}")
    
    city_lower = city.lower()
    
    if city_lower not in MOCK_WEATHER_DATA:
        logger.warning(f"City not found: {city}")
        raise HTTPException(
            status_code=404, 
            detail=f"Weather data not available for city: {city}"
        )
    
    weather_data = MOCK_WEATHER_DATA[city_lower].copy()
    weather_data["timestamp"] = datetime.now()
    
    return WeatherResponse(
        success=True,
        data=WeatherData(**weather_data),
        message=f"Weather data retrieved successfully for {city}"
    )

@app.get("/api/weather")
async def get_all_weather():
    """Get weather data for all cities"""
    logger.info("Getting weather data for all cities")
    
    all_weather = []
    for city_key, weather_info in MOCK_WEATHER_DATA.items():
        weather_data = weather_info.copy()
        weather_data["timestamp"] = datetime.now()
        all_weather.append(WeatherData(**weather_data))
    
    return {
        "success": True,
        "data": all_weather,
        "message": "Weather data retrieved successfully for all cities",
        "count": len(all_weather)
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=port, 
        reload=True,
        log_level="info"
    )
