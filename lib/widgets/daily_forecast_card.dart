import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';

class DailyForecastCard extends StatelessWidget {
  final List<DailyWeatherModel> dailyForecast;

  const DailyForecastCard({
    super.key,
    required this.dailyForecast,
  });

  String _getDayText(int index) {
    if (index == 0) return '今天';
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[index % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '未来七天天气预报',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...dailyForecast.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getDayText(entry.key),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Icon(
                      WeatherIconUtils.getWeatherIcon(entry.value.icon),
                      size: 18,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      '${entry.value.minTemp.toStringAsFixed(1)}° ~ ${entry.value.maxTemp.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 