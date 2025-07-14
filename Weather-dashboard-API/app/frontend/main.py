import streamlit as st
import requests
import json
import time
from datetime import datetime
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd

# Configure Streamlit page
st.set_page_config(
    page_title="Weather Dashboard",
    page_icon="🌤️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# API Configuration
API_BASE_URL = "http://localhost:8000"  # Will be updated with ALB URL later

def get_weather_data(city=None):
    """Fetch weather data from the API"""
    try:
        if city:
            response = requests.get(f"{API_BASE_URL}/api/weather/{city}")
        else:
            response = requests.get(f"{API_BASE_URL}/api/weather")
        
        if response.status_code == 200:
            json_response = response.json()
            # Extract the data field from the API response
            if isinstance(json_response, dict) and 'data' in json_response:
                return json_response['data']
            else:
                return json_response
        else:
            st.error(f"Error fetching weather data: {response.status_code}")
            return None
    except requests.exceptions.ConnectionError:
        st.error("Cannot connect to the weather API. Please ensure the backend is running.")
        return None
    except Exception as e:
        st.error(f"Error: {str(e)}")
        return None

def check_api_health():
    """Check if the API is healthy"""
    try:
        response = requests.get(f"{API_BASE_URL}/health")
        return response.status_code == 200
    except:
        return False

def create_temperature_chart(weather_data):
    """Create a temperature chart"""
    if isinstance(weather_data, list):
        cities = [item['city'] for item in weather_data]
        temperatures = [item['temperature'] for item in weather_data]
        
        fig = px.bar(
            x=cities,
            y=temperatures,
            title="Temperature by City",
            labels={'x': 'City', 'y': 'Temperature (°C)'},
            color=temperatures,
            color_continuous_scale='RdYlBu_r'
        )
        fig.update_layout(height=400)
        return fig
    return None

def create_weather_gauge(temperature):
    """Create a temperature gauge"""
    fig = go.Figure(go.Indicator(
        mode = "gauge+number+delta",
        value = temperature,
        domain = {'x': [0, 1], 'y': [0, 1]},
        title = {'text': "Temperature (°C)"},
        delta = {'reference': 20},
        gauge = {
            'axis': {'range': [None, 50]},
            'bar': {'color': "darkblue"},
            'steps': [
                {'range': [0, 10], 'color': "lightgray"},
                {'range': [10, 25], 'color': "gray"},
                {'range': [25, 35], 'color': "orange"},
                {'range': [35, 50], 'color': "red"}
            ],
            'threshold': {
                'line': {'color': "red", 'width': 4},
                'thickness': 0.75,
                'value': 40
            }
        }
    ))
    fig.update_layout(height=300)
    return fig

def main():
    st.title("🌤️ Weather Dashboard")
    st.markdown("Real-time weather information for Spanish cities")
    
    # Sidebar
    st.sidebar.header("Dashboard Controls")
    
    # API Health Check
    if check_api_health():
        st.sidebar.success("✅ API Status: Healthy")
    else:
        st.sidebar.error("❌ API Status: Unavailable")
        st.error("The weather API is not available. Please check if the backend service is running.")
        return
    
    # Refresh controls
    auto_refresh = st.sidebar.checkbox("Auto-refresh (30s)")
    if st.sidebar.button("🔄 Refresh Now"):
        st.rerun()
    
    # City selection
    cities = ["All Cities", "Madrid", "Barcelona", "Valencia", "Sevilla"]
    selected_city = st.sidebar.selectbox("Select City", cities)
    
    # Main content
    col1, col2, col3 = st.columns([2, 1, 1])
    
    with col1:
        st.subheader("Current Weather Data")
        
        # Fetch and display weather data
        if selected_city == "All Cities":
            weather_data = get_weather_data()
            if weather_data:
                # Display as table
                df = pd.DataFrame(weather_data)
                st.dataframe(df, use_container_width=True)
                
                # Temperature chart
                fig = create_temperature_chart(weather_data)
                if fig:
                    st.plotly_chart(fig, use_container_width=True)
        else:
            weather_data = get_weather_data(selected_city.lower())
            if weather_data:
                # Display single city data
                col_temp, col_desc, col_humid = st.columns(3)
                
                with col_temp:
                    st.metric(
                        label="Temperature",
                        value=f"{weather_data['temperature']}°C"
                    )
                
                with col_desc:
                    st.metric(
                        label="Condition",
                        value=weather_data['description'].title()
                    )
                
                with col_humid:
                    st.metric(
                        label="Humidity",
                        value=f"{weather_data['humidity']}%"
                    )
                
                # Temperature gauge
                fig_gauge = create_weather_gauge(weather_data['temperature'])
                st.plotly_chart(fig_gauge, use_container_width=True)
    
    with col2:
        st.subheader("Quick Stats")
        
        # Get all cities data for stats
        all_weather = get_weather_data()
        if all_weather:
            temps = [item['temperature'] for item in all_weather]
            st.metric("Average Temp", f"{sum(temps)/len(temps):.1f}°C")
            st.metric("Highest Temp", f"{max(temps)}°C")
            st.metric("Lowest Temp", f"{min(temps)}°C")
    
    with col3:
        st.subheader("System Info")
        st.info(f"Last Updated: {datetime.now().strftime('%H:%M:%S')}")
        st.info(f"Total Cities: {len(cities)-1}")
        
        # Display API base URL
        st.text_area("API Endpoint", API_BASE_URL, height=68)
    
    # Auto-refresh functionality
    if auto_refresh:
        time.sleep(30)
        st.rerun()
    
    # Footer
    st.markdown("---")
    st.markdown("Weather Dashboard API - DevOps Training Project")

if __name__ == "__main__":
    main()
