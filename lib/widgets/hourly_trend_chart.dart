import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class HourlyTrendChart extends StatefulWidget {
  final List<HourlyWeatherModel> hours;
  const HourlyTrendChart({super.key, required this.hours});
  @override
  State<HourlyTrendChart> createState() => _HourlyTrendChartState();
}

class _HourlyTrendChartState extends State<HourlyTrendChart> {
  bool _rain = false;
  int? _selected;
  @override
  void didUpdateWidget(covariant HourlyTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hours != widget.hours) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final hours = widget.hours;
    final values =
        hours.map((h) {
          final value = _rain ? h.pop : h.temp;
          return value != null &&
                  value.isFinite &&
                  (!_rain || (value >= 0 && value <= 100))
              ? value
              : null;
        }).toList();
    final unit = _rain ? '%' : '°C';
    final selected = _selected;
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('温度'),
                selected: !_rain,
                onSelected: (_) => setState(() => _rain = false),
              ),
              ChoiceChip(
                label: const Text('降水概率'),
                selected: _rain,
                onSelected: (_) => setState(() => _rain = true),
              ),
            ],
          ),
          if (values.every((v) => v == null))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('暂无趋势数据')),
            )
          else
            LayoutBuilder(
              builder:
                  (context, constraints) => GestureDetector(
                    onTapUp: (details) {
                      final fraction = ((details.localPosition.dx - 42) /
                              math.max(1, constraints.maxWidth - 54))
                          .clamp(0.0, 1.0);
                      setState(
                        () =>
                            _selected = (fraction * (hours.length - 1)).round(),
                      );
                    },
                    child: Semantics(
                      label: _rain ? '24 小时降水概率趋势，点击查看数值' : '24 小时温度趋势，点击查看数值',
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, 170),
                        painter: _TrendPainter(
                          values: values,
                          hours: hours,
                          rain: _rain,
                          line: color.primary,
                          text: color.onSurfaceVariant,
                          grid: color.outlineVariant,
                          selected: selected,
                        ),
                      ),
                    ),
                  ),
            ),
          Text(
            selected == null || selected >= hours.length
                ? '点击图表查看数值（$unit）'
                : '${_time(hours[selected].time)} · ${values[selected]?.toStringAsFixed(_rain ? 0 : 1) ?? '--'}$unit',
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

String _time(DateTime time) {
  final local = time.toLocal();
  return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:00';
}

class _TrendPainter extends CustomPainter {
  final List<double?> values;
  final List<HourlyWeatherModel> hours;
  final bool rain;
  final Color line, text, grid;
  final int? selected;
  _TrendPainter({
    required this.values,
    required this.hours,
    required this.rain,
    required this.line,
    required this.text,
    required this.grid,
    this.selected,
  });
  void _label(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: TextStyle(color: text, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final finite = values.whereType<double>().toList();
    if (finite.isEmpty) return;
    double low = rain ? 0 : finite.reduce(math.min);
    double high = rain ? 100 : finite.reduce(math.max);
    if (low == high) {
      low -= 1;
      high += 1;
    }
    const left = 42.0, top = 12.0;
    final width = math.max(1.0, size.width - 54);
    const height = 120.0;
    for (var i = 0; i <= 2; i++) {
      final y = top + height * i / 2;
      canvas.drawLine(
        Offset(left, y),
        Offset(left + width, y),
        Paint()..color = grid,
      );
      _label(
        canvas,
        '${(high - (high - low) * i / 2).toStringAsFixed(0)}${rain ? '%' : '°'}',
        Offset(0, y - 6),
      );
    }
    Offset point(int i, double v) => Offset(
      left + (values.length == 1 ? width / 2 : width * i / (values.length - 1)),
      top + (high - v) / (high - low) * height,
    );
    Offset? previous;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        previous = null;
        continue;
      }
      final p = point(i, value);
      if (previous != null) {
        canvas.drawLine(
          previous,
          p,
          Paint()
            ..color = line
            ..strokeWidth = 2,
        );
      }
      canvas.drawCircle(p, selected == i ? 5 : 2.5, Paint()..color = line);
      previous = p;
    }
    final indices = {0, (hours.length - 1) ~/ 2, hours.length - 1};
    for (final i in indices) {
      final x =
          left +
          (hours.length == 1 ? width / 2 : width * i / (hours.length - 1));
      final local = hours[i].time.toLocal();
      _label(
        canvas,
        '${local.hour}:00',
        Offset((x - 14).clamp(left, size.width - 32), 140),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}
