import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/weather_icon_utils.dart';
import 'weather_card_surface.dart';

class HourlyForecastCard extends StatelessWidget {
  final List<HourlyWeatherModel> hourlyForecast;
  final VoidCallback onTap;
  const HourlyForecastCard({
    super.key,
    required this.hourlyForecast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Keep the home-card preview compact; the drawer receives all 240 hours.
    final hours = hourlyForecast.take(24).toList();
    final wet =
        hours
            .where((hour) => hour.precip.isFinite && hour.precip > 0)
            .firstOrNull;
    final summary = wet == null ? '逐小时天气预报' : '${wet.time.hour}时有降水预报。';
    return GestureDetector(
      onTap: onTap,
      child: WeatherCardSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: hours.isEmpty ? null : onTap,

              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Semantics(
                      label: '查看天气趋势',
                      child: const Icon(Icons.chevron_right, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: .3),
            ),
            if (hours.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂无逐小时预报'),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    hours.map((hour) {
                      final time = hour.time;
                      final label =
                          hour == hours.first
                              ? '现在'
                              : time.hour == 0
                              ? '${time.month}/${time.day}'
                              : '${time.hour}时';
                      return SizedBox(
                        width: 54,
                        child: Column(
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Icon(
                              WeatherIconUtils.getWeatherIcon(
                                hour.icon,
                                filled: true,
                              ),
                              size: 26,
                              color: colors.onSurface,
                            ),
                            SizedBox(
                              height: 22,
                              child: Text(
                                hour.pop != null &&
                                        hour.pop!.isFinite &&
                                        hour.pop! > 0
                                    ? '${hour.pop!.round()}%'
                                    : '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                            Text(
                              hour.temp.isFinite
                                  ? '${hour.temp.round()}°'
                                  : '--',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
