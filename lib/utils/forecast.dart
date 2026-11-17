import '../models/weather_model.dart';

bool validPrecipitationProbability(double? value) =>
    value != null && value.isFinite && value >= 0 && value <= 100;

/// Split missing or non-adjacent hours so a chart never implies continuity
/// across a gap. Callers supply a timeline sorted by absolute forecast time.
List<List<HourlyWeatherModel>> forecastRuns(
  List<HourlyWeatherModel> timeline, {
  required double? Function(HourlyWeatherModel) value,
  Duration? utcOffset,
}) {
  final runs = <List<HourlyWeatherModel>>[];
  List<HourlyWeatherModel>? current;
  DateTime instant(HourlyWeatherModel hour) =>
      hour.time.subtract(hour.utcOffset ?? utcOffset ?? Duration.zero);
  for (final hour in timeline) {
    if (value(hour)?.isFinite != true) {
      current = null;
      continue;
    }
    if (current != null) {
      final previous = current.last;
      final gap = instant(hour).difference(instant(previous));
      if (gap <= Duration.zero ||
          gap > const Duration(hours: 1, minutes: 1) ||
          !hour.time.isAfter(previous.time)) {
        current = null;
      }
    }
    if (current == null) {
      current = <HourlyWeatherModel>[];
      runs.add(current);
    }
    current.add(hour);
  }
  return runs;
}
