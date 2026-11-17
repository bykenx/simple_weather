import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../utils/weather_time.dart';
import '../utils/weather_icon.dart';
import '../utils/forecast.dart';
import 'weather_detail_sheet.dart';
import 'temperature_chart_tooltip.dart';

DateTime forecastDate(DateTime value) => WeatherTimeUtils.date(value);

class ForecastDetailSheet extends StatefulWidget {
  final List<DailyWeatherModel> days;
  final List<HourlyWeatherModel> hours;
  final DateTime initialDate;
  final String cityName;
  final Duration? utcOffset;
  final LiveWeatherModel? weather;
  final DateTime? startDate;
  const ForecastDetailSheet({
    super.key,
    required this.days,
    required this.hours,
    required this.initialDate,
    required this.cityName,
    this.utcOffset,
    this.weather,
    this.startDate,
  });
  @override
  State<ForecastDetailSheet> createState() => _ForecastDetailSheetState();
}

class _ForecastDetailSheetState extends State<ForecastDetailSheet> {
  late List<DateTime> dates;
  late DateTime selected;
  bool feelsLike = false;
  HourlyWeatherModel? _selectedHour;
  late final Timer _timeRefresh;
  final dateController = ScrollController();
  late final PageController _temperaturePages;
  late final PageController _precipitationPages;
  bool _syncingPages = false;
  static const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  void initState() {
    super.initState();
    _timeRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(_syncSelection);
    });
    dates = _calendarDates();
    final initial = forecastDate(widget.initialDate);
    selected =
        dates.contains(initial) ? initial : (dates.firstOrNull ?? initial);
    final initialPage = dates.indexOf(selected);
    _temperaturePages = PageController(initialPage: initialPage);
    _precipitationPages = PageController(initialPage: initialPage);
    _temperaturePages.addListener(
      () => _syncPagePosition(_temperaturePages, _precipitationPages),
    );
    _precipitationPages.addListener(
      () => _syncPagePosition(_precipitationPages, _temperaturePages),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealSelectedDate(animate: false);
    });
  }

  void _revealSelectedDate({bool animate = true}) {
    if (!mounted || !dateController.hasClients) return;
    final position = dateController.position;
    final target = (dates.indexOf(selected) * 64.0 +
            32 -
            position.viewportDimension / 2)
        .clamp(0.0, position.maxScrollExtent);
    if (animate && !MediaQuery.disableAnimationsOf(context)) {
      dateController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      dateController.jumpTo(target);
    }
  }

  void _selectDate(DateTime date) {
    final page = dates.indexOf(date);
    if (page < 0 || !_temperaturePages.hasClients) return;
    if (_selectedHour != null) setState(() => _selectedHour = null);
    if (MediaQuery.disableAnimationsOf(context)) {
      _temperaturePages.jumpToPage(page);
    } else {
      _temperaturePages.animateToPage(
        page,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _pageChanged(int index) {
    if (index < 0 || index >= dates.length || dates[index] == selected) return;
    setState(() {
      selected = dates[index];
      _selectedHour = null;
    });
    _revealSelectedDate();
  }

  void _syncPagePosition(PageController source, PageController target) {
    if (_syncingPages || !source.hasClients || !target.hasClients) return;
    if (!source.position.hasViewportDimension ||
        !target.position.hasViewportDimension ||
        !target.position.hasContentDimensions) {
      return;
    }
    final page = source.page;
    if (page == null) return;
    final position = target.position;
    final offset = (page * position.viewportDimension).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((position.pixels - offset).abs() < .01) return;
    // Mirror fractional page positions, not just the final selected date, so
    // both charts follow the finger and the settling animation together.
    _syncingPages = true;
    try {
      target.jumpTo(offset);
      // jumpTo starts a ballistic settle; only the leading pager should
      // settle, otherwise the follower would snap back between drag frames.
      position.hold(() {});
    } finally {
      _syncingPages = false;
    }
  }

  Widget _chartPager({
    required Key key,
    required PageController controller,
    required double height,
    required Widget Function(DateTime date) builder,
  }) => SizedBox(
    key: key,
    height: height,
    child: LayoutBuilder(
      builder:
          (_, constraints) => OverflowBox(
            // Include both outer margins in the page stride while keeping each
            // chart at its original width and horizontal position when settled.
            minWidth: constraints.maxWidth + 2 * weatherDetailHorizontalPadding,
            maxWidth: constraints.maxWidth + 2 * weatherDetailHorizontalPadding,
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (notification) {
                if (notification.dragDetails != null && _selectedHour != null) {
                  setState(() => _selectedHour = null);
                }
                return false;
              },
              child: PageView.builder(
                controller: controller,
                physics: const ClampingScrollPhysics(),
                onPageChanged: _pageChanged,
                itemCount: dates.length,
                itemBuilder:
                    (_, index) => KeyedSubtree(
                      key: ValueKey(dates[index]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: weatherDetailHorizontalPadding,
                        ),
                        child: builder(dates[index]),
                      ),
                    ),
              ),
            ),
          ),
    ),
  );

  List<HourlyWeatherModel> _hoursForDate(DateTime date, DateTime now) =>
      widget.hours
          .where(
            (hour) =>
                forecastDate(hour.time) == date &&
                _isUpcomingHour(hour, now, widget.utcOffset),
          )
          .toList()
        ..sort(
          (a, b) => _forecastInstant(
            a,
            widget.utcOffset,
          ).compareTo(_forecastInstant(b, widget.utcOffset)),
        );

  List<DateTime> _calendarDates() {
    final now = WeatherTimeUtils.atOffset(DateTime.now(), widget.utcOffset);
    final today = forecastDate(now);
    final requestedStart = forecastDate(widget.startDate ?? today);
    final start = requestedStart.isBefore(today) ? today : requestedStart;
    return List.generate(
      10,
      (index) => DateTime.utc(start.year, start.month, start.day + index),
    );
  }

  @override
  void didUpdateWidget(covariant ForecastDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  void _syncSelection() {
    final previousStart = dates.firstOrNull;
    final previousSelected = selected;
    dates = _calendarDates();
    if (!dates.contains(selected)) {
      final initial = forecastDate(widget.initialDate);
      selected = dates.contains(initial) ? initial : dates.first;
      _selectedHour = null;
    } else if (_selectedHour != null) {
      final now = WeatherTimeUtils.atOffset(DateTime.now(), widget.utcOffset);
      _selectedHour =
          widget.hours
              .where(
                (hour) =>
                    _sameForecastHour(hour, _selectedHour!) &&
                    _isUpcomingHour(hour, now, widget.utcOffset) &&
                    (feelsLike ? hour.feelsLike : hour.temp)?.isFinite == true,
              )
              .firstOrNull;
    }
    if (previousStart != dates.firstOrNull || previousSelected != selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_temperaturePages.hasClients) {
          _temperaturePages.jumpToPage(dates.indexOf(selected));
        }
        _revealSelectedDate();
      });
    }
  }

  @override
  void dispose() {
    _timeRefresh.cancel();
    _temperaturePages.dispose();
    _precipitationPages.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = WeatherTimeUtils.atOffset(DateTime.now(), widget.utcOffset);
    final today = forecastDate(now);
    final hours = _hoursForDate(selected, now);
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
    final currentHour =
        hours.where((hour) => !hour.time.isAfter(now)).lastOrNull ??
        hours.firstOrNull;
    final showLive = selected == today && widget.weather != null;
    final liveTemperature =
        showLive
            ? (feelsLike ? widget.weather!.feelsLike : widget.weather!.temp)
            : null;
    final currentTemperature =
        liveTemperature?.isFinite == true
            ? liveTemperature
            : (feelsLike ? currentHour?.feelsLike : currentHour?.temp);
    final icon =
        showLive ? widget.weather!.icon : currentHour?.icon ?? day?.icon;
    final hourlyMaximum =
        selectedTemperatures.isEmpty
            ? null
            : selectedTemperatures.reduce(math.max);
    final hourlyMinimum =
        selectedTemperatures.isEmpty
            ? null
            : selectedTemperatures.reduce(math.min);
    final maximum =
        !feelsLike && day?.maxTemp.isFinite == true
            ? day!.maxTemp
            : hourlyMaximum;
    final minimum =
        !feelsLike && day?.minTemp.isFinite == true
            ? day!.minTemp
            : hourlyMinimum;
    final probabilities =
        hours
            .map((h) => h.pop)
            .whereType<double>()
            .where(validPrecipitationProbability)
            .toList();
    final probability =
        probabilities.isEmpty ? null : probabilities.reduce(math.max);
    final dailyPrecipitation = day?.precip;
    final hasDailyPrecipitation =
        dailyPrecipitation != null &&
        dailyPrecipitation.isFinite &&
        dailyPrecipitation >= 0;
    final precipitation =
        hasDailyPrecipitation
            ? dailyPrecipitation
            : _sum(hours.map((h) => h.precip));
    final intensities =
        hours
            .map((hour) => hour.precipitationIntensity)
            .whereType<double>()
            .where((value) => value.isFinite && value >= 0)
            .toList();
    final maximumIntensity =
        intensities.isEmpty ? null : intensities.reduce(math.max);
    final remaining = selected == today;
    final probabilityLabel = remaining ? '剩余时段最高逐小时概率' : '当日最高逐小时概率';
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
        const Padding(
          padding: EdgeInsets.only(top: 15.5),
          child: Divider(height: 1, thickness: 1),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            final rangeText =
                '最高 ${detailNumber(maximum, '°')} 最低 ${detailNumber(minimum, '°')}';
            final selectedHour = _selectedHour;
            final showIndicator = selectedHour != null;
            final indicatorWidth = _temperatureTooltipWidth(
              constraints.maxWidth,
              scaler,
            );
            final indicatorLeft =
                selectedHour == null
                    ? 0.0
                    : _temperatureTooltipLeft(
                      selectedHour,
                      constraints.maxWidth,
                      indicatorWidth,
                    );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: constraints.maxWidth,
                  child: Stack(
                    children: [
                      Visibility(
                        visible: !showIndicator,
                        maintainSize: true,
                        maintainState: true,
                        maintainAnimation: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Count the divider's lower spacing as part of the
                            // full area where the temperature callout centers.
                            const SizedBox(height: 15.5),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  detailNumber(currentTemperature, '°'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (icon != null)
                                  Icon(
                                    WeatherIconUtils.getWeatherIcon(
                                      icon,
                                      filled: true,
                                    ),
                                    size: 24,
                                  ),
                              ],
                            ),
                            Text(
                              rangeText,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      if (showIndicator)
                        Positioned(
                          left: indicatorLeft,
                          top: 0,
                          bottom: 0,
                          width: indicatorWidth,
                          child: IgnorePointer(
                            child: Center(
                              child: TemperatureChartTooltip(
                                hour: selectedHour,
                                feelsLike: feelsLike,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _chartPager(
                  key: const ValueKey('temperature-date-swipe'),
                  controller: _temperaturePages,
                  height: 220,
                  builder:
                      (date) => ForecastTemperatureChart(
                        key: ValueKey((date, feelsLike)),
                        hours: _hoursForDate(date, now),
                        feelsLike: feelsLike,
                        date: date,
                        now: now,
                        utcOffset: widget.utcOffset,
                        selectedHour: date == selected ? selectedHour : null,
                        showTooltip: false,
                        onHourSelected: (hour) {
                          if (date == selected) {
                            setState(() => _selectedHour = hour);
                          }
                        },
                      ),
                ),
              ],
            );
          },
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
                (values) => setState(() {
                  feelsLike = values.first;
                  _selectedHour = null;
                }),
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '降水概率',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$probabilityLabel：${detailNumber(probability, '%')}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        _chartPager(
          key: const ValueKey('precipitation-date-swipe'),
          controller: _precipitationPages,
          height: 250,
          builder:
              (date) => PrecipitationProbabilityChart(
                hours: _hoursForDate(date, now),
                utcOffset: widget.utcOffset,
              ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            '以上为逐小时降水概率，不代表全天发生降水的概率。',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        DetailSection(
          title: '降水明细',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _precipitationReading(
                hasDailyPrecipitation ? '白天与夜间累计' : '已获取时段累计',
                detailNumber(precipitation, ' 毫米'),
              ),
              if (day?.details != null) ...[
                _precipitationReading(
                  '白天降水概率',
                  detailNumber(day!.details!.daytime.probability, '%'),
                ),
                _precipitationReading(
                  '夜间降水概率',
                  detailNumber(day.details!.nighttime.probability, '%'),
                ),
              ],
              _precipitationReading(
                '已获取时段最大强度',
                detailNumber(maximumIntensity, ' 毫米/小时'),
              ),
              _precipitationReading('降水类型', _precipitationTypes(hours)),
              if (showLive)
                _precipitationReading(
                  '最近一小时实况',
                  detailNumber(widget.weather!.precip, ' 毫米'),
                ),
            ],
          ),
        ),
        DetailSection(
          title: remaining ? '剩余时段摘要' : '每日摘要',
          child: Text(
            _dailySummary(hours, probability, remaining: remaining),
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
              button: true,
              label:
                  '${date.month}月${date.day}日 星期${weekdays[date.weekday - 1]}',
              selected: date == selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _selectDate(date),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(weekdays[date.weekday - 1]),
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

Widget _precipitationReading(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 12),
      Flexible(child: Text(value, textAlign: TextAlign.right)),
    ],
  ),
);

String _precipitationTypes(List<HourlyWeatherModel> hours) {
  final types =
      hours
          .map((hour) => hour.precipitationType)
          .whereType<String>()
          .where((type) => type.isNotEmpty && type != '未知')
          .toSet();
  if (types.isEmpty) return '暂无数据';
  if (types.length > 1) types.remove('无降水');
  return types.join('、');
}

String _temperatureEmptyMessage(bool feelsLike) =>
    feelsLike ? '暂无当日体感温度数据' : '暂无当日气温数据';

class _ForecastChartEmptyState extends StatelessWidget {
  final String message;

  const _ForecastChartEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder:
          (context, constraints) => IgnorePointer(
            child: ColoredBox(
              color: colors.surface.withValues(alpha: .35),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: math.max(0.0, constraints.maxWidth - 32),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class ForecastTemperatureChart extends StatefulWidget {
  final List<HourlyWeatherModel> hours;
  final bool feelsLike;
  final DateTime date;
  final DateTime now;
  final Duration? utcOffset;
  final HourlyWeatherModel? selectedHour;
  final bool showTooltip;
  final ValueChanged<HourlyWeatherModel?>? onHourSelected;
  const ForecastTemperatureChart({
    super.key,
    required this.hours,
    required this.feelsLike,
    required this.date,
    required this.now,
    this.utcOffset,
    this.selectedHour,
    this.showTooltip = true,
    this.onHourSelected,
  });
  @override
  State<ForecastTemperatureChart> createState() =>
      _ForecastTemperatureChartState();
}

double _temperatureTooltipWidth(double width, TextScaler scaler) =>
    math.min(math.max(0.0, width - 42), scaler.scale(156));

double _temperatureTooltipLeft(
  HourlyWeatherModel hour,
  double width,
  double tooltipWidth,
) =>
    ((width - 42) * _hourPosition(hour) / 24 - tooltipWidth / 2)
        .clamp(0.0, math.max(0.0, width - 42 - tooltipWidth))
        .toDouble();

Path _temperatureUnderlayPath(Size size, Rect covered) {
  final bounds = Offset.zero & size;
  final path = Path()..addRect(bounds);
  final overlap = covered.intersect(bounds);
  if (overlap.isEmpty) return path;
  return path
    ..fillType = PathFillType.evenOdd
    ..addRect(overlap);
}

class _ForecastTemperatureChartState extends State<ForecastTemperatureChart> {
  HourlyWeatherModel? _selectedHour;

  @override
  void didUpdateWidget(covariant ForecastTemperatureChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedHour != null && widget.selectedHour == null) {
      _selectedHour = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeline =
        widget.hours
            .where(
              (hour) =>
                  forecastDate(hour.time) == forecastDate(widget.date) &&
                  _isUpcomingHour(hour, widget.now, widget.utcOffset),
            )
            .toList()
          ..sort(
            (a, b) => _forecastInstant(
              a,
              widget.utcOffset,
            ).compareTo(_forecastInstant(b, widget.utcOffset)),
          );
    final runs = _temperatureRuns(timeline, widget.feelsLike, widget.utcOffset);
    final hours = runs.expand((run) => run).toList();
    final candidate = widget.selectedHour ?? _selectedHour;
    final selected =
        candidate == null
            ? null
            : hours
                .where((hour) => _sameForecastHour(hour, candidate))
                .firstOrNull;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    const plotHeight = 190.0, bottom = 30.0, right = 42.0;
    const chartHeight = plotHeight + bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = constraints.maxWidth - right;
        if (plotWidth <= 0) return const SizedBox.shrink();
        final plot = Rect.fromLTWH(0, 0, plotWidth, plotHeight);
        final tooltipWidth = _temperatureTooltipWidth(
          constraints.maxWidth,
          scaler,
        );
        final tooltipLeft =
            selected == null
                ? 0.0
                : _temperatureTooltipLeft(
                  selected,
                  constraints.maxWidth,
                  tooltipWidth,
                );
        final tooltipHeight =
            selected == null || !widget.showTooltip
                ? 0.0
                : TemperatureChartTooltip.heightFor(
                  hour: selected,
                  feelsLike: widget.feelsLike,
                  width: tooltipWidth,
                  textScaler: scaler,
                  fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                );
        final tooltipTop = -tooltipHeight - 8;

        void select(Offset position) {
          HourlyWeatherModel? hit;
          if (plot.contains(position)) {
            final target = (position.dx - plot.left) / plot.width * 24;
            for (final run in runs) {
              final firstX =
                  plot.left + plot.width * _hourPosition(run.first) / 24;
              final lastX =
                  plot.left + plot.width * _hourPosition(run.last) / 24;
              final isolated = run.length == 1;
              final inside =
                  isolated
                      ? (position.dx - firstX).abs() <=
                          math.min(12.0, plot.width / 48)
                      : position.dx >= firstX && position.dx <= lastX;
              if (!inside) continue;
              for (final hour in run) {
                if (hit == null ||
                    (_hourPosition(hour) - target).abs() <
                        (_hourPosition(hit) - target).abs()) {
                  hit = hour;
                }
              }
            }
          }
          if ((selected == null && hit == null) ||
              (selected != null &&
                  hit != null &&
                  _sameForecastHour(selected, hit))) {
            return;
          }
          setState(() => _selectedHour = hit);
          widget.onHourSelected?.call(hit);
        }

        return Semantics(
          label:
              runs.isEmpty
                  ? _temperatureEmptyMessage(widget.feelsLike)
                  : widget.feelsLike
                  ? '体感温度曲线，灰线为实际温度，点按或长按拖动查看时段，左右轻扫切换日期'
                  : '实际气温曲线，点按或长按拖动查看时段，左右轻扫切换日期',
          child: SizedBox(
            height: chartHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => select(details.localPosition),
                  onLongPressStart: (details) => select(details.localPosition),
                  onLongPressMoveUpdate:
                      (details) => select(details.localPosition),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, chartHeight),
                    painter: _TemperaturePainter(
                      runs: runs,
                      referenceRuns:
                          widget.feelsLike
                              ? _temperatureRuns(
                                timeline,
                                false,
                                widget.utcOffset,
                              )
                              : const [],
                      plot: plot,
                      feelsLike: widget.feelsLike,
                      selected: selected,
                      coveredByTooltip:
                          selected == null || !widget.showTooltip
                              ? Rect.zero
                              : Rect.fromLTWH(
                                tooltipLeft,
                                tooltipTop,
                                tooltipWidth,
                                tooltipHeight,
                              ),
                      foreground: colors.onSurfaceVariant,
                      grid: colors.outlineVariant,
                      reference: colors.onSurfaceVariant.withValues(alpha: .65),
                      dark: theme.brightness == Brightness.dark,
                      fontFamily: theme.textTheme.bodySmall?.fontFamily,
                    ),
                  ),
                ),
                if (runs.isEmpty)
                  Positioned.fromRect(
                    rect: plot,
                    child: _ForecastChartEmptyState(
                      message: _temperatureEmptyMessage(widget.feelsLike),
                    ),
                  ),
                if (selected != null && widget.showTooltip)
                  // Float over the existing high/low header without adding
                  // another row or moving the plot during selection.
                  Positioned(
                    left: tooltipLeft,
                    top: tooltipTop,
                    width: tooltipWidth,
                    height: tooltipHeight,
                    child: IgnorePointer(
                      child: OverflowBox(
                        minHeight: 0,
                        maxHeight: double.infinity,
                        alignment: Alignment.center,
                        child: TemperatureChartTooltip(
                          hour: selected,
                          feelsLike: widget.feelsLike,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

bool _sameForecastHour(HourlyWeatherModel first, HourlyWeatherModel second) =>
    first.time == second.time && first.utcOffset == second.utcOffset;

DateTime _forecastInstant(HourlyWeatherModel hour, Duration? offset) =>
    hour.time.subtract(hour.utcOffset ?? offset ?? Duration.zero);

bool _isUpcomingHour(
  HourlyWeatherModel hour,
  DateTime now,
  Duration? utcOffset,
) =>
    !_forecastInstant(
      hour,
      utcOffset,
    ).isBefore(now.subtract(utcOffset ?? Duration.zero));

double _hourPosition(HourlyWeatherModel hour) =>
    hour.time.hour + hour.time.minute / 60 + hour.time.second / 3600;

List<List<HourlyWeatherModel>> _temperatureRuns(
  List<HourlyWeatherModel> timeline,
  bool feelsLike,
  Duration? offset,
) => forecastRuns(
  timeline,
  value: (hour) => feelsLike ? hour.feelsLike : hour.temp,
  utcOffset: offset,
);

const _temperatureStops = [-20.0, 0.0, 10.0, 20.0, 25.0, 30.0, 35.0, 45.0];
const _lightTemperatureColors = [
  Color(0xFF5E35B1),
  Color(0xFF1565C0),
  Color(0xFF00838F),
  Color(0xFF2E7D32),
  Color(0xFFB77900),
  Color(0xFFEF6C00),
  Color(0xFFC62828),
  Color(0xFFAD1457),
];
const _darkTemperatureColors = [
  Color(0xFFB39DDB),
  Color(0xFF64B5F6),
  Color(0xFF4DD0E1),
  Color(0xFF81C784),
  Color(0xFFFFD54F),
  Color(0xFFFFB74D),
  Color(0xFFEF5350),
  Color(0xFFF06292),
];

Color _temperatureColor(double value, bool dark) {
  final colors = dark ? _darkTemperatureColors : _lightTemperatureColors;
  if (value <= _temperatureStops.first) return colors.first;
  for (var i = 1; i < _temperatureStops.length; i++) {
    if (value <= _temperatureStops[i]) {
      final fraction =
          (value - _temperatureStops[i - 1]) /
          (_temperatureStops[i] - _temperatureStops[i - 1]);
      return Color.lerp(colors[i - 1], colors[i], fraction)!;
    }
  }
  return colors.last;
}

class _TemperaturePainter extends CustomPainter {
  final List<List<HourlyWeatherModel>> runs, referenceRuns;
  final Rect plot;
  final Rect coveredByTooltip;
  final HourlyWeatherModel? selected;
  final Color foreground, grid, reference;
  final String? fontFamily;
  final bool feelsLike, dark;
  _TemperaturePainter({
    required this.runs,
    required this.referenceRuns,
    required this.plot,
    required this.coveredByTooltip,
    required this.feelsLike,
    required this.selected,
    required this.foreground,
    required this.grid,
    required this.reference,
    required this.dark,
    this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipPath(_temperatureUnderlayPath(size, coveredByTooltip));
    double value(HourlyWeatherModel hour) =>
        feelsLike ? hour.feelsLike! : hour.temp;
    final values = [
      for (final run in runs) ...run.map(value),
      for (final run in referenceRuns) ...run.map((hour) => hour.temp),
    ];
    final low =
        values.isEmpty ? 0.0 : values.reduce(math.min).floorToDouble() - 2;
    final high =
        values.isEmpty ? 1.0 : values.reduce(math.max).ceilToDouble() + 2;
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
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()..color = grid.withValues(alpha: .5),
      );
      if (values.isNotEmpty) {
        label(
          '${(high - (high - low) * i / 4).round()}°',
          Offset(plot.right + 8, y),
        );
      }
    }
    for (final hour in const [0, 6, 12, 18]) {
      final x = plot.left + plot.width * hour / 24;
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()..color = grid.withValues(alpha: .3),
      );
      label('$hour时', Offset(x, plot.bottom + 10));
    }
    Offset point(HourlyWeatherModel hour, double temperature) => Offset(
      plot.left + plot.width * _hourPosition(hour) / 24,
      plot.top + plot.height * (high - temperature) / (high - low),
    );
    Path pathFor(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final before = points[i - 1], next = points[i];
        final middle = (before.dx + next.dx) / 2;
        path.cubicTo(middle, before.dy, middle, next.dy, next.dx, next.dy);
      }
      return path;
    }

    final temperatures = [
      low,
      ..._temperatureStops.where(
        (temperature) => temperature > low && temperature < high,
      ),
      high,
    ];
    final stops =
        temperatures
            .map((temperature) => (temperature - low) / (high - low))
            .toList();
    final curveShader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors:
          temperatures
              .map((temperature) => _temperatureColor(temperature, dark))
              .toList(),
      stops: stops,
    ).createShader(plot);
    final areaShader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors:
          temperatures
              .map(
                (temperature) =>
                    _temperatureColor(temperature, dark).withValues(
                      alpha: .05 + .17 * (temperature - low) / (high - low),
                    ),
              )
              .toList(),
      stops: stops,
    ).createShader(plot);
    canvas.save();
    canvas.clipRect(plot.inflate(3));
    for (final run in referenceRuns) {
      final points = run.map((hour) => point(hour, hour.temp)).toList();
      canvas.drawPath(
        pathFor(points),
        Paint()
          ..color = reference
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
      if (points.length == 1) {
        canvas.drawCircle(points.first, 2, Paint()..color = reference);
      }
    }
    for (final run in runs) {
      final points = run.map((hour) => point(hour, value(hour))).toList();
      final path = pathFor(points);
      if (!feelsLike && points.length > 1) {
        final fill =
            Path.from(path)
              ..lineTo(points.last.dx, plot.bottom)
              ..lineTo(points.first.dx, plot.bottom)
              ..close();
        canvas.drawPath(fill, Paint()..shader = areaShader);
      }
      canvas.drawPath(
        path,
        Paint()
          ..shader = curveShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      if (points.length == 1) {
        canvas.drawCircle(
          points.first,
          3,
          Paint()..color = _temperatureColor(value(run.first), dark),
        );
      }
    }
    if (selected != null) {
      final selectedPoint = point(selected!, value(selected!));
      canvas.drawLine(
        Offset(selectedPoint.dx, plot.top),
        Offset(selectedPoint.dx, plot.bottom),
        Paint()
          ..color = foreground.withValues(alpha: .65)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        selectedPoint,
        5,
        Paint()..color = _temperatureColor(value(selected!), dark),
      );
      canvas.drawCircle(selectedPoint, 2.5, Paint()..color = foreground);
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TemperaturePainter old) => true;
}

Rect _probabilityPlot(Size size) =>
    Rect.fromLTRB(0, 8, size.width - 48, size.height - 28);

class PrecipitationProbabilityChart extends StatelessWidget {
  final List<HourlyWeatherModel> hours;
  final Duration? utcOffset;
  const PrecipitationProbabilityChart({
    super.key,
    required this.hours,
    this.utcOffset,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timeline = List<HourlyWeatherModel>.of(hours)..sort(
      (a, b) => _forecastInstant(
        a,
        utcOffset,
      ).compareTo(_forecastInstant(b, utcOffset)),
    );
    final runs = forecastRuns(
      timeline,
      value:
          (hour) => validPrecipitationProbability(hour.pop) ? hour.pop : null,
      utcOffset: utcOffset,
    );
    final empty = runs.isEmpty;
    return Semantics(
      label: empty ? '暂无当日降水概率数据' : '所选日期降水概率曲线',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, 250);
          final plot = _probabilityPlot(size);
          if (plot.isEmpty) return const SizedBox.shrink();
          return SizedBox(
            height: size.height,
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _ProbabilityPainter(
                    runs: runs,
                    foreground: colors.onSurfaceVariant,
                    grid: colors.outlineVariant,
                    line: const Color(0xFF35C9F4),
                    fontFamily:
                        Theme.of(context).textTheme.bodySmall?.fontFamily,
                  ),
                ),
                if (empty)
                  Positioned.fromRect(
                    rect: plot,
                    child: const _ForecastChartEmptyState(
                      message: '暂无当日降水概率数据',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProbabilityPainter extends CustomPainter {
  final List<List<HourlyWeatherModel>> runs;
  final Color foreground, grid, line;
  final String? fontFamily;
  _ProbabilityPainter({
    required this.runs,
    required this.foreground,
    required this.grid,
    required this.line,
    this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plot = _probabilityPlot(size);
    final width = plot.width, height = plot.height, top = plot.top;
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
    for (final run in runs) {
      final points =
          run
              .map(
                (hour) => Offset(
                  width * (hour.time.hour + hour.time.minute / 60) / 24,
                  top + height * (1 - hour.pop! / 100),
                ),
              )
              .toList();
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
      if (points.length == 1) {
        canvas.drawCircle(points.first, 3, Paint()..color = line);
      }
    }
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
      old.runs != runs ||
      old.foreground != foreground ||
      old.grid != grid ||
      old.line != line ||
      old.fontFamily != fontFamily;
}

double? _sum(Iterable<double?> values) {
  final valid = values.whereType<double>().where((v) => v.isFinite).toList();
  return valid.isEmpty
      ? null
      : valid.fold<double>(0, (sum, value) => sum + value);
}

String _dailySummary(
  List<HourlyWeatherModel> hours,
  double? probability, {
  required bool remaining,
}) {
  if (hours.isEmpty) return '暂无当日天气数据';
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
          ? '，降水概率暂无数据'
          : probability <= 0
          ? '，逐小时降水概率为 0%'
          : '，最高逐小时降水概率 ${probability.round()}%';
  return '${remaining ? '剩余时段' : '已获取时段'}以$description为主$range$rain。';
}
