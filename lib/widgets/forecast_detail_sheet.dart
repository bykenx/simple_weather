import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/weather_icon_utils.dart';
import 'weather_detail_sheet.dart';

DateTime forecastDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class ForecastDetailSheet extends StatefulWidget {
  final List<DailyWeatherModel> days;
  final List<HourlyWeatherModel> hours;
  final DateTime initialDate;
  final String cityName;
  const ForecastDetailSheet({
    super.key,
    required this.days,
    required this.hours,
    required this.initialDate,
    required this.cityName,
  });
  @override
  State<ForecastDetailSheet> createState() => _ForecastDetailSheetState();
}

class _ForecastDetailSheetState extends State<ForecastDetailSheet> {
  late final List<DateTime> dates;
  late DateTime selected;
  bool feelsLike = false;
  final dateController = ScrollController();
  static const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  void initState() {
    super.initState();
    dates =
        (widget.days.isNotEmpty
                ? widget.days.map((day) => forecastDate(day.date)).toSet()
                : widget.hours.map((hour) => forecastDate(hour.time)).toSet())
            .take(10)
            .toList()
          ..sort();
    final initial = forecastDate(widget.initialDate);
    selected =
        dates.contains(initial) ? initial : (dates.firstOrNull ?? initial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !dateController.hasClients) return;
      dateController.jumpTo(
        (dates.indexOf(selected) * 64.0 - 100).clamp(
          0.0,
          dateController.position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hours =
        widget.hours.where((h) => forecastDate(h.time) == selected).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    final day =
        widget.days
            .where((day) => forecastDate(day.date) == selected)
            .firstOrNull;
    final selectedTemperatures =
        hours
            .map((hour) => feelsLike ? hour.feelsLike : hour.temp)
            .whereType<double>()
            .where((value) => value.isFinite)
            .toList();
    final icon = day?.icon ?? hours.firstOrNull?.icon;
    final probabilities =
        hours
            .map((h) => h.pop)
            .whereType<double>()
            .where((v) => v.isFinite)
            .toList();
    final probability =
        probabilities.isEmpty ? null : probabilities.reduce(math.max);
    final precipitation = day?.precip ?? _sum(hours.map((h) => h.precip));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.cityName, style: TextStyle(color: colors.onSurfaceVariant)),
        const SizedBox(height: 12),
        _datePicker(colors),
        Center(
          child: Text(
            '${selected.year}年${selected.month}月${selected.day}日 星期${weekdays[selected.weekday - 1]}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              feelsLike && selectedTemperatures.isNotEmpty
                  ? '${detailNumber(selectedTemperatures.reduce(math.max), '°C')} / ${detailNumber(selectedTemperatures.reduce(math.min), '°C')}'
                  : day == null
                  ? detailNumber(hours.firstOrNull?.temp, '°C')
                  : '${detailNumber(day.maxTemp, '°C')} / ${detailNumber(day.minTemp, '°C')}',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (icon != null)
              Icon(
                WeatherIconUtils.getWeatherIcon(icon, filled: true),
                size: 40,
              ),
          ],
        ),
        Text(
          day == null
              ? detailText(hours.firstOrNull?.text)
              : '${detailText(day.description)} · 最高 / 最低',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        if (hours.every(
          (hour) => (feelsLike ? hour.feelsLike : hour.temp)?.isFinite != true,
        ))
          DetailPanel(
            child: Text(
              feelsLike ? '暂无数据：该日期没有可用的逐小时体感温度。' : '暂无数据：该日期没有可用的逐小时温度预报。',
            ),
          )
        else
          ForecastTemperatureChart(
            key: ValueKey((selected, feelsLike)),
            hours: hours,
            feelsLike: feelsLike,
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('实际气温')),
              ButtonSegment(value: true, label: Text('体感温度')),
            ],
            selected: {feelsLike},
            onSelectionChanged:
                (values) => setState(() => feelsLike = values.first),
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          feelsLike ? '体感温度反映湿度、日照和风影响下的冷暖感受。' : '实际气温，仅展示接口覆盖的时段。',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        Text(
          '降雨概率',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '周${weekdays[selected.weekday - 1]}概率：${detailNumber(probability, '%')}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        if (probabilities.isEmpty)
          const DetailPanel(child: Text('暂无逐小时降雨概率数据。'))
        else
          PrecipitationProbabilityChart(hours: hours),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            '每日降雨概率通常比逐小时概率高。',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        DetailSection(
          title: '降雨总量',
          child: Row(
            children: [
              Icon(Icons.water_drop, color: colors.primary, size: 18),
              const SizedBox(width: 14),
              const Expanded(child: Text('降雨', style: TextStyle(fontSize: 18))),
              Text(
                detailNumber(precipitation, ' 毫米'),
                style: TextStyle(fontSize: 20, color: colors.primary),
              ),
            ],
          ),
        ),
        DetailSection(
          title: '每日摘要',
          child: Text(
            _dailySummary(hours, precipitation, probability),
            style: const TextStyle(fontSize: 18, height: 1.55),
          ),
        ),
        const DetailSection(
          title: '关于体感温度',
          child: Text(
            '体感温度传达身体感觉到的冷暖，与实际温度可能不尽相同。它会受到湿度、风速和日照等因素影响。',
            style: TextStyle(fontSize: 18, height: 1.55),
          ),
        ),
        const SizedBox(height: 20),
        Text('天气数据来源：和风天气', style: TextStyle(color: colors.onSurfaceVariant)),
      ],
    );
  }

