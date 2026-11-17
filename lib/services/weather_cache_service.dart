import '../models/weather_module.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/city_weather_data.dart';
import 'package:simple_weather/models/weather_model.dart';

class WeatherCacheService {
  static const String _weatherCacheKey = 'weather_cache';
  static const String _hotCitiesCacheKey = 'hot_cities_cache';
  const WeatherCacheService();

  Future<void> saveWeatherData(
    String cityKey,
    CityWeatherData weatherData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modules = <String, dynamic>{};
      for (final m in WeatherModule.values) {
        final state = weatherData.module(m);
        if (state.data == null) continue;
        final dynamic value = state.data;
        modules[m.name] = {
          'updatedAt': state.updatedAt?.millisecondsSinceEpoch,
          'data':
              value is List
                  ? value.map((e) => e.toJson()).toList()
                  : value.toJson(),
        };
      }
      await prefs.setString(
        '${_weatherCacheKey}_$cityKey',
        jsonEncode({
          'hourlyTimeVersion': 1,
          'hourlyDataVersion': 2,
          'modules': modules,
        }),
      );
    } catch (e) {
      if (kDebugMode) print('缓存保存错误: $e');
    }
  }

  Future<void> saveHotCities(List<CityModel> cities) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cacheData = {
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'cities': cities.map((city) => city.toJson()).toList(),
      };

      await prefs.setString(_hotCitiesCacheKey, jsonEncode(cacheData));

      if (kDebugMode) {
        print('已保存热门城市到缓存');
      }
    } catch (e) {
      if (kDebugMode) {
        print('保存热门城市缓存错误: $e');
      }
    }
  }

  Future<List<CityModel>?> loadHotCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_hotCitiesCacheKey);

      if (cacheString == null || cacheString.isEmpty) return null;

      final Map<String, dynamic> cacheData = jsonDecode(cacheString);

      if (isHotCitiesCacheExpired(cacheData)) {
        if (kDebugMode) {
          print('热门城市缓存已过期');
        }
        return null;
      }

      if (cacheData['cities'] != null) {
        final cities =
            (cacheData['cities'] as List)
                .map(
                  (item) => CityModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList();

        if (kDebugMode) {
          print('从缓存加载热门城市列表');
        }

        return cities;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('加载热门城市缓存错误: $e');
      }
      return null;
    }
  }

  bool isHotCitiesCacheExpired(Map<String, dynamic> cacheData) {
    if (!cacheData.containsKey('lastUpdated')) return true;

    final lastUpdated = DateTime.fromMillisecondsSinceEpoch(
      cacheData['lastUpdated'],
    );
    return DateTime.now().isAfter(lastUpdated.add(const Duration(hours: 24)));
  }

  Future<CityWeatherData?> loadWeatherData(CityModel city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityKey = city.uniqueName;
      final cacheString = prefs.getString('${_weatherCacheKey}_$cityKey');

      if (cacheString == null || cacheString.isEmpty) return null;

      final Map<String, dynamic> cacheData = jsonDecode(cacheString);
      final weatherData = CityWeatherData(city);

      const legacyKeys = {
        WeatherModule.live: 'weather',
        WeatherModule.daily: 'dailyForecast',
        WeatherModule.hourly: 'hourlyForecast',
        WeatherModule.warnings: 'warnings',
        WeatherModule.airQuality: 'airQuality',
      };
      for (final m in WeatherModule.values) {
        try {
          final entry = cacheData['modules']?[m.name];
          final raw =
              cacheData.containsKey('modules')
                  ? (entry == null ? null : entry['data'])
                  : (cacheData['data'] == null
                      ? null
                      : cacheData['data'][legacyKeys[m]]);
          if (raw == null) continue;
          if (m == WeatherModule.hourly &&
              cacheData['hourlyTimeVersion'] != 1) {
            // Old minute-precision timestamps could be shifted to UTC before
            // saving, losing the original clock and offset. Reload this module
            // rather than displaying an ambiguous cached forecast.
            continue;
          }
          final state = weatherData.module(m);
          state.data = switch (m) {
            WeatherModule.live => LiveWeatherModel.fromJson(raw),
            WeatherModule.daily =>
              (raw as List).map((e) => DailyWeatherModel.fromJson(e)).toList(),
            WeatherModule.hourly =>
              (raw as List).map((e) => HourlyWeatherModel.fromJson(e)).toList(),
            WeatherModule.warnings =>
              (raw as List)
                  .map((e) => WeatherWarningModel.fromJson(e))
                  .toList(),
            WeatherModule.airQuality => AirQualityModel.fromJson(raw),
          };
          final timestamp =
              cacheData.containsKey('modules')
                  ? (entry == null ? null : entry['updatedAt'])
                  : cacheData['lastUpdated'];
          state.updatedAt =
              timestamp is int
                  ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                  : null;
          if (m == WeatherModule.hourly &&
              cacheData['hourlyDataVersion'] != 2 &&
              !hasTenDayHourlyCoverage(
                state.data as List<HourlyWeatherModel>,
              )) {
            // Refresh legacy short feeds once. New partial v1 feeds retain
            // their successful fetch time instead of refreshing every launch.
            state.updatedAt = null;
          }
          state.fromCache = true;
        } catch (e) {
          if (kDebugMode) print('忽略损坏的缓存模块 ${m.name}: $e');
        }
      }
      return weatherData;
    } catch (e) {
      if (kDebugMode) {
        print('缓存加载错误: $e');
      }
      return null;
    }
  }

  Future<void> clearCityCache(String cityKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_weatherCacheKey}_$cityKey');
    } catch (e) {
      // 忽略清除缓存错误
    }
  }

  Future<void> clearHotCitiesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hotCitiesCacheKey);
      if (kDebugMode) {
        print('已清除热门城市缓存');
      }
    } catch (e) {
      // 忽略清除缓存错误
    }
  }

  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_weatherCacheKey) || key == _hotCitiesCacheKey) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // 忽略清除缓存错误
    }
  }
}
