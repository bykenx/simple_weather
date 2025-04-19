import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/weather_model.dart';

class CityWeatherData {
  final CityModel city;
  LiveWeatherModel? weather;
  List<DailyWeatherModel>? dailyForecast;
  List<HourlyWeatherModel>? hourlyForecast;
  List<WeatherWarningModel>? warnings;
  AirQualityModel? airQuality;
  bool isLoading;
  late DateTime lastUpdated;

  CityWeatherData(this.city, {this.isLoading = false}) {
    lastUpdated = DateTime.now();
  }

  bool get hasData => weather != null;

  bool get isExpired =>
      DateTime.now().isAfter(lastUpdated.add(const Duration(hours: 1)));
}
