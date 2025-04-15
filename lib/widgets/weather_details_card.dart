import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherDetailsCard extends StatelessWidget {
  final LiveWeatherModel weather;

  const WeatherDetailsCard({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildWeatherDetail(
              '体感温度',
              '${weather.feelsLike.toStringAsFixed(1)}°C',
              WeatherIcons.thermometer,
            ),
            _buildWeatherDetail(
              '湿度',
              '${weather.humidity}%',
              WeatherIcons.humidity,
            ),
            _buildWeatherDetail(
              '风速',
              '${weather.windSpeed} m/s',
              WeatherIcons.wind,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
} 