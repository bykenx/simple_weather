import 'package:dio/dio.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/services/http_service.dart';
import 'package:simple_weather/services/settings_service.dart';

class WeatherService {
  final HttpService _httpService = HttpService();
  final SettingsService _settingsService = SettingsService();

  Future<bool> isApiConfigured() => _settingsService.isSettingsComplete();

  Future<Map<String, dynamic>> getHotCities({CancelToken? cancelToken}) =>
      _getJson(
        '/geo/v2/city/top',
        cancelToken: cancelToken,
        errorMessage: '获取热门城市失败',
        validate: (data) => data['code'] == '200',
      );

  Future<Map<String, dynamic>> searchCity(
    String query, {
    CancelToken? cancelToken,
  }) async {
    const errorMessage = '搜索城市失败，请检查API配置或稍后重试';
    final data = await _getJson(
      '/geo/v2/city/lookup',
      queryParameters: {'location': query},
      cancelToken: cancelToken,
      handleErrorResponse: true,
      errorMessage: errorMessage,
    );
    final apiError = data['error'];
    final noLocation =
        apiError is Map &&
        Uri.tryParse(apiError['type']?.toString() ?? '')?.fragment ==
            'no-such-location';
    if (noLocation || data['code'] == '404') {
      return {'location': <dynamic>[]};
    }
    if (data['code'] != '200' || data['location'] is! List) {
      throw errorMessage;
    }
    return data;
  }

  Future<Map<String, dynamic>> getLiveWeather({
    required double lat,
    required double lon,
  }) => _getWeatherJson(
    '/weather/v1/current',
    lat: lat,
    lon: lon,
    errorMessage: '获取实时天气失败',
    validate: (data) => data['condition'] is Map && data['temperature'] is Map,
  );

  Future<Map<String, dynamic>> getDailyWeather({
    required double lat,
    required double lon,
  }) => _getWeatherJson(
    '/weather/v1/daily',
    lat: lat,
    lon: lon,
    queryParameters: {'days': 10},
    errorMessage: '获取每日天气预报失败',
    validate: (data) => _hasForecastEntries(data['days']),
  );

  Future<Map<String, dynamic>> getHourlyWeather({
    required double lat,
    required double lon,
  }) => _getWeatherJson(
    '/weather/v1/hourly',
    lat: lat,
    lon: lon,
    queryParameters: {'hours': 240},
    errorMessage: '获取逐小时天气失败',
    validate: (data) => _hasForecastEntries(data['hours']),
  );

  Future<List<WeatherWarningModel>> getWeatherWarnings({
    required double lat,
    required double lon,
  }) async {
    const errorMessage = '获取天气预警失败';
    final data = await _getWeatherJson(
      '/weatheralert/v1/current',
      lat: lat,
      lon: lon,
      errorMessage: errorMessage,
      validate: (data) => data['metadata'] is Map,
    );
    final metadata = data['metadata'] as Map;
    final zeroResult = metadata['zeroResult'];
    final rawAlerts = data['alerts'];
    final alerts =
        rawAlerts == null && zeroResult == true ? const [] : rawAlerts;
    if (alerts is! List) throw errorMessage;
    final sources = metadata['attributions'] ?? const [];
    if ((zeroResult != null && zeroResult is! bool) ||
        sources is! List ||
        sources.any((source) => source is! String) ||
        alerts.any((alert) => alert is! Map) ||
        (alerts.isEmpty && zeroResult != true) ||
        (alerts.isNotEmpty && zeroResult == true)) {
      throw errorMessage;
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
    final data = await _getJson(
      '/airquality/v1/current/$lat/$lon',
      errorMessage: '获取空气质量失败',
    );
    return AirQualityModel.fromJson(extractAirQualityData(data));
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    required String errorMessage,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool handleErrorResponse = false,
    bool Function(Map<String, dynamic>)? validate,
  }) async {
    final apiKey = await _settingsService.getApiKey();
    final apiHost = await _settingsService.getApiHost();
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiHost == null ||
        apiHost.isEmpty) {
      throw '请先完成API配置';
    }
    final response = await _httpService.get(
      'https://$apiHost$path',
      queryParameters: queryParameters,
      headers: {'X-QW-Api-Key': apiKey},
      cancelToken: cancelToken,
      handleErrorResponse: handleErrorResponse,
    );
    final data = response.data;
    if (data is! Map || data.keys.any((key) => key is! String)) {
      throw errorMessage;
    }
    final json = Map<String, dynamic>.from(data);
    if (validate != null && !validate(json)) throw errorMessage;
    return json;
  }

  Future<Map<String, dynamic>> _getWeatherJson(
    String path, {
    required double lat,
    required double lon,
    required String errorMessage,
    Map<String, dynamic> queryParameters = const {},
    bool Function(Map<String, dynamic>)? validate,
  }) => _getJson(
    '$path/${lat.toStringAsFixed(2)}/${lon.toStringAsFixed(2)}',
    queryParameters: {'localTime': true, 'lang': 'zh', ...queryParameters},
    errorMessage: errorMessage,
    validate: validate,
  );

  bool _hasForecastEntries(dynamic entries) =>
      entries is List &&
      entries.isNotEmpty &&
      entries.every((entry) => entry is Map);

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
