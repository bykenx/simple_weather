import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';

class WeatherDetailsCard extends StatelessWidget {
  final LiveWeatherModel weather;

  const WeatherDetailsCard({super.key, required this.weather});

  String _formatNumber(double value, {int fractionDigits = 0}) {
    if (value.isNaN || value.isInfinite) return '--';
    return value.toStringAsFixed(fractionDigits);
  }

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
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 16) / 2;
              final windScaleText =
                  weather.windScale.trim().isEmpty ? '--' : '${weather.windScale}级';
              final windDirText =
                  weather.windDir.trim().isEmpty ? '--' : weather.windDir;
              return Wrap(
                spacing: 16,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildWeatherDetail(
                      context,
                      label: windDirText,
                      value: windScaleText,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildWeatherDetail(
                      context,
                      label: '相对湿度',
                      value: '${_formatNumber(weather.humidity)}%',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildWeatherDetail(
                      context,
                      label: '体感温度',
                      value: '${_formatNumber(weather.feelsLike)}°',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildWeatherDetail(
                      context,
                      label: '能见度',
                      value: '${_formatNumber(weather.vis)}km',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildWeatherDetail(
                      context,
                      label: '降水量',
                      value: '${_formatNumber(weather.precip, fractionDigits: 1)}mm',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildWeatherDetail(
                      context,
                      label: '大气压',
                      value: '${_formatNumber(weather.pressure)}hPa',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
