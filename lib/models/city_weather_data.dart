import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/weather_module.dart';

class CityWeatherData {
  final CityModel city;
  final live = ModuleState<LiveWeatherModel>();
  final daily = ModuleState<List<DailyWeatherModel>>();
  final hourly = ModuleState<List<HourlyWeatherModel>>();
  final warningState = ModuleState<List<WeatherWarningModel>>();
  final air = ModuleState<AirQualityModel>();
  CityWeatherData(this.city);

  ModuleState<dynamic> module(WeatherModule module) => switch (module) {
    WeatherModule.live => live,
    WeatherModule.daily => daily,
    WeatherModule.hourly => hourly,
    WeatherModule.warnings => warningState,
    WeatherModule.airQuality => air,
  };
  bool get hasData => WeatherModule.values.any((m) => module(m).data != null);
  bool get isLoading => WeatherModule.values.any((m) => module(m).isLoading);
  bool get isExpired => WeatherModule.values.any((m) => module(m).isExpired);
  LiveWeatherModel? get weather => live.data;
  List<DailyWeatherModel>? get dailyForecast => daily.data;
  List<HourlyWeatherModel>? get hourlyForecast => hourly.data;
  List<WeatherWarningModel>? get warnings => warningState.data;
  AirQualityModel? get airQuality => air.data;
}
