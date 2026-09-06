import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/moon_orientation_utils.dart';
import 'weather_card_surface.dart';
import 'moon_renderers.dart';

class WeatherDetailsCard extends StatelessWidget {
  final LiveWeatherModel weather;
  final DailyWeatherModel? daily;
  final List<DailyWeatherModel> dailyForecast;
  final double? latitude;
  final double? longitude;
  const WeatherDetailsCard({
    super.key,
    required this.weather,
    this.daily,
    this.dailyForecast = const [],
    this.latitude,
    this.longitude,
  });

  String _number(double? value, [String unit = '']) =>
      value != null && value.isFinite
          ? '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$unit'
          : '暂无数据';
  String _text(String? value) =>
      value == null || value.isEmpty ? '暂无数据' : value;

  ({String label, String value}) _nextMoonEvent() {
    final today = daily;
    if (today == null) return (label: '月落', value: '暂无数据');
    final now = DateTime.now();
    final moonset = _timeOnDate(today.date, today.moonset);
    if (moonset == null || now.isBefore(moonset)) {
      return (label: '月落', value: _text(today.moonset));
    }
    final next =
        dailyForecast
            .where((day) => day.date.isAfter(today.date))
            .where((day) => day.moonrise?.isNotEmpty == true)
            .firstOrNull;
    return (
      label: '下次月出',
      value:
          next == null
              ? '暂无数据'
              : '${next.date.month}月${next.date.day}日 ${next.moonrise}',
    );
  }

