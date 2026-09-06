enum WeatherModule { live, daily, hourly, warnings, airQuality }

class ModuleState<T> {
  T? data;
  bool isLoading = false;
  String? error;
  DateTime? updatedAt;
  bool fromCache = false;
  bool get isExpired =>
      updatedAt == null ||
      DateTime.now().difference(updatedAt!) >= const Duration(hours: 1);
}
