import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import 'weather_detail_sheet.dart';

class HourlyForecastFacts extends StatelessWidget {
  final List<HourlyWeatherModel> hours;
  const HourlyForecastFacts({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    final precipitation = _sum(hours.map((hour) => hour.precip));
    final precipitationProbability = _maximum(hours.map((hour) => hour.pop));
    final precipitationIntensity = _maximum(
      hours.map((hour) => hour.precipitationIntensity),
    );
    final types =
        hours
            .map((hour) => hour.precipitationType)
            .whereType<String>()
            .where((type) => type != '无降水')
            .toSet();

    return Column(
      children: [
        DetailSection(
          title: '降水',
          child: _readings([
            ('累计降水量', detailNumber(precipitation, ' mm')),
            ('最高小时降水概率', detailNumber(precipitationProbability, '%')),
            ('最大降水强度', detailNumber(precipitationIntensity, ' mm/h')),
            ('降水类型', types.isEmpty ? '无降水' : types.join('、')),
          ]),
        ),
        DetailSection(
          title: '气温',
          child: _readings([
            ('平均实际温度', detailNumber(_average(hours.map((h) => h.temp)), '°C')),
            (
              '平均体感温度',
              detailNumber(_average(hours.map((h) => h.feelsLike)), '°C'),
            ),
            ('平均露点温度', detailNumber(_average(hours.map((h) => h.dew)), '°C')),
          ]),
        ),
        DetailSection(
          title: '风',
          child: _readings([
            (
              '最大风速',
              detailNumber(_maximum(hours.map((h) => h.windSpeed)), ' km/h'),
            ),
            ('最大阵风', detailNumber(_maximum(hours.map((h) => h.gust)), ' km/h')),
            ('主要风向', _mode(hours.map((h) => h.windDir))),
            ('最高风力', _maximumScale(hours)),
          ]),
        ),
        DetailSection(
          title: '空气与能见度',
          child: _readings([
            ('平均湿度', detailNumber(_average(hours.map((h) => h.humidity)), '%')),
            ('平均云量', detailNumber(_average(hours.map((h) => h.cloud)), '%')),
            (
              '平均海平面气压',
              detailNumber(_average(hours.map((h) => h.pressure)), ' hPa'),
            ),
            (
              '最低能见度',
              detailNumber(_minimum(hours.map((h) => h.visibility)), ' km'),
            ),
            (
              '最高紫外线指数',
              detailNumber(_maximum(hours.map((h) => h.uvIndex)), ''),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _readings(List<(String, String)> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < rows.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        Text('${rows[index].$1}：${rows[index].$2}'),
      ],
    ],
  );

  double? _average(Iterable<double?> values) {
    final valid =
        values.whereType<double>().where((value) => value.isFinite).toList();
    return valid.isEmpty ? null : valid.reduce((a, b) => a + b) / valid.length;
  }

  double? _sum(Iterable<double?> values) {
    final valid =
        values.whereType<double>().where((value) => value.isFinite).toList();
    return valid.isEmpty
        ? null
        : valid.fold<double>(0, (sum, value) => sum + value);
  }

  double? _maximum(Iterable<double?> values) {
    final valid =
        values.whereType<double>().where((value) => value.isFinite).toList();
    return valid.isEmpty ? null : valid.reduce(math.max);
  }

  double? _minimum(Iterable<double?> values) {
    final valid =
        values.whereType<double>().where((value) => value.isFinite).toList();
    return valid.isEmpty ? null : valid.reduce(math.min);
  }

  String _mode(Iterable<String> values) {
    final counts = <String, int>{};
    for (final value in values.where((value) => value.isNotEmpty)) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    if (counts.isEmpty) return '暂无数据';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String _maximumScale(List<HourlyWeatherModel> hours) {
    final scales =
        hours
            .map((hour) => int.tryParse(hour.windScale))
            .whereType<int>()
            .toList();
    return scales.isEmpty ? '暂无数据' : '${scales.reduce(math.max)}级';
  }
}
