import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/city_weather_data.dart';
import 'package:simple_weather/models/weather_model.dart';

class WeatherCacheService {
  static const String _weatherCacheKey = 'weather_cache';
  static final WeatherCacheService _instance = WeatherCacheService._internal();
  
  factory WeatherCacheService() => _instance;
  WeatherCacheService._internal();

  // 保存城市天气数据到缓存
  Future<void> saveWeatherData(String cityKey, CityWeatherData weatherData) async {
    if (weatherData.weather == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 创建要缓存的数据结构
      final Map<String, dynamic> cacheData = {
        'lastUpdated': weatherData.lastUpdated.millisecondsSinceEpoch,
        'data': {
          'weather': weatherData.weather?.toJson(),
          'dailyForecast': weatherData.dailyForecast?.map((e) => e.toJson()).toList(),
          'hourlyForecast': weatherData.hourlyForecast?.map((e) => e.toJson()).toList(),
          'warnings': weatherData.warnings?.map((e) => e.toJson()).toList(),
          'airQuality': weatherData.airQuality?.toJson(),
        }
      };
      
      // 直接保存该城市的数据
      await prefs.setString('${_weatherCacheKey}_$cityKey', jsonEncode(cacheData));
    } catch (e) {
      // 忽略缓存错误
      if (kDebugMode) {
        print('缓存保存错误: $e');
      }
    }
  }

  // 从缓存加载城市天气数据
  Future<CityWeatherData?> loadWeatherData(CityModel city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityKey = city.uniqueName;
      final cacheString = prefs.getString('${_weatherCacheKey}_$cityKey');
      
      if (cacheString == null || cacheString.isEmpty) return null;
      
      final Map<String, dynamic> cacheData = jsonDecode(cacheString);
      final weatherData = CityWeatherData(city);
      
      // 设置最后更新时间
      if (cacheData.containsKey('lastUpdated')) {
        weatherData.lastUpdated = 
            DateTime.fromMillisecondsSinceEpoch(cacheData['lastUpdated']);
      }
      
      final data = cacheData['data'];
      if (data == null) return null;
      
      // 恢复天气数据
      if (data.containsKey('weather')) {
        weatherData.weather = LiveWeatherModel.fromJson(data['weather']);
      }
      
      // 恢复天气预报数据
      if (data.containsKey('dailyForecast')) {
        weatherData.dailyForecast = (data['dailyForecast'] as List)
            .map((item) => DailyWeatherModel.fromJson(item))
            .toList();
      }
      
      // 恢复小时预报数据
      if (data.containsKey('hourlyForecast')) {
        weatherData.hourlyForecast = (data['hourlyForecast'] as List)
            .map((item) => HourlyWeatherModel.fromJson(item))
            .toList();
      }
      
      // 恢复天气预警数据
      if (data.containsKey('warnings')) {
        weatherData.warnings = (data['warnings'] as List)
            .map((item) => WeatherWarningModel.fromJson(item))
            .toList();
      }
      
      // 恢复空气质量数据
      if (data.containsKey('airQuality')) {
        final airQualityData = data['airQuality'];
        weatherData.airQuality = AirQualityModel.fromJson(airQualityData);
      }
      
      return weatherData;
    } catch (e) {
      // 如果解析缓存数据出错，返回null
      if (kDebugMode) {
        print('缓存加载错误: $e');
      }
      return null;
    }
  }

  // 清除指定城市的缓存数据
  Future<void> clearCityCache(String cityKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_weatherCacheKey}_$cityKey');
    } catch (e) {
      // 忽略清除缓存错误
    }
  }

  // 清除所有缓存数据
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_weatherCacheKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // 忽略清除缓存错误
    }
  }
} 