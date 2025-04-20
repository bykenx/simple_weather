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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
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
                          WeatherIconUtils.getWeatherIcon(day.icon),
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            day.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          '${day.minTemp.toStringAsFixed(1)}° ~ ${day.maxTemp.toStringAsFixed(1)}°',
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
      ),
    );
  }
} 