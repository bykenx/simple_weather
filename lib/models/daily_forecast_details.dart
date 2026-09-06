/// Optional v1 forecast fields retained verbatim for lossless cache round trips.
class DailyForecastDetails {
  final Map<String, dynamic> json;
  DailyForecastDetails(this.json);
  ForecastPeriod get daytime => ForecastPeriod(object(json['daytime']));
  ForecastPeriod get nighttime => ForecastPeriod(object(json['nighttime']));
  Map<String, dynamic> get astro => object(json['astro']);
  double? get averageTemperature => measurement(json['temperatureAvg'], '°C');
  double? get uvIndex => number(json['uvIndexMax']);
  List<String> get attributions =>
      (json['_attributions'] as List? ?? []).whereType<String>().toList();
  double? get totalPrecipitation {
    final day = daytime.precipitation, night = nighttime.precipitation;
    return day == null || night == null ? null : day + night;
  }

  static Map<String, dynamic> object(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  static double? number(dynamic value) {
    final result = double.tryParse(value?.toString() ?? '');
    return result != null && result.isFinite ? result : null;
  }

  static double? fraction(dynamic value) {
    final n = number(value);
    return n == null || n < 0 || n > 1 ? null : n * 100;
  }

  static double? measurement(dynamic value, String target) {
    final map = object(value), n = number(object(value)['value']);
    if (n == null) return null;
    final unit = map['unit'];
    if (unit == target) return n;
    if (target == 'km/h' && unit == 'm/s') return n * 3.6;
    if (target == 'mm' && unit == 'cm') return n * 10;
    return null; // Never relabel an unknown unit.
  }

  static String? clock(dynamic value) {
    final text = value?.toString();
    if (text == null || DateTime.tryParse(text) == null || text.length < 16) {
      return null;
    }
    return text.substring(
      11,
      16,
    ); // localTime=true; keep the location's wall clock.
  }

  static const moonNames = {
    'new-moon': '新月',
    'waxing-crescent': '蛾眉月',
    'first-quarter': '上弦月',
    'waxing-gibbous': '盈凸月',
    'full-moon': '满月',
    'waning-gibbous': '亏凸月',
    'last-quarter': '下弦月',
    'waning-crescent': '残月',
  };
}

class ForecastPeriod {
  final Map<String, dynamic> json;
  ForecastPeriod(this.json);
  Map<String, dynamic> get _wind => DailyForecastDetails.object(json['wind']);
  Map<String, dynamic> get _rain =>
      DailyForecastDetails.object(json['precipitation']);
  String? get description =>
      DailyForecastDetails.object(json['condition'])['text']?.toString();
  String? get icon =>
      DailyForecastDetails.object(json['condition'])['code']?.toString();
  double? get maxTemperature =>
      DailyForecastDetails.measurement(json['temperatureMax'], '°C');
  double? get minTemperature =>
      DailyForecastDetails.measurement(json['temperatureMin'], '°C');
  double? get humidity => DailyForecastDetails.fraction(json['humidity']);
  double? get cloudCover => DailyForecastDetails.fraction(json['cloudCover']);
  double? get probability =>
      DailyForecastDetails.fraction(_rain['probability']);
  double? get precipitation =>
      DailyForecastDetails.measurement(_rain['amount'], 'mm');
  double? get windSpeed =>
      DailyForecastDetails.measurement(_wind['speed'], 'km/h');
  double? get gust =>
      DailyForecastDetails.measurement(json['windGustMax'], 'km/h');
  double? get windDegrees => DailyForecastDetails.number(
    DailyForecastDetails.object(_wind['direction'])['degree'],
  );
  String? get windScale => _wind['scale']?.toString();
  String? get windDirection {
    const names = {
      'n': '北风',
      'nne': '北东北风',
      'ne': '东北风',
      'ene': '东东北风',
      'e': '东风',
      'ese': '东东南风',
      'se': '东南风',
      'sse': '南东南风',
      's': '南风',
      'ssw': '南西南风',
      'sw': '西南风',
      'wsw': '西西南风',
      'w': '西风',
      'wnw': '西西北风',
      'nw': '西北风',
      'nnw': '北西北风',
      'none': '无持续风向',
      'vrb': '风向不定',
    };
    return names[DailyForecastDetails.object(_wind['direction'])['compass']];
  }

  String? get precipitationType =>
      const {
        'rain': '雨',
        'snow': '雪',
        'ice': '冰粒或冻雨',
        'mixed': '混合降水',
        'none': '无降水',
        'unknown': '未知',
      }[_rain['type']];
}
