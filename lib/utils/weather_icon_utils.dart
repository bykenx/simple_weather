import 'package:flutter/material.dart';
import 'weather_icons.g.dart';

class WeatherIconUtils {
  static IconData getWeatherIcon(String iconCode, {bool filled = false}) {
    final code = iconCode.trim();
    return (filled
            ? filledWeatherIcons[code] ??
                weatherIcons[code] ??
                filledWeatherIcons['999'] ??
                weatherIcons['999']
            : weatherIcons[code] ?? weatherIcons['999']) ??
        Icons.help_outline;
  }

  static String getIconDescription(String iconCode) =>
      weatherDescriptions[iconCode.trim()] ??
      weatherDescriptions['999'] ??
      '未知';
}