  Widget _datePicker(ColorScheme colors) => SingleChildScrollView(
    controller: dateController,
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final date in dates)
          SizedBox(
            width: 64,
            child: Semantics(
              selected: date == selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => selected = date),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text('周${weekdays[date.weekday - 1]}'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              date == selected
                                  ? colors.primary
                                  : Colors.transparent,
                        ),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 22,
                            color:
                                date == selected
                                    ? colors.onPrimary
                                    : colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class ForecastTemperatureChart extends StatefulWidget {
  final List<HourlyWeatherModel> hours;
  final bool feelsLike;
  const ForecastTemperatureChart({
    super.key,
    required this.hours,
    required this.feelsLike,
  });
  @override
  State<ForecastTemperatureChart> createState() =>
      _ForecastTemperatureChartState();
}

class _ForecastTemperatureChartState extends State<ForecastTemperatureChart> {
  int? selected;

  @override
  Widget build(BuildContext context) {
    final hours =
        widget.hours
            .where(
              (hour) =>
                  (widget.feelsLike ? hour.feelsLike : hour.temp)?.isFinite ==
                  true,
            )
            .toList();
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            void select(double x) {
              final target = (x / (constraints.maxWidth - 42)).clamp(0, 1) * 24;
              var index = 0;
              for (var i = 1; i < hours.length; i++) {
                if ((_hourPosition(hours[i]) - target).abs() <
                    (_hourPosition(hours[index]) - target).abs()) {
                  index = i;
                }
              }
              setState(() => selected = index);
            }

            return Semantics(
              label: '所选日期${widget.feelsLike ? '体感' : '实际'}气温曲线，点击查看小时数值',
              child: GestureDetector(
                onTapDown: (details) => select(details.localPosition.dx),
                onHorizontalDragUpdate:
                    (details) => select(details.localPosition.dx),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 220),
                  painter: _TemperaturePainter(
                    hours: hours,
                    feelsLike: widget.feelsLike,
                    selected: selected,
                    foreground: colors.onSurfaceVariant,
                    grid: colors.outlineVariant,
                    line:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFFFAB40)
                            : const Color(0xFFAF5200),
                    fontFamily:
                        Theme.of(context).textTheme.bodySmall?.fontFamily,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          selected == null
              ? '点击曲线查看${widget.feelsLike ? '体感' : '实际'}温度（°C）'
              : '${hours[selected!].time.hour}时 · ${detailNumber(widget.feelsLike ? hours[selected!].feelsLike : hours[selected!].temp, '°C')}',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

double _hourPosition(HourlyWeatherModel hour) =>
    hour.time.hour + hour.time.minute / 60;

class _TemperaturePainter extends CustomPainter {
  final List<HourlyWeatherModel> hours;
  final int? selected;
  final Color foreground, grid, line;
  final String? fontFamily;
  final bool feelsLike;
  _TemperaturePainter({
    required this.hours,
    required this.feelsLike,
    required this.selected,
    required this.foreground,
    required this.grid,
    required this.line,
    this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hours.isEmpty) return;
    double value(HourlyWeatherModel hour) =>
        feelsLike ? hour.feelsLike! : hour.temp;
    final low = hours.map(value).reduce(math.min).floorToDouble() - 2;
    final high = hours.map(value).reduce(math.max).ceilToDouble() + 2;
    final width = size.width - 42, height = size.height - 30;
    final style = TextStyle(
      color: foreground,
      fontSize: 12,
      fontFamily: fontFamily,
    );
    void label(String value, Offset point) {
      final text = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, point);
    }

    for (var i = 0; i <= 4; i++) {
      final y = height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        Paint()..color = grid.withValues(alpha: .5),
      );
      label('${(high - (high - low) * i / 4).round()}°', Offset(width + 8, y));
    }
    for (final hour in const [0, 6, 12, 18]) {
      final x = width * hour / 24;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        Paint()..color = grid.withValues(alpha: .3),
      );
      label('$hour时', Offset(x, height + 10));
    }
    final points =
        hours
            .map(
              (hour) => Offset(
                width * _hourPosition(hour) / 24,
                height * (high - value(hour)) / (high - low),
              ),
            )
            .toList();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final before = points[i - 1],
          next = points[i],
          middle = (before.dx + next.dx) / 2;
      path.cubicTo(middle, before.dy, middle, next.dy, next.dx, next.dy);
    }
    final fill =
        Path.from(path)
          ..lineTo(points.last.dx, height)
          ..lineTo(points.first.dx, height)
          ..close();
    canvas.drawPath(fill, Paint()..color = line.withValues(alpha: .16));
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    if (selected != null) {
      final point = points[selected!];
      canvas.drawLine(
        Offset(point.dx, 0),
        Offset(point.dx, height),
        Paint()..color = foreground.withValues(alpha: .5),
      );
      canvas.drawCircle(point, 6, Paint()..color = line);
      canvas.drawCircle(point, 3, Paint()..color = foreground);
    }
  }

  @override
  bool shouldRepaint(covariant _TemperaturePainter old) => true;
}

class PrecipitationProbabilityChart extends StatelessWidget {
  final List<HourlyWeatherModel> hours;
  const PrecipitationProbabilityChart({super.key, required this.hours});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '所选日期逐小时降雨概率曲线',
      child: CustomPaint(
        size: const Size(double.infinity, 250),
        painter: _ProbabilityPainter(
          hours: hours,
          foreground: colors.onSurfaceVariant,
          grid: colors.outlineVariant,
          line: const Color(0xFF35C9F4),
          fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
        ),
      ),
    );
  }
}

