import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/widgets/current_city_weather.dart';

class WeatherAppBar extends StatelessWidget {
  final LiveWeatherModel? weather;
  final DailyWeatherModel? dailyForecast;
  final String? cityName;
  final int currentCityIndex;
  final int totalCities;
  final PageController pageController;
  final Function() onSettingsPressed;

  const WeatherAppBar({
    super.key,
    this.weather,
    this.dailyForecast,
    this.cityName,
    required this.currentCityIndex,
    required this.totalCities,
    required this.pageController,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue.shade50,
      elevation: 0,
      title: null,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double currentExtent = constraints.biggest.height;
          final double deltaExtent =
              MediaQuery.of(context).padding.top + kToolbarHeight;
          final double scrollPercent =
              1 - (currentExtent - deltaExtent) / (420 - deltaExtent);

          var titleOpacity =
              scrollPercent < 0.5 ? 0.0 : (scrollPercent - 0.5) / 0.5;
          var contentOpacity = scrollPercent < 0.5 ? 1 - scrollPercent : 0.0;

          titleOpacity = max(min(titleOpacity, 1.0), 0.0);
          contentOpacity = max(min(contentOpacity, 1.0), 0.0);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            centerTitle: true,
            title: AnimatedOpacity(
              opacity: titleOpacity,
              duration: const Duration(milliseconds: 150),
              child: Text(
                cityName ?? '',
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade200, Colors.blue.shade50],
                ),
              ),
              child:
                  weather != null
                      ? AnimatedOpacity(
                        opacity: contentOpacity,
                        duration: const Duration(milliseconds: 150),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: CurrentCityWeather(
                            cityName: cityName ?? '',
                            weather: weather!,
                            dailyForecast: dailyForecast,
                            currentIndex: currentCityIndex,
                            totalCities: totalCities,
                            pageController: pageController,
                          ),
                        ),
                      )
                      : SizedBox.shrink(),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }
}
