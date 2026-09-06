import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/widgets/current_weather_info.dart';

class CurrentCityWeather extends StatelessWidget {
  final String cityName;
  final LiveWeatherModel weather;
  final DailyWeatherModel? dailyForecast;
  final int currentIndex;
  final int totalCities;
  final PageController pageController;

  const CurrentCityWeather({
    super.key,
    required this.cityName,
    required this.weather,
    this.dailyForecast,
    required this.currentIndex,
    required this.totalCities,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 城市名称
        Text(
          cityName,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w400),
        ),
        // 天气信息
        CurrentWeatherInfo(weather: weather, dailyForecast: dailyForecast),
      ],
    );
  }
}
