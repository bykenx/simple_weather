import '../models/forecast_days.dart';
import 'package:flutter/foundation.dart';
import '../models/city_weather_data.dart';
import '../models/city_model.dart';
import '../models/weather_module.dart';
import '../models/weather_model.dart';
import 'weather_service.dart';
import 'weather_cache_service.dart';

typedef ModuleLoader = Future<dynamic> Function(CityModel, WeatherModule);

class WeatherLoadController extends ChangeNotifier {
  final WeatherService service;
  final WeatherCacheService cache;
  final ModuleLoader? loader;
  final Map<String, CityWeatherData> cities = {};
  final Map<String, Future<void>> _pending = {};
  bool _disposed = false;
  WeatherLoadController({
    WeatherService? service,
    WeatherCacheService? cache,
    this.loader,
  }) : service = service ?? WeatherService(),
       cache = cache ?? WeatherCacheService();
  CityWeatherData data(CityModel city) =>
      cities.putIfAbsent(city.id, () => CityWeatherData(city));
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restore(CityModel city) async {
    if (cities.containsKey(city.id)) return;
    final saved = await cache.loadWeatherData(city);
    if (_disposed || cities.containsKey(city.id)) return;
    cities[city.id] = saved ?? CityWeatherData(city);
    _emit();
  }

  Future<void> refresh(CityModel city) =>
      Future.wait(WeatherModule.values.map((m) => retry(city, m)));
  Future<void> retry(CityModel city, WeatherModule module) {
    if (_disposed) return Future.value();
    final key = '${city.id}:${module.name}';
    return _pending.putIfAbsent(
      key,
      () => _load(city, module).whenComplete(() {
        _pending.remove(key);
      }),
    );
  }

  Future<List<DailyWeatherModel>> _daily(CityModel city) async {
    try {
      final response = await service.getDailyWeather(
        lat: city.lat!,
        lon: city.lon!,
      );
      final sources = response['metadata']?['attributions'] ?? [];
      final days =
          (response['days'] as List)
              .map(
                (day) => DailyWeatherModel.fromJson({
                  ...Map<String, dynamic>.from(day),
                  '_attributions': sources,
                }),
              )
              .toList();
      return await _withMoonAstronomy(city, days);
    } catch (_) {
      // Keep forecasts available for accounts without access to the v1 product.
    }
    Map<String, dynamic> response;
    try {
      response = await service.getWeatherForecast(
        lat: city.lat,
        lon: city.lon,
        forecastDays: ForecastDays.ten,
      );
    } catch (_) {
      // Some accounts only have the shorter forecast; retain useful live data.
      response = await service.getWeatherForecast(lat: city.lat, lon: city.lon);
    }
    final days =
        (response['daily'] as List)
            .map((day) => DailyWeatherModel.fromJson(day))
            .toList();
    return await _withMoonAstronomy(city, days);
  }

  Future<List<DailyWeatherModel>> _withMoonAstronomy(
    CityModel city,
    List<DailyWeatherModel> days,
  ) async {
    if (days.isEmpty) return days;
    try {
      final moon = await service.getMoonAstronomy(
        lat: city.lat!,
        lon: city.lon!,
        date: days.first.date,
      );
      final phases =
          moon['moonPhase'] is List ? moon['moonPhase'] as List : const [];
      final firstJson =
          days.first.toJson()
            ..['_moonrise'] = moon['moonrise']
            ..['_moonset'] = moon['moonset']
            ..['_moonPhaseHourly'] = phases;
      return [DailyWeatherModel.fromJson(firstJson), ...days.skip(1)];
    } catch (_) {
      // Astronomy is an enhancement; daily weather remains usable without it.
      return days;
    }
  }

  Future<dynamic> _fetch(CityModel city, WeatherModule module) async {
    if (loader != null) return loader!(city, module);
    if (city.lat == null || city.lon == null) throw '城市缺少坐标，请重新添加';
    return switch (module) {
      WeatherModule.live => LiveWeatherModel.fromJson(
        (await service.getLiveWeather(lat: city.lat, lon: city.lon))['now'],
      ),
      WeatherModule.daily => await _daily(city),
      WeatherModule.hourly => await _hourly(city),
      WeatherModule.warnings => await service.getWeatherWarnings(
        lat: city.lat!,
        lon: city.lon!,
      ),
      WeatherModule.airQuality => await service.getAirQuality(
        lat: city.lat!,
        lon: city.lon!,
      ),
    };
  }

  Future<List<HourlyWeatherModel>> _hourly(CityModel city) async {
    final response = await service.getHourlyWeather(
      lat: city.lat,
      lon: city.lon,
    );
    final sources = response['metadata']?['attributions'] ?? const [];
    final hours =
        (response['hours'] as List)
            .map(
              (hour) => HourlyWeatherModel.fromJson({
                ...Map<String, dynamic>.from(hour),
                '_attributions': sources,
              }),
            )
            .toList();
    if (!hasTenDayHourlyCoverage(hours)) {
      throw '逐小时预报数据不完整，请稍后重试';
    }
    return hours;
  }

  Future<void> _load(CityModel city, WeatherModule module) async {
    final cityData = data(city);
    final state = cityData.module(module);
    state.isLoading = true;
    state.error = null;
    _emit();
    try {
      final result = await _fetch(city, module);
      if (_disposed) return;
      state.data = result;
      state.updatedAt = DateTime.now();
      state.fromCache = false;
    } catch (e) {
      if (!_disposed) state.error = e.toString();
    } finally {
      state.isLoading = false;
      _emit();
    }
    if (!_disposed) await cache.saveWeatherData(city.uniqueName, cityData);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
