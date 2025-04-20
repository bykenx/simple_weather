class WeatherDateUtils {
  

  static String getDateText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return '今天';
    if (dateOnly == tomorrow) return '明天';
    
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }
  
  // 新增方法，同时显示周几和日期
  static String getFormattedDateText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    
    if (dateOnly == today) return '今天 ${date.month}/${date.day}';
    if (dateOnly == tomorrow) return '明天 ${date.month}/${date.day}';
    
    return '$weekday ${date.month}/${date.day}';
  }
} 