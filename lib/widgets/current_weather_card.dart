import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';

class CurrentWeatherCard extends StatelessWidget {
  final LiveWeatherModel weather;
  final DailyWeatherModel? dailyForecast;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
    this.dailyForecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Icon(
            WeatherIconUtils.getWeatherIcon(weather.icon),
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          Text(
            '${weather.temp.toStringAsFixed(1)}°C',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            WeatherIconUtils.getIconDescription(weather.icon),
            style: const TextStyle(fontSize: 16),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('最高 ${dailyForecast?.maxTemp.toStringAsFixed(1)}°C'),
              const SizedBox(width: 10),
              Text('最低 ${dailyForecast?.minTemp.toStringAsFixed(1)}°C'),
            ],
          ),
        ],
      ),
    );
  }
}
