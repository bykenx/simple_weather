import '../utils/forecast.dart';
import '../utils/weather_time.dart';
import 'weather_model.dart';

/// Derived from one rolling forecast window. Daily totals and observations
/// have different time ranges and must not be substituted for its amounts.
class PrecipitationSummary {
  final List<HourlyWeatherModel> hours;
  final double? maximumProbability;
  final double? totalPrecipitation;
  final bool completeProbability;
  final List<HourlyWeatherModel> highProbabilityHours;
  final DateTime localNow;

  const PrecipitationSummary._({
    required this.hours,
    required this.maximumProbability,
    required this.totalPrecipitation,
    required this.completeProbability,
    required this.highProbabilityHours,
    required this.localNow,
  });

  factory PrecipitationSummary.fromHours(
    Iterable<HourlyWeatherModel> forecast, {
    DateTime? now,
    Duration? utcOffset,
  }) {
    final instantNow = (now ?? DateTime.now()).toUtc();
    final end = instantNow.add(const Duration(hours: 24));
    DateTime instant(HourlyWeatherModel hour) =>
        hour.time.subtract(hour.utcOffset ?? utcOffset ?? Duration.zero);
    final unique = <DateTime, HourlyWeatherModel>{};
    for (final hour in forecast) {
      final time = instant(hour);
      if (!time.isBefore(instantNow) && !time.isAfter(end)) unique[time] = hour;
    }
    final timeline =
        unique.values.toList()
          ..sort((a, b) => instant(a).compareTo(instant(b)));
    final hours = timeline.take(24).toList();
    final complete =
        hours.length == 24 &&
        List.generate(
          23,
          (index) =>
              instant(hours[index + 1]).difference(instant(hours[index])) ==
              const Duration(hours: 1),
        ).every((adjacent) => adjacent);
    final probabilities =
        hours
            .map((hour) => hour.pop)
            .whereType<double>()
            .where(validPrecipitationProbability)
            .toList();
    final maximum =
        probabilities.isEmpty
            ? null
            : probabilities.reduce((a, b) => a > b ? a : b);
    final completeAmount =
        complete &&
        hours.every((hour) => hour.precip.isFinite && hour.precip >= 0);
    final total =
        completeAmount
            ? hours.fold<double>(0, (sum, hour) => sum + hour.precip)
            : null;
    // This is a presentation threshold, not a provider-defined rain category.
    // Show only the continuous >=50% run containing the highest hourly value.
    final highRuns =
        maximum != null && maximum >= 50
            ? forecastRuns(
              hours,
              value:
                  (hour) =>
                      validPrecipitationProbability(hour.pop) && hour.pop! >= 50
                          ? hour.pop
                          : null,
              utcOffset: utcOffset,
            )
            : <List<HourlyWeatherModel>>[];
    final highHours =
        highRuns
            .where((run) => run.any((hour) => hour.pop == maximum))
            .firstOrNull ??
        <HourlyWeatherModel>[];
    return PrecipitationSummary._(
      hours: List.unmodifiable(hours),
      maximumProbability: maximum,
      totalPrecipitation: total,
      completeProbability: complete && probabilities.length == hours.length,
      highProbabilityHours: List.unmodifiable(highHours),
      localNow: WeatherTimeUtils.atOffset(instantNow, utcOffset),
    );
  }

  String get timingText {
    if (maximumProbability == null) return '逐小时概率暂缺';
    if (maximumProbability == 0) return '已知时段概率均为0%';
    if (highProbabilityHours.isEmpty) return '已知时段降水概率较低';
    final first = highProbabilityHours.first.time;
    final last = highProbabilityHours.last.time;
    String prefix(DateTime time) {
      final difference =
          WeatherTimeUtils.date(
            time,
          ).difference(WeatherTimeUtils.date(localNow)).inDays;
      return difference == 0
          ? ''
          : difference == 1
          ? '明天'
          : '${time.month}/${time.day} ';
    }

    String clock(DateTime time) =>
        time.minute == 0
            ? '${time.hour}时'
            : '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    final sameDate =
        WeatherTimeUtils.date(first) == WeatherTimeUtils.date(last);
    final label =
        first == last
            ? '${prefix(first)}${clock(first)}'
            : sameDate && first.minute == 0 && last.minute == 0
            ? '${prefix(first)}${first.hour}–${last.hour}时'
            : '${prefix(first)}${clock(first)}至${prefix(last)}${clock(last)}';
    return '$label概率较高';
  }
}
