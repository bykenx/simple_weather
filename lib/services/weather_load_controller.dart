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
    final response = await service.getDailyWeather(
      lat: city.lat!,
      lon: city.lon!,
    );
    final sources = response['metadata']?['attributions'] ?? [];
    return (response['days'] as List)
        .map(
          (day) => DailyWeatherModel.fromJson({
            ...Map<String, dynamic>.from(day),
            '_attributions': sources,
          }),
        )
        .toList();
  }

  Future<dynamic> _fetch(CityModel city, WeatherModule module) async {
    if (loader != null) return loader!(city, module);
    if (city.lat == null || city.lon == null) throw '城市缺少坐标，请重新添加';
    return switch (module) {
      WeatherModule.live => LiveWeatherModel.fromJson(
        await service.getLiveWeather(lat: city.lat!, lon: city.lon!),
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
      lat: city.lat!,
      lon: city.lon!,
    );
    final rawHours = response['hours'] as List;
    final sources = response['metadata']?['attributions'] ?? const [];
    final hours =
        rawHours
            .map(
              (hour) => HourlyWeatherModel.fromJson({
                ...Map<String, dynamic>.from(hour),
                '_attributions': sources,
              }),
            )
            .toList();
    return hours;
  }

  Future<void> _load(CityModel city, WeatherModule module) async {
    final cityData = data(city);
    final state = cityData.module(module);
    state.isLoading = true;
    state.error = null;
    _emit();
    try {
      var result = await _fetch(city, module);
      if (_disposed) return;
      if (module == WeatherModule.hourly) {
        final hours = List<HourlyWeatherModel>.from(result as List);
        if (!hasTenDayHourlyCoverage(hours)) {
          throw '逐小时预报数据不完整，请稍后重试';
        }
        result = hours;
      }
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
