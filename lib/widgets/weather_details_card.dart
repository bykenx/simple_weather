import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/precipitation_summary.dart';
import '../models/weather_model.dart';
import 'precipitation_summary_card.dart';
import 'weather_card_surface.dart';
import 'weather_metric_card.dart';
import 'weather_metric_dials.dart';

class WeatherDetailsCard extends StatelessWidget {
  final LiveWeatherModel weather;
  final DailyWeatherModel? daily;
  final PrecipitationSummary? precipitation;
  final VoidCallback? onPrecipitationTap;

  const WeatherDetailsCard({
    super.key,
    required this.weather,
    this.daily,
    this.precipitation,
    this.onPrecipitationTap,
  });

  String _number(double? value, [String unit = '']) =>
      value != null && value.isFinite
          ? '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$unit'
          : '暂无数据';

  String _text(String? value) =>
      value == null || value.isEmpty ? '暂无数据' : value;

  @override
  Widget build(BuildContext context) {
    final difference = weather.feelsLike - weather.temp;
    final average = daily?.details?.averageTemperature;
    final comparison =
        average != null && average.isFinite && weather.temp.isFinite
            ? (weather.temp - average).round()
            : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = math.max(
          1.0,
          MediaQuery.textScalerOf(context).scale(16) / 16,
        );
        final columns =
            constraints.maxWidth >= 300 * textScale && textScale < 1.5;
        Widget pair(Widget left, Widget right) =>
            columns
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 12),
                    Expanded(child: right),
                  ],
                )
                : Column(children: [left, const SizedBox(height: 12), right]);
        return Column(
          children: [
            pair(
              _tile(
                Icons.thermostat,
                '体感温度',
                _number(weather.feelsLike, '°'),
                notes: [
                  if (!difference.isFinite)
                    '暂无可比较数据'
                  else if (difference.abs() < 1)
                    '与实际气温接近'
                  else
                    '比实际气温${difference > 0 ? '高' : '低'} ${_number(difference.abs(), '°')}',
                ],
              ),
              _tile(
                Icons.wb_sunny_outlined,
                '紫外线指数',
                _number(daily?.uvIndex),
                notes: [_uvDescription(daily?.uvIndex), '今日最高预报'],
              ),
            ),
            const SizedBox(height: 12),
            _windCard(context),
            const SizedBox(height: 12),
            pair(
              _tile(
                Icons.wb_twilight,
                '日落',
                _text(daily?.sunset),
                notes: ['日出 ${_text(daily?.sunrise)}'],
              ),
              PrecipitationSummaryCard(
                summary:
                    precipitation ?? PrecipitationSummary.fromHours(const []),
                onTap: onPrecipitationTap,
              ),
            ),
            const SizedBox(height: 12),
            pair(
              _tile(
                Icons.visibility_outlined,
                '能见度',
                _number(weather.vis),
                unit: weather.vis.isFinite ? '公里' : null,
                notes: const ['当前能见度'],
              ),
              _tile(
                Icons.waves,
                '湿度',
                _number(weather.humidity, '%'),
                notes: ['露点 ${_number(weather.dew, '°')}'],
              ),
            ),
            const SizedBox(height: 12),
            pair(
              _tile(
                Icons.thermostat,
                '气温对比',
                comparison == null
                    ? '暂无数据'
                    : '${comparison > 0
                        ? '+'
                        : comparison < 0
                        ? '−'
                        : ''}${comparison.abs()}°',
                notes: [comparison == null ? '暂无可比较数据' : '较今日预报均温'],
              ),
              WeatherMetricCard(
                icon: Icons.speed,
                title: '气压',
                child: Center(child: PressureDial(pressure: weather.pressure)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String value, {
    String? unit,
    required List<String> notes,
  }) => WeatherMetricCard(
    icon: icon,
    title: title,
    child: WeatherMetricValue(value: value, unit: unit, notes: notes),
  );

  String _uvDescription(double? value) {
    if (value == null || !value.isFinite || value < 0) return '暂无等级数据';
    if (value < 3) return '低';
    if (value < 6) return '中等';
    if (value < 8) return '高';
    if (value < 11) return '很高';
    return '极高';
  }

  Widget _windCard(BuildContext context) {
    final factor = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(16) / 16,
    );
    final heading = const WeatherMetricHeading(icon: Icons.air, title: '风');
    final facts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_text(weather.windDir)}${weather.windScale.isEmpty ? '' : ' ${weather.windScale} 级'}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Text(
          '风速 ${_number(weather.windSpeed / 3.6, '米/秒')}',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    Widget dial(double dimension) => SizedBox.square(
      dimension: dimension,
      child: WindDirectionDial(
        degrees: double.tryParse(weather.wind360),
        grade: weather.windScale,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (factor == 1 && constraints.maxWidth >= 300) {
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 128),
            child: WeatherCardSurface(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [heading, const SizedBox(height: 8), facts],
                      ),
                    ),
                    const SizedBox(width: 16),
                    dial(112),
                  ],
                ),
              ),
            ),
          );
        }
        final diagram = dial(112 * factor);
        return WeatherCardSurface(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: 12),
                if (constraints.maxWidth >= 360 * factor && factor < 1.5)
                  Row(
                    children: [
                      Expanded(child: facts),
                      const SizedBox(width: 16),
                      diagram,
                    ],
                  )
                else ...[
                  facts,
                  const SizedBox(height: 16),
                  Center(child: diagram),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
