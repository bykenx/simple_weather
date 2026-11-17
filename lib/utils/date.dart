import 'weather_time.dart';

class WeatherDateUtils {
  static String getDateText(DateTime date, {DateTime? now}) {
    final today = WeatherTimeUtils.date(now ?? DateTime.now());
    final tomorrow = DateTime.utc(today.year, today.month, today.day + 1);
    final dateOnly = WeatherTimeUtils.date(date);

    if (dateOnly == today) return '今天';
    if (dateOnly == tomorrow) return '明天';

    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  static String getFormattedDateText(DateTime date, {DateTime? now}) {
    final today = WeatherTimeUtils.date(now ?? DateTime.now());
    final tomorrow = DateTime.utc(today.year, today.month, today.day + 1);
    final dateOnly = WeatherTimeUtils.date(date);

    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];

    if (dateOnly == today) return '今天 ${date.month}/${date.day}';
    if (dateOnly == tomorrow) return '明天 ${date.month}/${date.day}';

    return '$weekday ${date.month}/${date.day}';
  }
}
