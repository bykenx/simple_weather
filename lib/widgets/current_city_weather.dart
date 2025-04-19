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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 天气信息
        CurrentWeatherInfo(
          weather: weather,
          dailyForecast: dailyForecast,
        ),
        // 城市指示器
        if (totalCities > 1)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalCities,
                (index) => GestureDetector(
                  onTap: () {
                    pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == index
                          ? Colors.blue
                          : Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 