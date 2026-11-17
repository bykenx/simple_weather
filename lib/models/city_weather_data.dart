import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/weather_module.dart';
import '../utils/weather_time.dart';

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

  DateTime get detailStartDate {
    final today = WeatherTimeUtils.date(
      WeatherTimeUtils.atOffset(DateTime.now(), utcOffset),
    );
    return today;
  }

  List<DailyWeatherModel> get detailDays {
    final start = detailStartDate;
    final end = start.add(const Duration(days: 10));
    return (dailyForecast ?? <DailyWeatherModel>[])
        .where((day) => !day.date.isBefore(start) && day.date.isBefore(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<HourlyWeatherModel> get detailHours {
    final start = detailStartDate;
    final end = start.add(const Duration(days: 10));
    final offset = utcOffset ?? Duration.zero;
    final now = DateTime.now().toUtc();
    return (hourlyForecast ?? <HourlyWeatherModel>[])
        .where(
          (hour) =>
              !hour.time.isBefore(start) &&
              !hour.time.subtract(hour.utcOffset ?? offset).isBefore(now) &&
              hour.time.isBefore(end),
        )
        .toList()
      ..sort(
        (a, b) => a.time
            .subtract(a.utcOffset ?? offset)
            .compareTo(b.time.subtract(b.utcOffset ?? offset)),
      );
  }

  Duration? get utcOffset {
    final observationOffset = WeatherTimeUtils.offsetOf(weather?.obsTime);
    if (observationOffset != null) return observationOffset;
    // Choose the offset near the current instant, since cached forecasts can
    // span a daylight-saving transition.
    final now = DateTime.now().toUtc();
    DateTime? latestElapsed, earliestFuture;
    Duration? elapsedOffset, futureOffset;
    for (final hour in hourlyForecast ?? <HourlyWeatherModel>[]) {
      final offset = hour.utcOffset;
      if (offset == null) continue;
      final instant = hour.time.subtract(offset);
      if (instant.isAfter(now)) {
        if (earliestFuture == null || instant.isBefore(earliestFuture)) {
          earliestFuture = instant;
          futureOffset = offset;
        }
      } else if (latestElapsed == null || instant.isAfter(latestElapsed)) {
        latestElapsed = instant;
        elapsedOffset = offset;
      }
    }
    final hourlyOffset = elapsedOffset ?? futureOffset;
    if (hourlyOffset != null) return hourlyOffset;
    final cityOffset = WeatherTimeUtils.offsetOf(city.utcOffset);
    if (cityOffset != null) return cityOffset;
    final forecastOffset = WeatherTimeUtils.offsetOf(
      dailyForecast?.firstOrNull?.details?.json['forecastStartTime']
          ?.toString(),
    );
    return forecastOffset;
  }
}
