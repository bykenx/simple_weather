import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import '../utils/weather_icon.dart';
import 'weather_detail_sheet.dart';

class TemperatureChartTooltip extends StatelessWidget {
  final HourlyWeatherModel hour;
  final bool feelsLike;

  const TemperatureChartTooltip({
    super.key,
    required this.hour,
    required this.feelsLike,
  });

  static TextStyle _smallStyle({String? fontFamily, Color? color}) => TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    color: color,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: .5,
    height: 1.2,
  );

  static TextStyle _temperatureStyle({String? fontFamily, Color? color}) =>
      TextStyle(
        inherit: false,
        fontFamily: fontFamily,
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: .5,
        height: 1.2,
      );

  static double heightFor({
    required HourlyWeatherModel hour,
    required bool feelsLike,
    required double width,
    required TextScaler textScaler,
    String? fontFamily,
  }) {
    final availableWidth = width < 0 ? 0.0 : width;
    final smallStyle = _smallStyle(fontFamily: fontFamily);
    final temperatureStyle = _temperatureStyle(fontFamily: fontFamily);

    Size measure(String text, TextStyle style, {bool singleLine = false}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textScaler: textScaler,
      )..layout(maxWidth: singleLine ? double.infinity : availableWidth);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final time =
        '${hour.time.hour.toString().padLeft(2, '0')}:'
        '${hour.time.minute.toString().padLeft(2, '0')}';
    final timeHeight = measure(time, smallStyle).height;
    final valueSize = measure(
      detailNumber(feelsLike ? hour.feelsLike : hour.temp, '°'),
      temperatureStyle,
      singleLine: !feelsLike,
    );
    if (feelsLike) {
      final comparisonHeight =
          measure('实际温度：${detailNumber(hour.temp, '°')}', smallStyle).height;
      return timeHeight + 4 + valueSize.height + 2 + comparisonHeight;
    }
    final rowWidth = 20 + 6 + valueSize.width;
    final rowHeight = valueSize.height < 20 ? 20.0 : valueSize.height;
    final scale = rowWidth > availableWidth ? availableWidth / rowWidth : 1.0;
    return timeHeight + 4 + rowHeight * scale;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fontFamily = DefaultTextStyle.of(context).style.fontFamily;
    final smallStyle = _smallStyle(
      fontFamily: fontFamily,
      color: colors.onSurfaceVariant,
    );
    final temperatureStyle = _temperatureStyle(
      fontFamily: fontFamily,
      color: colors.onSurface,
    );
    final time =
        '${hour.time.hour.toString().padLeft(2, '0')}:'
        '${hour.time.minute.toString().padLeft(2, '0')}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: smallStyle, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        if (feelsLike) ...[
          Text(
            detailNumber(hour.feelsLike, '°'),
            style: temperatureStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '实际温度：${detailNumber(hour.temp, '°')}',
            style: smallStyle,
            textAlign: TextAlign.center,
          ),
        ] else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  WeatherIconUtils.getWeatherIcon(hour.icon, filled: true),
                  size: 20,
                  applyTextScaling: false,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(detailNumber(hour.temp, '°'), style: temperatureStyle),
              ],
            ),
          ),
      ],
    );
  }
}