  DateTime? _timeOnDate(DateTime date, String? clock) {
    if (clock == null) return null;
    final parts = clock.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]), minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  double? _moonIllumination() {
    final current = daily?.moonPhaseAt(DateTime.now());
    if (current != null) return current.illumination;
    final date = daily?.date;
    if (date == null) return null;
    final age = _lunarAge(date);
    return (50 * (1 - math.cos(2 * math.pi * age / 29.53058867)))
        .roundToDouble();
  }

  double get _moonPhaseProgress {
    final current = daily?.moonPhaseAt(DateTime.now());
    if (current != null) return current.value;
    final date = daily?.date ?? DateTime.now();
    return _lunarAge(date) / 29.53058867;
  }

  String get _moonPhaseName {
    final current = daily?.moonPhaseAt(DateTime.now());
    return current?.name.isNotEmpty == true
        ? current!.name
        : _text(daily?.moonPhase);
  }

  String _nextFullMoon() {
    final forecastFullMoon =
        dailyForecast
            .where((day) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              return !day.date.isBefore(today);
            })
            .where((day) => day.details?.astro['moonPhase'] == 'full-moon')
            .firstOrNull;
    final date =
        forecastFullMoon?.date ?? _calculatedNextFullMoon(DateTime.now());
    return '${date.month}月${date.day}日';
  }

  double _lunarAge(DateTime date) {
    final reference = DateTime.utc(2000, 1, 6, 18, 14);
    final sample = DateTime.utc(date.year, date.month, date.day, 12);
    final days = sample.difference(reference).inMinutes / 1440;
    return ((days % 29.53058867) + 29.53058867) % 29.53058867;
  }

  DateTime _calculatedNextFullMoon(DateTime now) {
    final reference = DateTime.utc(2000, 1, 6, 18, 14);
    const cycle = 29.53058867;
    final days = now.toUtc().difference(reference).inMinutes / 1440;
    final cycleNumber = ((days / cycle) - .5).ceil();
    return reference
        .add(Duration(minutes: ((cycleNumber + .5) * cycle * 1440).round()))
        .toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final difference = weather.feelsLike - weather.temp;
    final moonEvent = _nextMoonEvent();
    final orientation = approximateMoonOrientation(
      time: DateTime.now(),
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 300 &&
            MediaQuery.textScalerOf(context).scale(16) < 25;
        Widget pair(Widget left, Widget right) =>
            columns
                ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 12),
                      Expanded(child: right),
                    ],
                  ),
                )
                : Column(children: [left, const SizedBox(height: 12), right]);
        return Column(
          children: [
            pair(
              _tile(
                context,
                Icons.thermostat,
                '体感温度',
                _number(weather.feelsLike, '°'),
                note:
                    !difference.isFinite
                        ? '暂无数据'
                        : difference.abs() < 1
                        ? '与实际气温接近。'
                        : difference > 0
                        ? '体感温度更高。'
                        : '体感温度更低。',
              ),
              _tile(
                context,
                Icons.wb_sunny_outlined,
                '紫外线指数',
                _number(daily?.uvIndex),
                note: '当日最大值预报',
                graphic:
                    daily?.uvIndex?.isFinite == true
                        ? _scale(context, daily!.uvIndex! / 11)
                        : null,
              ),
            ),
            const SizedBox(height: 12),
            _wide(
              context,
              Icons.air,
              '风',
              [
                _row(
                  '风力',
                  weather.windScale.isEmpty ? '暂无数据' : '${weather.windScale}级',
                ),
                _row('风速', _number(weather.windSpeed / 3.6, ' 米/秒')),
                _row(
                  '方向',
                  '${_text(weather.windDir)} ${_number(double.tryParse(weather.wind360), '°')}',
                ),
              ],
              graphic: SizedBox(
                width: 128,
                height: 128,
                child: CustomPaint(
                  painter: _CompassPainter(
                    Theme.of(context).colorScheme.onSurface,
                    double.tryParse(weather.wind360),
                  ),
                  child: Center(
                    child: Text(
                      weather.windScale.isEmpty
                          ? '--'
                          : '${weather.windScale}\n级',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            pair(
              _tile(
                context,
                Icons.wb_twilight,
                '日落',
                _text(daily?.sunset),
                note: '日出 ${_text(daily?.sunrise)}',
                graphic: SizedBox(
                  height: 40,
                  child: CustomPaint(
                    size: const Size(double.infinity, 40),
                    painter: _SunPathPainter(
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              _tile(
                context,
                Icons.water_drop_outlined,
                '降水',
                _number(daily?.precip, ' 毫米'),
                note:
                    '${daily?.details == null ? '今日预报' : '白天与夜间累计预报'}\n白天概率 ${_number(daily?.details?.daytime.probability, '%')}\n夜间概率 ${_number(daily?.details?.nighttime.probability, '%')}\n最近一小时 ${_number(weather.precip, '毫米')}',
              ),
            ),
            const SizedBox(height: 12),
            pair(
              _tile(
                context,
                Icons.visibility_outlined,
                '能见度',
                _number(weather.vis, ' 公里'),
                note: '当前能见度',
              ),
              _tile(
                context,
                Icons.waves,
                '湿度',
                _number(weather.humidity, '%'),
                note: '露点 ${_number(weather.dew, '°')}',
              ),
            ),
            const SizedBox(height: 12),
            _wide(
              context,
              Icons.nightlight_round,
              _moonPhaseName,
              [
                _row('照射范围', _number(_moonIllumination(), '%')),
                _row(moonEvent.label, moonEvent.value),
                _row('下次满月', _nextFullMoon()),
              ],
              graphic: SizedBox.square(
                dimension: 128,
                child: MoonPhaseSphere(
                  phase: _moonPhaseProgress,
                  librationLongitude: orientation.longitude,
                  librationLatitude: orientation.latitude,
                  orientation: orientation.rotation,
                ),
              ),
            ),
            const SizedBox(height: 12),
            pair(
              _averageTemperatureTile(context),
              _tile(
                context,
                Icons.speed,
                '气压',
                _number(weather.pressure),
                note: '百帕',
                graphic: SizedBox(
                  height: 56,
                  child: CustomPaint(
                    size: const Size(double.infinity, 56),
                    painter: _PressurePainter(
                      Theme.of(context).colorScheme.onSurface,
                      weather.pressure,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _averageTemperatureTile(BuildContext context) {
    final average = daily?.details?.averageTemperature;
    final difference =
        average != null && average.isFinite && weather.temp.isFinite
            ? weather.temp - average
            : null;
    final differenceText =
        difference == null
            ? '暂无数据'
            : '${difference >= 0 ? '+' : '−'}${difference.abs().round()}°';
    final comparison =
        difference == null
            ? '暂无可比较数据'
            : difference.abs() < 0.5
            ? '接近今日预报平均温度'
            : '${difference > 0 ? '高于' : '低于'}今日预报平均温度';

    return WeatherCardSurface(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 190),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading(context, Icons.trending_up, '平均'),
            const SizedBox(height: 14),
            Text(
              differenceText,
              style: TextStyle(
                fontSize: difference == null ? 22 : 30,
                height: 1.15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              comparison,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '今天',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最高 ${_number(daily?.maxTemp, '°')}'),
                    Text('平均 ${_number(average, '°')}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    required String note,
    Widget? graphic,
  }) => WeatherCardSurface(
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context, icon, label),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: value == '暂无数据' ? 22 : 30,
              height: 1.15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          if (graphic != null) ...[graphic, const SizedBox(height: 16)],
          Text(note, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    ),
  );

  Widget _wide(
    BuildContext context,
    IconData icon,
    String label,
    List<Widget> rows, {
    required Widget graphic,
  }) => WeatherCardSurface(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context, icon, label),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder:
                (context, constraints) =>
                    constraints.maxWidth < 280 ||
                            MediaQuery.textScalerOf(context).scale(16) >= 25
                        ? Column(
                          children: [
                            Column(children: rows),
                            const SizedBox(height: 16),
                            graphic,
                          ],
                        )
                        : Row(
                          children: [
                            Expanded(child: Column(children: rows)),
                            const SizedBox(width: 16),
                            graphic,
                          ],
                        ),
          ),
        ],
      ),
    ),
  );

  Widget _heading(BuildContext context, IconData icon, String label) => Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );
  Widget _scale(BuildContext context, double value) => SizedBox(
    height: 7,
    child: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [
                Colors.green,
                Colors.yellow,
                Colors.orange,
                Colors.red,
                Colors.purple,
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment(value.clamp(0.0, 1.0) * 2 - 1, 0),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CompassPainter extends CustomPainter {
  final Color color;
  final double? degrees;
  _CompassPainter(this.color, this.degrees);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 14;
    final pen =
        Paint()
          ..color = color.withValues(alpha: .35)
          ..strokeWidth = 1;
    for (var i = 0; i < 60; i++) {
      final a = i * math.pi / 30;
      final direction = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(
        center + direction * r,
        center + direction * (r - (i % 5 == 0 ? 7 : 4)),
        pen,
      );
    }
    for (var i = 0; i < 4; i++) {
      final text = TextPainter(
        text: TextSpan(
          text: ['北', '东', '南', '西'][i],
          style: TextStyle(color: color, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final a = i * math.pi / 2;
      final point = center + Offset(math.sin(a), -math.cos(a)) * (r + 9);
      text.paint(canvas, point - Offset(text.width / 2, text.height / 2));
    }
    if (degrees != null && degrees!.isFinite) {
      final a = degrees! * math.pi / 180;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(
        center + dir * (r - 15),
        center + dir * (r - 2),
        Paint()
          ..color = color
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      color != old.color || degrees != old.degrees;
}

class _SunPathPainter extends CustomPainter {
  final Color color;
  _SunPathPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(0, size.height * .8)
          ..cubicTo(
            size.width * .3,
            -size.height * .15,
            size.width * .7,
            -size.height * .15,
            size.width,
            size.height * .8,
          );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(0, size.height * .8),
      Offset(size.width, size.height * .8),
      Paint()..color = color.withValues(alpha: .2),
    );
  }

  @override
  bool shouldRepaint(covariant _SunPathPainter old) => color != old.color;
}

class _PressurePainter extends CustomPainter {
  final Color color;
  final double pressure;
  _PressurePainter(this.color, this.pressure);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final r = math.min(size.width / 2 - 4, size.height - 3);
    for (var i = 0; i <= 24; i++) {
      final angle = math.pi + i / 24 * math.pi;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * r,
        center + direction * (r - 7),
        Paint()
          ..color = color.withValues(alpha: .3)
          ..strokeWidth = 2,
      );
    }
    if (pressure.isFinite) {
      final a = math.pi + ((pressure - 950) / 100).clamp(0.0, 1.0) * math.pi;
      final direction = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + direction * (r - 10),
        center + direction * (r + 1),
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PressurePainter old) =>
      color != old.color || pressure != old.pressure;
}
