enum WeatherModule { live, daily, hourly, warnings, airQuality }

class ModuleState<T> {
  T? data;
  bool isLoading = false;
  String? error;
  DateTime? updatedAt;
  DateTime? retryAfter;
  bool fromCache = false;
  bool get isExpired => isExpiredAt(DateTime.now());
  bool isExpiredAt(DateTime now) =>
      updatedAt == null ||
      now.difference(updatedAt!) >= const Duration(hours: 1);

  bool shouldRefreshAt(DateTime now) =>
      !isLoading &&
      isExpiredAt(now) &&
      (retryAfter == null || !now.isBefore(retryAfter!));
}
