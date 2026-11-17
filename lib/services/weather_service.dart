import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/services/http_service.dart';
import 'package:simple_weather/services/settings_service.dart';

class WeatherService {
  final HttpService _httpService = HttpService();
  final SettingsService _settingsService = SettingsService();

  Future<bool> isApiConfigured() async {
    final apiKey = await _settingsService.getApiKey();
    final apiHost = await _settingsService.getApiHost();
    return apiKey != null &&
        apiKey.isNotEmpty &&
        apiHost != null &&
        apiHost.isNotEmpty;
  }

  Future<String> _getApiKey() async {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw '请先设置API密钥';
    }
    return apiKey;
  }

  Future<String> _getApiHost() async {
    final apiHost = await _settingsService.getApiHost();
    if (apiHost == null || apiHost.isEmpty) {
      throw '请先设置API域名';
    }
    return apiHost;
  }

  Future<Map<String, dynamic>> getHotCities() async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    try {
      final apiKey = await _getApiKey();
      final apiHost = await _getApiHost();
      final response = await _httpService.get(
        'https://$apiHost/geo/v2/city/top',
        queryParameters: {'key': apiKey},
      );
      if (response.data['code'] != '200') {
        throw '获取热门城市失败';
      }
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> searchCity(String query) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    try {
      final apiKey = await _getApiKey();
      final apiHost = await _getApiHost();
      final response = await _httpService.get(
        'https://$apiHost/geo/v2/city/lookup',
        queryParameters: {'location': query, 'key': apiKey},
      );

      if (response.data['code'] != '200' ||
          response.data['location'] == null ||
          response.data['location'].isEmpty) {
        throw '未找到该城市';
      }

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLiveWeather({
    required double lat,
    required double lon,
  }) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    final apiKey = await _getApiKey();
    final apiHost = await _getApiHost();
    final response = await _httpService.get(
      'https://$apiHost/weather/v1/current/'
      '${lat.toStringAsFixed(2)}/${lon.toStringAsFixed(2)}',
      queryParameters: {'localTime': true, 'lang': 'zh'},
      headers: {'X-QW-Api-Key': apiKey},
    );
    if (response.data is! Map ||
        response.data['condition'] is! Map ||
        response.data['temperature'] is! Map) {
      throw '获取实时天气失败';
    }
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getDailyWeather({
    required double lat,
    required double lon,
  }) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    final host = await _getApiHost();
    final key = await _getApiKey();
    final response = await _httpService.get(
      'https://$host/weather/v1/daily/${lat.toStringAsFixed(2)}/${lon.toStringAsFixed(2)}',
      queryParameters: {'days': 10, 'localTime': true, 'lang': 'zh'},
      headers: {'X-QW-Api-Key': key},
    );
    if (response.data is! Map ||
        response.data['days'] is! List ||
        (response.data['days'] as List).isEmpty ||
        (response.data['days'] as List).any((day) => day is! Map)) {
      throw '获取每日天气预报失败';
    }
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getHourlyWeather({
    required double lat,
    required double lon,
  }) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    final apiKey = await _getApiKey();
    final apiHost = await _getApiHost();
    final response = await _httpService.get(
      'https://$apiHost/weather/v1/hourly/'
      '${lat.toStringAsFixed(2)}/${lon.toStringAsFixed(2)}',
      queryParameters: {'hours': 240, 'localTime': true, 'lang': 'zh'},
      headers: {'X-QW-Api-Key': apiKey},
    );
    if (response.data is! Map ||
        response.data['hours'] is! List ||
        (response.data['hours'] as List).isEmpty ||
        (response.data['hours'] as List).any((hour) => hour is! Map)) {
      throw '获取逐小时天气失败';
    }
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<WeatherWarningModel>> getWeatherWarnings({
    required double lat,
    required double lon,
  }) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    final apiKey = await _getApiKey();
    final apiHost = await _getApiHost();
    final response = await _httpService.get(
      'https://$apiHost/weatheralert/v1/current/'
      '${lat.toStringAsFixed(2)}/${lon.toStringAsFixed(2)}',
      queryParameters: {'localTime': true, 'lang': 'zh'},
      headers: {'X-QW-Api-Key': apiKey},
    );
    final data = response.data;
    if (data is! Map || data['metadata'] is! Map) {
      throw '获取天气预警失败';
    }
    final metadata = data['metadata'] as Map;
    final zeroResult = metadata['zeroResult'];
    final rawAlerts = data['alerts'];
    final alerts =
        rawAlerts == null && zeroResult == true ? const [] : rawAlerts;
    if (alerts is! List) throw '获取天气预警失败';
    final sources = metadata['attributions'] ?? const [];
    if ((zeroResult != null && zeroResult is! bool) ||
        sources is! List ||
        sources.any((source) => source is! String) ||
        alerts.any((alert) => alert is! Map) ||
        (alerts.isEmpty && zeroResult != true) ||
        (alerts.isNotEmpty && zeroResult == true)) {
      throw '获取天气预警失败';
    }
    // Only the documented successful zero-result response clears saved alerts.
    // Parsing any malformed alert throws, leaving the previous module intact.
    return alerts
        .map(
          (alert) => WeatherWarningModel.fromJson({
            ...Map<String, dynamic>.from(alert),
            '_attributions': List<String>.from(sources),
          }),
        )
        .toList();
  }

  Future<AirQualityModel> getAirQuality({
    required double lat,
    required double lon,
  }) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    try {
      final apiKey = await _getApiKey();
      final apiHost = await _getApiHost();
      final response = await _httpService.get(
        'https://$apiHost/airquality/v1/current/$lat/$lon',
        queryParameters: {'key': apiKey},
      );

      // 处理API返回的JSON结构，提取需要的部分
      final responseData = response.data;
      final airQualityData = extractAirQualityData(responseData);
      return AirQualityModel.fromJson(airQualityData);
    } catch (e) {
      rethrow;
    }
  }

  // 从API响应中提取空气质量数据
  Map<String, dynamic> extractAirQualityData(
    Map<String, dynamic> responseData,
  ) {
    if (responseData.containsKey('indexes') &&
        responseData['indexes'] is List &&
        responseData['indexes'].isNotEmpty) {
      final firstIndex = responseData['indexes'][0];
      final Map<String, dynamic> result = {
        'aqi': firstIndex['aqi'],
        'code': firstIndex['code'],
        'name': firstIndex['name'],
        'category': firstIndex['category'],
        'primaryPollutant': firstIndex['primaryPollutant'],
        'health': firstIndex['health'],
        'pollutants': responseData['pollutants'],
      };
      return result;
    }

    return {
      'aqi': 0.0,
      'code': '',
      'name': '',
      'category': '',
      'primaryPollutant': {'code': '', 'name': '', 'fullName': ''},
      'health': {
        'effect': '',
        'advice': {'generalPopulation': '', 'sensitivePopulation': ''},
      },
      'pollutants': [],
    };
  }
}
