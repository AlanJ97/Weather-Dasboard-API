import pytest
from fastapi.testclient import TestClient
from app.api.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    # API returns 'healthy' for health status
    # INTENTIONALLY FAIL THIS TEST TO SEE HOW CODEBUILD REPORTS FAILURES
    assert response.json()["status"] == "BROKEN_ON_PURPOSE"

def test_weather_all():
    response = client.get("/api/weather")
    assert response.status_code == 200
    assert "data" in response.json()

def test_weather_city():
    # Test a known city from mock data
    city_name = "Madrid"
    response = client.get(f"/api/weather/{city_name}")
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["success"] is True
    assert json_data["data"]["city"] == city_name
    assert json_data["message"].startswith("Weather data retrieved")
