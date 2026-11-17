import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_model.dart';
import '../utils/url.dart';
import '../utils/weather_time.dart';
import '../utils/warning_colors.dart';
import '../utils/weather_icon.dart';
import 'weather_detail_sheet.dart';

Future<void> showWeatherWarningSheet(
  BuildContext context,
  WeatherWarningModel warning, {
  Duration? utcOffset,
}) => showWeatherDetailSheet(
  context,
  title: '天气预警',
  icon: Icons.warning_amber_rounded,
  child: WeatherWarningSheet(warning: warning, utcOffset: utcOffset),
);

class WeatherWarningSheet extends StatelessWidget {
  final WeatherWarningModel warning;
  final Duration? utcOffset;
  const WeatherWarningSheet({super.key, required this.warning, this.utcOffset});

  String _formatDateTime(DateTime value) => DateFormat(
    'yyyy-MM-dd HH:mm',
  ).format(WeatherTimeUtils.atOffset(value, warning.utcOffset ?? utcOffset));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = WarningColorsUtils.background(
      warning.severityColor,
      rgba: warning.alertColor,
    );
    final foreground = WarningColorsUtils.foreground(
      warning.severityColor,
      rgba: warning.alertColor,
      surface: colors.surface,
    );
    final iconForeground = WarningColorsUtils.foreground(
      warning.severityColor,
      rgba: warning.alertColor,
      surface: colors.surfaceContainerHigh,
    );
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
                  WeatherIconUtils.getWeatherIcon(
                    warning.icon.isNotEmpty ? warning.icon : warning.type,
                    filled: true,
                  ),
                  size: 32,
                  color: iconForeground,
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
        if (warning.instruction.trim().isNotEmpty)
          DetailSection(
            title: '防御指南',
            child: SelectableText(
              warning.instruction,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.65),
            ),
          ),
        if (warning.attributions.isNotEmpty)
          DetailSection(
            title: '数据来源',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final attribution in warning.attributions)
                  _attribution(context, attribution),
              ],
            ),
          ),
      ],
    );
  }

  Widget _attribution(BuildContext context, String value) {
    final uri = Uri.tryParse(value.trim());
    final isLink =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    if (!isLink) return SelectableText(value);
    return TextButton(
      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
      onPressed: () async {
        try {
          await UrlUtils.launchUrlInBrowser(uri.toString());
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('暂时无法打开数据来源')));
          }
        }
      },
      child: Text(value),
    );
  }
}
