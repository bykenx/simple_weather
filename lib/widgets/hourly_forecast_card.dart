import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';

class HourlyForecastCard extends StatelessWidget {
  final List<HourlyWeatherModel> hourlyForecast;

  const HourlyForecastCard({super.key, required this.hourlyForecast});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // 过滤掉当前时间之前的数据
    final filteredForecast = hourlyForecast.where((hour) {
      return hour.time.hour >= currentHour;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '逐小时天气预报',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredForecast.length,
                    itemBuilder: (context, index) {
                      final hour = filteredForecast[index];
                      final isCurrentHour = hour.time.hour == currentHour;
                      
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Text(
                              isCurrentHour ? '现在' : '${hour.time.hour}:00',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              WeatherIconUtils.getWeatherIcon(hour.icon),
                              size: 24,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${hour.temp.toStringAsFixed(1)}°C',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
