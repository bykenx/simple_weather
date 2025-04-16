import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/forecast_days.dart';
import 'package:simple_weather/services/http_service.dart';
import 'package:simple_weather/services/settings_service.dart';

class WeatherService {
  final HttpService _httpService = HttpService();
  final SettingsService _settingsService = SettingsService();

  Future<bool> isApiConfigured() async {
    final apiKey = await _settingsService.getApiKey();
    final apiHost = await _settingsService.getApiHost();
    return apiKey != null && apiKey.isNotEmpty && apiHost != null && apiHost.isNotEmpty;
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
    double? lat,
    double? lon,
    String? locationId,
  }) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    assert(locationId != null || (lat != null && lon != null));
    try {
      final apiKey = await _getApiKey();
      final apiHost = await _getApiHost();
      final response = await _httpService.get(
        'https://$apiHost/v7/weather/now',
        queryParameters: {'location': '$lon,$lat', 'key': apiKey},
      );
      if (response.data['code'] != '200') {
        throw '获取实时天气失败';
      }

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWeatherForecast({
    double? lat,
    double? lon,
    String? locationId,
    ForecastDays forecastDays = ForecastDays.three,
  }) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    assert(locationId != null || (lat != null && lon != null));
    try {
      final apiKey = await _getApiKey();
      final apiHost = await _getApiHost();
      final response = await _httpService.get(
        'https://$apiHost/v7/weather/${forecastDays.apiSuffix}',
        queryParameters: {'location': '$lon,$lat', 'key': apiKey},
      );

      if (response.data['code'] != '200') {
        throw '获取天气预报失败';
      }

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHourlyWeather({
    double? lat,
    double? lon,
    String? locationId,
  }) async {
    if (!await isApiConfigured()) {
      throw '请先完成API配置';
    }
    assert(locationId != null || (lat != null && lon != null));
    try {
      final apiKey = await _getApiKey();
      final apiHost = await _getApiHost();
      final response = await _httpService.get(
        'https://$apiHost/v7/weather/24h',
        queryParameters: {'location': '$lon,$lat', 'key': apiKey},
      );

      if (response.data['code'] != '200') {
        throw '获取逐小时天气失败';
      }

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<WeatherWarningModel>> getWeatherWarnings({
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
        'https://$apiHost/v7/warning/now',
        queryParameters: {
          'location': '$lon,$lat',
          'key': apiKey,
        },
      );

      if (response.data['code'] == '200') {
        final data = response.data;
        if (data['warning'] != null && data['warning'].isNotEmpty) {
          return (data['warning'] as List)
              .map((item) => WeatherWarningModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
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

      return AirQualityModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
