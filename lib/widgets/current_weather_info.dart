import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';

class CurrentWeatherInfo extends StatelessWidget {
  final LiveWeatherModel weather;
  final DailyWeatherModel? dailyForecast;

  const CurrentWeatherInfo({
    super.key,
    required this.weather,
    this.dailyForecast,
  });

  String _temperature(double? value) =>
      value != null && value.isFinite ? '${value.round()}°' : '--';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _temperature(weather.temp),
          style: const TextStyle(
            fontSize: 88,
            fontWeight: FontWeight.w200,
            height: 1.05,
            letterSpacing: -4,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          children: [
            _extreme('最\n高', dailyForecast?.maxTemp),
            _extreme('最\n低', dailyForecast?.minTemp),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          weather.text,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _extreme(String label, double? temperature) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(fontSize: 14, height: 1.05)),
      const SizedBox(width: 5),
      Text(
        _temperature(temperature),
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300),
      ),
    ],
  );
}
