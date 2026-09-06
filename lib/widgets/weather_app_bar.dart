import 'dart:math';
import 'package:flutter/services.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 290.0,
      toolbarHeight: 88,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: null,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double currentExtent = constraints.biggest.height;
          final double deltaExtent = MediaQuery.of(context).padding.top + 88;
          final double scrollPercent =
              1 - (currentExtent - deltaExtent) / (290 - 88);

          var titleOpacity =
              scrollPercent < 0.5 ? 0.0 : (scrollPercent - 0.5) / 0.5;
          var contentOpacity = scrollPercent < 0.5 ? 1 - scrollPercent : 0.0;

          titleOpacity = max(min(titleOpacity, 1.0), 0.0);
          contentOpacity = max(min(contentOpacity, 1.0), 0.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Only shade the pinned toolbar, fading out before its lower edge.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: min(currentExtent, deltaExtent + 24),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.7, 1],
                        colors: [
                          colorScheme.surface.withValues(alpha: titleOpacity),
                          colorScheme.surface.withValues(
                            alpha: titleOpacity * 0.96,
                          ),
                          colorScheme.surface.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                centerTitle: true,
                expandedTitleScale: 1,
                titlePadding: const EdgeInsets.fromLTRB(52, 0, 52, 12),
                title: AnimatedOpacity(
                  opacity: titleOpacity,
                  duration: const Duration(milliseconds: 150),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cityName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (weather != null)
                        Text(
                          '${weather!.temp.isFinite ? weather!.temp.round() : '--'}°  |  ${weather!.text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                background:
                    weather != null
                        ? AnimatedOpacity(
                          opacity: contentOpacity,
                          duration: const Duration(milliseconds: 150),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.paddingOf(context).top + 32,
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
            ],
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
