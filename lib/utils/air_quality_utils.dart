import 'package:flutter/material.dart';

/// 空气质量工具类，用于处理AQI相关的计算和转换
/// 
/// 当前只处理中国（cn-mee）的空气质量数据
class AirQualityUtils {
  static int getAqiLevel(double aqi) {
    if (aqi <= 50) return 1;
    if (aqi <= 100) return 2;
    if (aqi <= 150) return 3;
    if (aqi <= 200) return 4;
    if (aqi <= 300) return 5;
    return 6;
  }

  static String getAqiCategory(double aqi) {
    if (aqi <= 50) return '优';
    if (aqi <= 100) return '良';
    if (aqi <= 150) return '轻度污染';
    if (aqi <= 200) return '中度污染';
    if (aqi <= 300) return '重度污染';
    return '严重污染';
  }

  static Color getAqiColor(double aqi) {
    if (aqi <= 50) return const Color.fromRGBO(0, 228, 0, 1); // 优
    if (aqi <= 100) return const Color.fromRGBO(255, 255, 0, 1); // 良
    if (aqi <= 150) return const Color.fromRGBO(255, 126, 0, 1); // 轻度污染
    if (aqi <= 200) return const Color.fromRGBO(255, 0, 0, 1); // 中度污染
    if (aqi <= 300) return const Color.fromRGBO(153, 0, 76, 1); // 重度污染
    return const Color.fromRGBO(126, 0, 35, 1); // 严重污染
  }

  static String getPollutantUnit(String code) {
    switch (code) {
      case 'pm2p5':
      case 'pm10':
        return 'μg/m³';
      case 'o3':
      case 'no2':
      case 'so2':
        return 'ppb';
      case 'co':
        return 'ppm';
      default:
        return '';
    }
  }

  static String formatPollutantValue(double value, String code) {
    return '${value.toStringAsFixed(1)} ${getPollutantUnit(code)}';
  }

  static bool shouldShowAirQuality(String code) {
    return code == 'cn-mee';
  }

  static String getAqiDisplayValue(double aqi) {
    return aqi.round().toString();
  }
}
