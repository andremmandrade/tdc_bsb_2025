const express = require('express');
const axios = require('axios');
const app = express();

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from Node API - Test1' });
});

// New York weather endpoint using Open-Meteo API (no API key required)
app.get('/api/weather/ny', async (req, res) => {
  try {
    // New York coordinates: 40.7128° N, 74.0060° W
    const response = await axios.get('https://api.open-meteo.com/v1/forecast', {
      params: {
        latitude: 40.7128,
        longitude: -74.0060,
        current: 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
        temperature_unit: 'fahrenheit',
        wind_speed_unit: 'mph',
        timezone: 'America/New_York'
      },
      timeout: 5000
    });

    const current = response.data.current;
    const weatherCodes = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Foggy',
      48: 'Foggy',
      51: 'Light drizzle',
      53: 'Moderate drizzle',
      55: 'Dense drizzle',
      61: 'Slight rain',
      63: 'Moderate rain',
      65: 'Heavy rain',
      71: 'Slight snow',
      73: 'Moderate snow',
      75: 'Heavy snow',
      80: 'Slight rain showers',
      81: 'Moderate rain showers',
      82: 'Violent rain showers',
      95: 'Thunderstorm'
    };

    res.json({
      location: 'New York, NY',
      timestamp: current.time,
      temperature: {
        current: current.temperature_2m,
        feels_like: current.apparent_temperature,
        unit: '°F'
      },
      humidity: current.relative_humidity_2m,
      precipitation: current.precipitation,
      wind_speed: {
        value: current.wind_speed_10m,
        unit: 'mph'
      },
      conditions: weatherCodes[current.weather_code] || 'Unknown',
      source: 'Open-Meteo API'
    });
  } catch (error) {
    console.error('Weather API error:', error.message);
    res.status(500).json({ 
      error: 'Failed to fetch weather data',
      message: error.message 
    });
  }
});

// Load testing endpoint - simulates CPU-intensive work
app.get('/api/load', (req, res) => {
  const duration = parseInt(req.query.duration) || 100;
  const start = Date.now();
  
  // Simulate work
  let result = 0;
  while (Date.now() - start < duration) {
    result += Math.sqrt(Math.random());
  }
  
  res.json({ 
    message: 'Load test completed',
    duration: `${Date.now() - start}ms`,
    result: result 
  });
});

module.exports = app;