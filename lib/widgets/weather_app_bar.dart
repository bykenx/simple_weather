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
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          // 获取当前 FlexibleSpaceBar 的高度
          final double currentExtent = constraints.biggest.height;
          // 计算 FlexibleSpaceBar 高度的百分比（从完全展开到完全折叠）
          final double deltaExtent =
              MediaQuery.of(context).padding.top + kToolbarHeight;
          final double scrollPercent =
              (constraints.maxHeight - currentExtent) /
                  (constraints.maxHeight - deltaExtent);

          // 使用更渐进的不透明度变化计算
          // 在滚动的前60%不改变不透明度，之后快速改变
          final double titleOpacity = scrollPercent < 0.6
              ? 0.0
              : ((scrollPercent - 0.6) / 0.4).clamp(
                  0.0,
                  1.0,
                );

          // 反向计算内容的不透明度
          final double contentOpacity = 1.0 - titleOpacity;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            centerTitle: true,
            title: AnimatedOpacity(
              opacity: titleOpacity,
              duration: const Duration(
                milliseconds: 150,
              ),
              child: Text(
                cityName ?? '',
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade200,
                    Colors.blue.shade50,
                  ],
                ),
              ),
              child: weather != null
                  ? AnimatedOpacity(
                      opacity: contentOpacity,
                      duration: const Duration(
                        milliseconds: 150,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 100,
                        ),
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