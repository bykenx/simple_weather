import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';

class HourlyForecastCard extends StatelessWidget {
  final List<HourlyWeatherModel> hourlyForecast;

  const HourlyForecastCard({super.key, required this.hourlyForecast});

  @override
  Widget build(BuildContext context) {
    // 使用本地时区的当前时间
    final now = DateTime.now().toLocal();
    
    // 过滤掉当前时间之前的数据
    final filteredForecast = hourlyForecast.where((forecast) {
      // 确保API返回的时间也是本地时区
      final forecastLocalTime = forecast.time.toLocal();
      return forecastLocalTime.isAfter(now.subtract(const Duration(minutes: 30)));
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
                      
                      // 计算时间差（分钟）
                      final diffMinutes = hourLocalTime.difference(now).inMinutes;
                      
                      // 如果时间差在半小时内，显示为"现在"
                      final isCurrentHour = diffMinutes.abs() <= 30;
                      
                      // 格式化时间显示
                      String timeText;
                      if (isCurrentHour) {
                        timeText = '现在';
                      } else if (hourLocalTime.hour == 0) {
                        // 0:00时只显示日期，统一使用月/日格式
                        timeText = '${hourLocalTime.month}/${hourLocalTime.day}';
                      } else {
                        // 其他时间正常显示小时
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
                              WeatherIconUtils.getWeatherIcon(hourData.icon),
                              size: 24,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getWindOrRainText(hourData),
                              style: TextStyle(
                                fontSize: 12,
                                color: hourData.pop != null && hourData.pop! > 0 
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade700,
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
