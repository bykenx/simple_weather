import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/forecast_days.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/services/weather_service.dart';
import 'package:simple_weather/utils/date_utils.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';

class ExtendedForecastScreen extends StatefulWidget {
  final CityModel currentCity;

  const ExtendedForecastScreen({super.key, required this.currentCity});

  @override
  State<ExtendedForecastScreen> createState() => _ExtendedForecastScreenState();
}

class _ExtendedForecastScreenState extends State<ExtendedForecastScreen> {
  final WeatherService _weatherService = WeatherService();
  static const String _extendedForecastCacheKey = 'extended_forecast_cache';
  static const Duration _cacheExpiry = Duration(hours: 6); // 6小时过期

  List<DailyWeatherModel>? _dailyForecast;
  bool _isLoading = true;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadExtendedForecastWithCache();
  }

  // 检查缓存是否过期
  bool _isCacheExpired() {
    if (_lastUpdated == null) return true;
    return DateTime.now().isAfter(_lastUpdated!.add(_cacheExpiry));
  }

  // 加载扩展天气预报（优先从缓存加载）
  Future<void> _loadExtendedForecastWithCache() async {
    // 尝试从缓存加载数据
    await _loadFromCache();

    // 如果缓存不存在或已过期，从网络加载
    if (_dailyForecast == null || _isCacheExpired()) {
      await _loadExtendedForecast();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 从缓存加载数据
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          '${_extendedForecastCacheKey}_${widget.currentCity.uniqueName}';
      final cacheJson = prefs.getString(cacheKey);

      if (cacheJson != null && cacheJson.isNotEmpty) {
        final cacheData = Map<String, dynamic>.from(jsonDecode(cacheJson));

        setState(() {
          _lastUpdated = DateTime.fromMillisecondsSinceEpoch(
            cacheData['lastUpdated'],
          );

          if (cacheData['forecast'] != null) {
            _dailyForecast =
                (cacheData['forecast'] as List)
                    .map(
                      (item) => DailyWeatherModel.fromJson(
                        Map<String, dynamic>.from(item),
                      ),
                    )
                    .toList();
          }
        });

        if (kDebugMode) {
          print('从缓存加载15天天气预报');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('加载缓存出错: $e');
      }
      // 缓存加载错误，忽略并继续从网络加载
    }
  }

  // 将数据保存到缓存
  Future<void> _saveToCache() async {
    if (_dailyForecast == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          '${_extendedForecastCacheKey}_${widget.currentCity.uniqueName}';

      final cacheData = {
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'forecast': _dailyForecast!.map((item) => item.toJson()).toList(),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));

      if (kDebugMode) {
        print('已保存15天天气预报到缓存');
      }
    } catch (e) {
      if (kDebugMode) {
        print('保存缓存出错: $e');
      }
    }
  }

  Future<void> _loadExtendedForecast() async {
    if (!await _weatherService.isApiConfigured()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先完成API配置')));
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await _weatherService.getWeatherForecast(
        lat: widget.currentCity.lat!,
        lon: widget.currentCity.lon!,
        forecastDays: ForecastDays.thirty,
      );

      if (mounted) {
        setState(() {
          _dailyForecast =
              (result['daily'] as List)
                  .map((item) => DailyWeatherModel.fromJson(item))
                  .toList();
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });

        // 保存到缓存
        _saveToCache();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadExtendedForecast,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 100.0,
                  floating: false,
                  backgroundColor: Colors.blue.shade50,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('15天天气预报'),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue.shade200, Colors.blue.shade50],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child:
                      !_isLoading && _dailyForecast != null
                          ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: List.generate(_dailyForecast!.length, (
                                index,
                              ) {
                                final day = _dailyForecast![index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            WeatherDateUtils.getFormattedDateText(day.date),
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          WeatherIconUtils.getWeatherIcon(
                                            day.icon,
                                          ),
                                          size: 24,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            day.description,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${day.minTemp.toStringAsFixed(1)}° ~ ${day.maxTemp.toStringAsFixed(1)}°',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          )
                          : const SizedBox(height: 300), // 预留加载空间
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
