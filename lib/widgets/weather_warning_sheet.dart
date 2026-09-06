import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_model.dart';
import '../utils/warning_colors.dart';
import '../utils/weather_icon_utils.dart';
import 'weather_detail_sheet.dart';

Future<void> showWeatherWarningSheet(
  BuildContext context,
  WeatherWarningModel warning,
) => showWeatherDetailSheet(
  context,
  title: '天气预警',
  icon: Icons.warning_amber_rounded,
  child: WeatherWarningSheet(warning: warning),
);

class WeatherWarningSheet extends StatelessWidget {
  final WeatherWarningModel warning;
  const WeatherWarningSheet({super.key, required this.warning});

  String _formatDateTime(DateTime value) =>
      DateFormat('yyyy-MM-dd HH:mm').format(value);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = WarningColors.background(warning.severityColor);
    final foreground = WarningColors.foreground(warning.severityColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  WeatherIconUtils.getWeatherIcon(warning.type, filled: true),
                  size: 32,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warning.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(warning.pubTime),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                warning.typeName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: foreground,
                ),
              ),
            ),
            if (warning.sender.isNotEmpty)
              Text(
                warning.sender,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SelectableText(
          warning.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65),
        ),
      ],
    );
  }
}
