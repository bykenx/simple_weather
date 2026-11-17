/// Forecast dates and clocks are civil values in the queried city's time zone.
/// UTC DateTimes carry those fields without the device's DST rules changing them;
/// they must not be converted with toLocal() or used as absolute instants.
class WeatherTimeUtils {
  static final _offset = RegExp(r'([+-])(\d{2})(?::?(\d{2}))?$');

  static Duration? offsetOf(String? value) {
    if (value == null) return null;
    final text = value.trim();
    if (text.endsWith('Z') || text.endsWith('z')) return Duration.zero;
    // A date's trailing day (e.g. "-24") is not a UTC offset.
    if (!text.startsWith('+') &&
        !text.startsWith('-') &&
        !text.contains('T') &&
        !text.contains(' ')) {
      return null;
    }
    final match = _offset.firstMatch(text);
    if (match == null) return null;
    final hours = int.parse(match[2]!);
    final minutes = int.parse(match[3] ?? '0');
    if (hours > 23 || minutes > 59) return null;
    final total = hours * 60 + minutes;
    return Duration(minutes: match[1] == '-' ? -total : total);
  }

  static DateTime parseWallClock(String value) {
    final text = value.trim();
    if (!text.contains('T') && !text.contains(' ')) {
      return date(DateTime.parse(text));
    }
    // ISO 8601 allows minute precision as well as seconds. Cutting at index 19
    // can leave "+08" behind, causing Dart to silently convert the clock to UTC.
    final clock = text.replaceFirst(
      RegExp(r'(?:[zZ]|[+-]\d{2}(?::?\d{2})?)$'),
      '',
    );
    return DateTime.parse('${clock}Z');
  }

  static DateTime atOffset(DateTime instant, Duration? offset) {
    if (offset != null) return instant.toUtc().add(offset);
    final local = instant.toLocal();
    return DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
      local.microsecond,
    );
  }

  static DateTime date(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}