class _ProbabilityPainter extends CustomPainter {
  final List<HourlyWeatherModel> hours;
  final Color foreground, grid, line;
  final String? fontFamily;
  _ProbabilityPainter({
    required this.hours,
    required this.foreground,
    required this.grid,
    required this.line,
    this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const right = 48.0, top = 8.0, bottom = 28.0;
    final width = size.width - right, height = size.height - top - bottom;
    final labelStyle = TextStyle(
      color: foreground,
      fontSize: 12,
      fontFamily: fontFamily,
    );
    for (var value = 0; value <= 100; value += 20) {
      final y = top + height * (1 - value / 100);
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        Paint()..color = grid.withValues(alpha: .65),
      );
      _label(canvas, '$value%', Offset(width + 10, y - 8), labelStyle);
    }
    for (final hour in const [0, 6, 12, 18]) {
      final x = width * hour / 24;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + height),
        Paint()..color = grid.withValues(alpha: .5),
      );
      _label(
        canvas,
        '$hour时',
        Offset(x + (hour == 0 ? 8 : -10), size.height - 20),
        labelStyle,
      );
    }
    final points = <Offset>[];
    for (final hour in hours) {
      if (hour.pop?.isFinite != true) continue;
      points.add(
        Offset(
          width * (hour.time.hour + hour.time.minute / 60) / 24,
          top + height * (1 - hour.pop!.clamp(0, 100) / 100),
        ),
      );
    }
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final area =
        Path.from(path)
          ..lineTo(points.last.dx, top + height)
          ..lineTo(points.first.dx, top + height)
          ..close();
    canvas.drawPath(area, Paint()..color = line.withValues(alpha: .22));
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _label(Canvas canvas, String value, Offset point, TextStyle style) {
    final text = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, point);
  }

  @override
  bool shouldRepaint(covariant _ProbabilityPainter old) =>
      old.hours != hours || old.foreground != foreground || old.grid != grid;
}

double? _sum(Iterable<double?> values) {
  final valid = values.whereType<double>().where((v) => v.isFinite).toList();
  return valid.isEmpty
      ? null
      : valid.fold<double>(0, (sum, value) => sum + value);
}

String _dailySummary(
  List<HourlyWeatherModel> hours,
  double? precipitation,
  double? probability,
) {
  if (hours.isEmpty) return '该日期暂无可用的逐小时天气预报。';
  final descriptions = <String, int>{};
  for (final text in hours
      .map((h) => h.text)
      .where((text) => text.isNotEmpty)) {
    descriptions[text] = (descriptions[text] ?? 0) + 1;
  }
  final description =
      descriptions.isEmpty
          ? '天气状况暂无数据'
          : descriptions.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
  final temperatures =
      hours.map((h) => h.temp).where((v) => v.isFinite).toList();
  final range =
      temperatures.isEmpty
          ? ''
          : '，气温 ${temperatures.reduce(math.min).round()}° 至 ${temperatures.reduce(math.max).round()}°';
  final rain =
      probability == null
          ? '，降雨概率暂无数据'
          : probability <= 0
          ? '，预计没有降雨'
          : '，最高降雨概率 ${probability.round()}%，预计降雨总量${precipitation == null ? '暂无数据' : ' ${detailNumber(precipitation, ' 毫米')}'}';
  return '当天以$description为主$range$rain。';
}
