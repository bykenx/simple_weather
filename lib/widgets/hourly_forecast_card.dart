import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';

class HourlyForecastCard extends StatelessWidget {
  final List<HourlyWeatherModel> hourlyForecast;

  const HourlyForecastCard({super.key, required this.hourlyForecast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 使用本地时区的当前时间
    final now = DateTime.now().toLocal();
    
    // 过滤掉当前时间之前的数据
    final filteredForecast = hourlyForecast.where((forecast) {
      // 确保API返回的时间也是本地时区
      final forecastLocalTime = forecast.time.toLocal();
      return forecastLocalTime.isAfter(now.subtract(const Duration(minutes: 30)));
    }).toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).cardColor.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '逐小时天气预报',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredForecast.length,
                  itemBuilder: (context, index) {
                    final hourData = filteredForecast[index];
                    final hourLocalTime = hourData.time.toLocal();

                    final diffMinutes = hourLocalTime.difference(now).inMinutes;
                    final isCurrentHour = diffMinutes.abs() <= 30;

                    String timeText;
                    if (isCurrentHour) {
                      timeText = '现在';
                    } else if (hourLocalTime.hour == 0) {
                      timeText = '${hourLocalTime.month}/${hourLocalTime.day}';
                    } else {
                      timeText = '${hourLocalTime.hour}:00';
                    }

                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Text(
                            timeText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            WeatherIconUtils.getWeatherIcon(
                              hourData.icon,
                              filled: true,
                            ),
                            size: 24,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWindOrRainText(hourData),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  hourData.pop != null && hourData.pop! > 0
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${hourData.temp.toStringAsFixed(1)}°C',
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
    );
  }
  
  // 获取风级或降雨概率文本
  String _getWindOrRainText(HourlyWeatherModel data) {
    if (data.pop != null && data.pop! > 0) {
      return '${data.pop!.toStringAsFixed(0)}%';
    } else {
      return '${data.windScale}级';
    }
  }
}
