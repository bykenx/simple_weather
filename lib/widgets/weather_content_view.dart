import 'package:flutter/material.dart';
import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/widgets/air_quality_card.dart';
import 'package:simple_weather/widgets/daily_forecast_card.dart';
import 'package:simple_weather/widgets/hourly_forecast_card.dart';
import 'package:simple_weather/widgets/weather_details_card.dart';
import 'package:simple_weather/widgets/weather_warning_card.dart';

class WeatherContentView extends StatelessWidget {
  final LiveWeatherModel weather;
  final List<DailyWeatherModel>? dailyForecast;
  final List<HourlyWeatherModel>? hourlyForecast;
  final List<WeatherWarningModel>? warnings;
  final AirQualityModel? airQuality;
  final CityModel city;
  final Future<void> Function() onRefresh;

  const WeatherContentView({
    super.key,
    required this.weather,
    this.dailyForecast,
    this.hourlyForecast,
    this.warnings,
    this.airQuality,
    required this.city,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Container(
        color: Colors.blue.shade50,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (warnings != null && warnings!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    WeatherWarningCard(warnings: warnings!),
                    const SizedBox(height: 20),
                  ],
                  WeatherDetailsCard(weather: weather),
                  const SizedBox(height: 20),
                  if (airQuality != null) ...[
                    AirQualityCard(airQuality: airQuality!),
                    const SizedBox(height: 20),
                  ],
                  if (hourlyForecast != null && hourlyForecast!.isNotEmpty) ...[
                    HourlyForecastCard(hourlyForecast: hourlyForecast!),
                    const SizedBox(height: 20),
                  ],
                  if (dailyForecast != null && dailyForecast!.isNotEmpty) ...[
                    DailyForecastCard(
                      dailyForecast: dailyForecast!,
                      currentCity: city,
                    ),
                    const SizedBox(height: 20),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
