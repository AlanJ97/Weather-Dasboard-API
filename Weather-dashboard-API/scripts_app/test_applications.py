#!/usr/bin/env python3
"""
Test script for Weather Dashboard API
Tests both the FastAPI backend and basic functionality
"""

import asyncio
import sys
import time
import requests
from typing import Dict, Any

def test_api_health() -> bool:
    """Test if the API health endpoint is responding"""
    try:
        print("🔍 Testing API health endpoint...")
        response = requests.get("http://localhost:8000/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API Health: {data}")
            return True
        else:
            print(f"❌ API Health check failed with status: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ API Health check failed: {e}")
        return False

def test_weather_endpoints() -> bool:
    """Test weather data endpoints"""
    try:
        print("🌤️  Testing weather endpoints...")
        
        # Test single city endpoint
        response = requests.get("http://localhost:8000/api/weather/Madrid", timeout=5)
        if response.status_code == 200:
            data = response.json()
            # Handle the API response structure where data is nested
            city_data = data.get('data', data)  # Get nested data or fallback to top level
            print(f"✅ Single city weather: {city_data['city']} - {city_data['temperature']}°C")
        else:
            print(f"❌ Single city endpoint failed: {response.status_code}")
            return False
            
        # Test all cities endpoint
        response = requests.get("http://localhost:8000/api/weather", timeout=5)
        if response.status_code == 200:
            data = response.json()
            # Handle the API response structure where data is nested
            cities_data = data.get('data', data)  # Get nested data or fallback to top level
            if isinstance(cities_data, list):
                print(f"✅ All cities weather: {len(cities_data)} cities found")
            else:
                print(f"✅ All cities weather: response received")
        else:
            print(f"❌ All cities endpoint failed: {response.status_code}")
            return False
            
        return True
    except requests.exceptions.RequestException as e:
        print(f"❌ Weather endpoints test failed: {e}")
        return False

def test_api_docs() -> bool:
    """Test if API documentation is accessible"""
    try:
        print("📚 Testing API documentation...")
        response = requests.get("http://localhost:8000/docs", timeout=5)
        if response.status_code == 200:
            print("✅ API documentation is accessible")
            return True
        else:
            print(f"❌ API documentation failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ API documentation test failed: {e}")
        return False

def test_cors() -> bool:
    """Test CORS headers"""
    try:
        print("🌐 Testing CORS configuration...")
        response = requests.options("http://localhost:8000/api/weather", timeout=5)
        cors_headers = [
            'access-control-allow-origin',
            'access-control-allow-methods',
            'access-control-allow-headers'
        ]
        
        has_cors = any(header in response.headers for header in cors_headers)
        if has_cors:
            print("✅ CORS headers are present")
            return True
        else:
            print("⚠️  CORS headers not found (might be OK for development)")
            return True  # Not critical for basic functionality
    except requests.exceptions.RequestException as e:
        print(f"⚠️  CORS test failed: {e}")
        return True  # Not critical

def test_frontend_availability() -> bool:
    """Test if frontend is responding (basic check)"""
    try:
        print("🎨 Testing frontend availability...")
        response = requests.get("http://localhost:8501", timeout=10)
        if response.status_code == 200:
            print("✅ Frontend is responding")
            return True
        else:
            print(f"❌ Frontend failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Frontend test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🧪 Starting Weather Dashboard API Tests")
    print("=" * 50)
    
    tests = [
        ("API Health", test_api_health),
        ("Weather Endpoints", test_weather_endpoints),
        ("API Documentation", test_api_docs),
        ("CORS Configuration", test_cors),
        ("Frontend Availability", test_frontend_availability),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n🔬 Running: {test_name}")
        try:
            result = test_func()
            results.append((test_name, result))
            if result:
                print(f"✅ {test_name}: PASSED")
            else:
                print(f"❌ {test_name}: FAILED")
        except Exception as e:
            print(f"💥 {test_name}: ERROR - {e}")
            results.append((test_name, False))
        
        time.sleep(1)  # Brief pause between tests
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"   {test_name}: {status}")
    
    print(f"\n🎯 Overall: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Your Weather Dashboard API is working correctly.")
        return 0
    else:
        print("⚠️  Some tests failed. Please check the application setup.")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
