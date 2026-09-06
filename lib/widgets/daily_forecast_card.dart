import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/city_model.dart';

import '../utils/date_utils.dart';
import '../utils/weather_icon_utils.dart';
import 'weather_card_surface.dart';

class DailyForecastCard extends StatelessWidget {
  final List<DailyWeatherModel> dailyForecast;
  final CityModel currentCity;
  final ValueChanged<DateTime> onDayTap;

  const DailyForecastCard({
    super.key,
    required this.dailyForecast,
    required this.currentCity,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final days = dailyForecast.take(10).toList();
    final temperatures =
        days
            .expand((d) => [d.minTemp, d.maxTemp])
            .where((t) => t.isFinite)
            .toList()
          ..sort();
    final low = temperatures.isEmpty ? 0.0 : temperatures.first;
    final span =
        temperatures.isEmpty
            ? 1.0
            : (temperatures.last - low).clamp(1.0, double.infinity);
    return WeatherCardSurface(
      child: InkWell(
        borderRadius: WeatherCardSurface.borderRadius,
        onTap: () => onDayTap(days.first.date),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${days.length}日天气预报',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final day in days) ...[
                Divider(
                  height: 1,
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
                InkWell(
                  onTap: () => onDayTap(day.date),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            WeatherDateUtils.getDateText(day.date),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(
                          WeatherIconUtils.getWeatherIcon(
                            day.icon,
                            filled: true,
                          ),
                          size: 24,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _temp(day.minTemp),
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final valid =
                                  day.minTemp.isFinite && day.maxTemp.isFinite;
                              final start =
                                  valid
                                      ? ((day.minTemp - low) / span).clamp(
                                        0.0,
                                        1.0,
                                      )
                                      : 0.0;
                              final length =
                                  valid
                                      ? ((day.maxTemp - day.minTemp) / span)
                                          .clamp(0.0, 1.0)
                                      : 0.0;
                              return SizedBox(
                                height: 6,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: colors.onSurface.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    if (valid)
                                      Positioned(
                                        left: constraints.maxWidth * start,
                                        width: (constraints.maxWidth * length)
                                            .clamp(3.0, constraints.maxWidth),
                                        top: 0,
                                        bottom: 0,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFFC64A),
                                                Color(0xFFF18438),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _temp(day.maxTemp),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _temp(double value) => value.isFinite ? '${value.round()}°' : '--';
}
