import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';
import 'package:simple_weather/routes/app_routes.dart';
import 'package:simple_weather/utils/date_utils.dart';

class DailyForecastCard extends StatelessWidget {
  final List<DailyWeatherModel> dailyForecast;
  final CityModel currentCity;

  const DailyForecastCard({
    super.key,
    required this.dailyForecast,
    required this.currentCity,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).cardColor.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.extendedForecast,
            arguments: currentCity,
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(3, (index) {
                final day = dailyForecast[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          WeatherDateUtils.getDateText(day.date),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Icon(
                        WeatherIconUtils.getWeatherIcon(day.icon, filled: true),
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          day.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        '${day.minTemp.toStringAsFixed(1)} ~ ${day.maxTemp.toStringAsFixed(1)}℃',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
} 
