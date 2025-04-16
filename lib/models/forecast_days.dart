enum ForecastDays {
  three(3, '3d'),
  five(5, '5d'),
  ten(10, '10d'),
  thirty(30, '30d');

  final int days;
  final String apiSuffix;

  const ForecastDays(this.days, this.apiSuffix);

  static ForecastDays fromDays(int days) {
    switch (days) {
      case 3:
        return ForecastDays.three;
      case 5:
        return ForecastDays.five;
      case 10:
        return ForecastDays.ten;
      case 30:
        return ForecastDays.thirty;
      default:
        throw ArgumentError('不支持的预报天数: $days');
    }
  }
} 