import 'daily_forecast_details.dart';
import '../utils/weather_time.dart';

class DailyWeatherModel {
  final DateTime date;
  final DailyForecastDetails? details;
  final String icon;
  final String description;
  final double maxTemp;
  final double minTemp;
  final double humidity;
  final double windSpeed;

  final String? sunrise, sunset;
  final String? windDir, windScale;
  final double? uvIndex, precip;

  DailyWeatherModel({
    required this.date,
    this.details,
    required this.icon,
    required this.description,
    required this.maxTemp,
    required this.minTemp,
    required this.humidity,
    required this.windSpeed,
    this.windDir,
    this.windScale,
    this.sunrise,
    this.sunset,
    this.uvIndex,
    this.precip,
  });

  factory DailyWeatherModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('forecastStartTime')) {
      final details = DailyForecastDetails(json);
      final day = details.daytime;
      final astro = details.astro;
      return DailyWeatherModel(
        date: WeatherTimeUtils.parseWallClock(
          json['forecastStartTime'].toString().substring(0, 10),
        ),
        details: details,
        icon: day.icon ?? '',
        description: day.description ?? '',
        maxTemp:
            DailyForecastDetails.measurement(json['temperatureMax'], '°C') ??
            double.nan,
        minTemp:
            DailyForecastDetails.measurement(json['temperatureMin'], '°C') ??
            double.nan,
        humidity: day.humidity ?? double.nan,
        windSpeed: day.windSpeed ?? double.nan,
        windDir: day.windDirection,
        windScale: day.windScale,
        precip: details.totalPrecipitation,
        uvIndex: details.uvIndex,
        sunrise: DailyForecastDetails.clock(astro['sunrise']),
        sunset: DailyForecastDetails.clock(astro['sunset']),
      );
    }
    return DailyWeatherModel(
      date: WeatherTimeUtils.parseWallClock(json['fxDate'].toString()),
      windDir: json['windDirDay']?.toString(),
      windScale: json['windScaleDay']?.toString(),
      sunrise: json['sunrise']?.toString(),
      sunset: json['sunset']?.toString(),
      uvIndex: double.tryParse(json['uvIndex']?.toString() ?? ''),
      precip: double.tryParse(json['precip']?.toString() ?? ''),
      icon: json['iconDay'],
      description: json['textDay'],
      maxTemp: double.tryParse(json['tempMax']) ?? double.nan,
      minTemp: double.tryParse(json['tempMin']) ?? double.nan,
      humidity: double.tryParse(json['humidity']) ?? double.nan,
      windSpeed: double.tryParse(json['windSpeedDay']) ?? double.nan,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (details != null) ...details!.json,
      'fxDate': date.toIso8601String().substring(0, 10),
      'windDirDay': windDir,
      'windScaleDay': windScale,
      'sunrise': sunrise,
      'sunset': sunset,
      'uvIndex': uvIndex?.toString(),
      'precip': precip?.toString(),
      'iconDay': icon,
      'textDay': description,
      'tempMax': maxTemp.toString(),
      'tempMin': minTemp.toString(),
      'humidity': humidity.toString(),
      'windSpeedDay': windSpeed.toString(),
    };
  }
}

class LiveWeatherModel {
  final String obsTime;
  final double temp;
  final double feelsLike;
  final String icon;
  final String text;
  final String wind360;
  final String windDir;
  final String windScale;
  final double windSpeed;
  final double humidity;
  final double precip;
  final double pressure;
  final double vis;
  final double cloud;
  final double dew;
  final List<String> attributions;

  LiveWeatherModel({
    required this.obsTime,
    required this.temp,
    required this.feelsLike,
    required this.icon,
    required this.text,
    required this.wind360,
    required this.windDir,
    required this.windScale,
    required this.windSpeed,
    required this.humidity,
    required this.precip,
    required this.pressure,
    required this.vis,
    required this.cloud,
    required this.dew,
    this.attributions = const [],
  });

  factory LiveWeatherModel.fromJson(Map<String, dynamic> json) {
    final attributions = _weatherAttributions(json);
    if (json['temperature'] is Map || json['condition'] is Map) {
      final condition = DailyForecastDetails.object(json['condition']);
      final wind = DailyForecastDetails.object(json['wind']);
      final direction = DailyForecastDetails.object(wind['direction']);
      final precipitation = DailyForecastDetails.object(json['precipitation']);
      return LiveWeatherModel(
        // The v1 current product does not return an observation timestamp.
        obsTime: '',
        temp:
            DailyForecastDetails.measurement(json['temperature'], '°C') ??
            double.nan,
        feelsLike:
            DailyForecastDetails.measurement(json['feelsLike'], '°C') ??
            double.nan,
        icon: condition['code']?.toString() ?? '',
        text: condition['text']?.toString() ?? '',
        wind360: direction['degree']?.toString() ?? '',
        windDir: _windDirection(direction['compass']?.toString()),
        windScale:
            wind['scale']?.toString().replaceFirst(RegExp(r'\.0$'), '') ?? '',
        windSpeed:
            DailyForecastDetails.measurement(wind['speed'], 'km/h') ??
            double.nan,
        humidity: DailyForecastDetails.fraction(json['humidity']) ?? double.nan,
        precip:
            DailyForecastDetails.measurement(precipitation['amount'], 'mm') ??
            double.nan,
        pressure:
            DailyForecastDetails.measurement(json['pressure'], 'hPa') ??
            double.nan,
        vis: _visibilityInKilometers(json['visibility']) ?? double.nan,
        cloud: DailyForecastDetails.fraction(json['cloudCover']) ?? double.nan,
        dew:
            DailyForecastDetails.measurement(json['dewPoint'], '°C') ??
            double.nan,
        attributions: attributions,
      );
    }
    return LiveWeatherModel(
      obsTime: json['obsTime']?.toString() ?? '',
      temp: DailyForecastDetails.number(json['temp']) ?? double.nan,
      feelsLike: DailyForecastDetails.number(json['feelsLike']) ?? double.nan,
      icon: json['icon']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      wind360: json['wind360']?.toString() ?? '',
      windDir: json['windDir']?.toString() ?? '',
      windScale: json['windScale']?.toString() ?? '',
      windSpeed: DailyForecastDetails.number(json['windSpeed']) ?? double.nan,
      humidity: DailyForecastDetails.number(json['humidity']) ?? double.nan,
      precip: DailyForecastDetails.number(json['precip']) ?? double.nan,
      pressure: DailyForecastDetails.number(json['pressure']) ?? double.nan,
      vis: DailyForecastDetails.number(json['vis']) ?? double.nan,
      cloud: DailyForecastDetails.number(json['cloud']) ?? double.nan,
      dew: DailyForecastDetails.number(json['dew']) ?? double.nan,
      attributions: attributions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'obsTime': obsTime,
      'temp': temp.toString(),
      'feelsLike': feelsLike.toString(),
      'icon': icon,
      'text': text,
      'wind360': wind360,
      'windDir': windDir,
      'windScale': windScale,
      'windSpeed': windSpeed.toString(),
      'humidity': humidity.toString(),
      'precip': precip.toString(),
      'pressure': pressure.toString(),
      'vis': vis.toString(),
      'cloud': cloud.toString(),
      'dew': dew.toString(),
      '_attributions': attributions,
    };
  }
}

List<String> _weatherAttributions(Map<String, dynamic> json) {
  final metadata = DailyForecastDetails.object(json['metadata']);
  final value = metadata['attributions'] ?? json['_attributions'];
  return value is List ? value.whereType<String>().toList() : const [];
}

class HourlyWeatherModel {
  /// City civil time; use its fields directly rather than converting toLocal().
  final DateTime time;
  final Duration? utcOffset;
  final double temp;
  final String icon;
  final String text;
  final String wind360;
  final String windDir;
  final String windScale;
  final double windSpeed;
  final double humidity;
  final double precip;
  final double? pop;
  final double pressure;
  final double? cloud;
  final double? dew;
  final double? feelsLike;
  final double? gust;
  final double? visibility;
  final double? uvIndex;
  final double? precipitationIntensity;
  final String? precipitationType;
  final List<String> attributions;

  HourlyWeatherModel({
    required this.time,
    this.utcOffset,
    required this.temp,
    required this.icon,
    required this.text,
    required this.wind360,
    required this.windDir,
    required this.windScale,
    required this.windSpeed,
    required this.humidity,
    required this.precip,
    required this.pressure,
    this.pop,
    this.cloud,
    this.dew,
    this.feelsLike,
    this.gust,
    this.visibility,
    this.uvIndex,
    this.precipitationIntensity,
    this.precipitationType,
    this.attributions = const [],
  });

  factory HourlyWeatherModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('forecastTime')) {
      final condition = DailyForecastDetails.object(json['condition']);
      final wind = DailyForecastDetails.object(json['wind']);
      final direction = DailyForecastDetails.object(wind['direction']);
      final precipitation = DailyForecastDetails.object(json['precipitation']);
      return HourlyWeatherModel(
        // localTime=true returns the queried location's civil time. Parse the
        // wall-clock portion so a city in another time zone is not shifted to
        // the device's date when grouping the ten-day chart.
        time: _parseForecastWallClock(json['forecastTime']),
        utcOffset: WeatherTimeUtils.offsetOf(json['forecastTime']?.toString()),
        temp:
            DailyForecastDetails.measurement(json['temperature'], '°C') ??
            double.nan,
        feelsLike: DailyForecastDetails.measurement(json['feelsLike'], '°C'),
        icon: condition['code']?.toString() ?? '',
        text: condition['text']?.toString() ?? '',
        wind360: direction['degree']?.toString() ?? '',
        windDir: _windDirection(direction['compass']?.toString()),
        windScale: wind['scale']?.toString() ?? '',
        windSpeed:
            DailyForecastDetails.measurement(wind['speed'], 'km/h') ??
            double.nan,
        gust: DailyForecastDetails.measurement(json['windGust'], 'km/h'),
        humidity: DailyForecastDetails.fraction(json['humidity']) ?? double.nan,
        precip:
            DailyForecastDetails.measurement(precipitation['amount'], 'mm') ??
            double.nan,
        precipitationIntensity: DailyForecastDetails.measurement(
          precipitation['intensity'],
          'mm/h',
        ),
        precipitationType: _precipitationType(
          precipitation['type']?.toString(),
        ),
        pop: DailyForecastDetails.fraction(precipitation['probability']),
        pressure:
            DailyForecastDetails.measurement(json['pressure'], 'hPa') ??
            double.nan,
        visibility: _visibilityInKilometers(json['visibility']),
        cloud: DailyForecastDetails.fraction(json['cloudCover']),
        dew: DailyForecastDetails.measurement(json['dewPoint'], '°C'),
        uvIndex: DailyForecastDetails.number(json['uvIndex']),
        attributions:
            (json['_attributions'] as List? ?? const [])
                .whereType<String>()
                .toList(),
      );
    }
    return HourlyWeatherModel(
      time: _parseForecastWallClock(json['fxTime']),
      utcOffset:
          json['_utcOffsetMinutes'] is int
              ? Duration(minutes: json['_utcOffsetMinutes'] as int)
              : WeatherTimeUtils.offsetOf(json['fxTime']?.toString()),
      temp: double.tryParse(json['temp'] ?? '') ?? double.nan,
      icon: json['icon'] ?? '',
      text: json['text'] ?? '',
      wind360: json['wind360'] ?? '',
      windDir: json['windDir'] ?? '',
      windScale: json['windScale'] ?? '',
      windSpeed: double.tryParse(json['windSpeed'] ?? '') ?? double.nan,
      humidity: double.tryParse(json['humidity'] ?? '') ?? double.nan,
      precip: double.tryParse(json['precip'] ?? '') ?? double.nan,
      pressure: double.tryParse(json['pressure'] ?? '') ?? double.nan,
      pop: json['pop'] != null ? double.tryParse(json['pop']) : null,
      cloud: json['cloud'] != null ? double.tryParse(json['cloud']) : null,
      dew: json['dew'] != null ? double.tryParse(json['dew']) : null,
      feelsLike:
          json['feelsLike'] != null
              ? double.tryParse(json['feelsLike'].toString())
              : null,
      gust:
          json['gust'] != null
              ? double.tryParse(json['gust'].toString())
              : null,
      visibility:
          json['visibility'] != null
              ? double.tryParse(json['visibility'].toString())
              : null,
      uvIndex:
          json['uvIndex'] != null
              ? double.tryParse(json['uvIndex'].toString())
              : null,
      precipitationIntensity:
          json['precipitationIntensity'] != null
              ? double.tryParse(json['precipitationIntensity'].toString())
              : null,
      precipitationType: json['precipitationType']?.toString(),
      attributions:
          (json['_attributions'] as List? ?? const [])
              .whereType<String>()
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // This is already a city clock, not an instant in UTC. Keep cache values
      // timezone-free so restoring them never shifts them to the device zone.
      'fxTime': time.toIso8601String().replaceFirst(RegExp(r'Z$'), ''),
      '_utcOffsetMinutes': utcOffset?.inMinutes,
      'temp': temp.toString(),
      'icon': icon,
      'text': text,
      'wind360': wind360,
      'windDir': windDir,
      'windScale': windScale,
      'windSpeed': windSpeed.toString(),
      'humidity': humidity.toString(),
      'precip': precip.toString(),
      'pressure': pressure.toString(),
      'pop': pop?.toString(),
      'cloud': cloud?.toString(),
      'dew': dew?.toString(),
      'feelsLike': feelsLike?.toString(),
      'gust': gust?.toString(),
      'visibility': visibility?.toString(),
      'uvIndex': uvIndex?.toString(),
      'precipitationIntensity': precipitationIntensity?.toString(),
      'precipitationType': precipitationType,
      '_attributions': attributions,
    };
  }
}

bool hasTenDayHourlyCoverage(List<HourlyWeatherModel> hours) =>
    hours.length >= 216;

DateTime _parseForecastWallClock(dynamic value) {
  return WeatherTimeUtils.parseWallClock(value?.toString() ?? '');
}

String _windDirection(String? compass) =>
    const {
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
    }[compass] ??
    '';

String? _precipitationType(String? type) =>
    const {
      'rain': '雨',
      'snow': '雪',
      'ice': '冰粒或冻雨',
      'mixed': '混合降水',
      'none': '无降水',
      'unknown': '未知',
    }[type];

double? _visibilityInKilometers(dynamic value) {
  final map = DailyForecastDetails.object(value);
  final number = DailyForecastDetails.number(map['value']);
  if (number == null) return null;
  if (map['unit'] == 'm') return number / 1000;
  if (map['unit'] == 'km') return number;
  return null;
}

class WeatherWarningModel {
  final String id;
  final String sender;
  final DateTime pubTime;

  /// Preserve the publication's local offset while keeping warning instants
  /// suitable for comparisons such as expiration checks.
  final Duration? utcOffset;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String level;
  final String severity;
  final String severityColor;
  final String type;
  final String typeName;
  final String text;
  final String icon;
  final Map<String, dynamic> alertColor;
  final String instruction;
  final String criteria;
  final List<String> supersedes;
  final List<String> attributions;
  final DateTime? onsetTime;

  WeatherWarningModel({
    required this.id,
    required this.sender,
    required this.pubTime,
    this.utcOffset,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.level,
    required this.severity,
    required this.severityColor,
    required this.type,
    required this.typeName,
    required this.text,
    this.icon = '',
    this.alertColor = const {},
    this.instruction = '',
    this.criteria = '',
    this.supersedes = const [],
    this.attributions = const [],
    this.onsetTime,
  });

  factory WeatherWarningModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('issuedTime') || json['eventType'] is Map) {
      final event = DailyForecastDetails.object(json['eventType']);
      final message = DailyForecastDetails.object(json['messageType']);
      final color = DailyForecastDetails.object(json['color']);
      final id = json['id']?.toString() ?? '';
      if (id.isEmpty) throw const FormatException('预警缺少编号');
      final issuedTime = json['issuedTime']?.toString() ?? '';
      return WeatherWarningModel(
        id: id,
        sender: json['senderName']?.toString() ?? '',
        pubTime: DateTime.parse(issuedTime),
        utcOffset: WeatherTimeUtils.offsetOf(issuedTime),
        title: json['headline']?.toString() ?? '',
        startTime: DateTime.parse(json['effectiveTime']?.toString() ?? ''),
        endTime: DateTime.parse(json['expireTime']?.toString() ?? ''),
        onsetTime: DateTime.tryParse(json['onsetTime']?.toString() ?? ''),
        status: message['code']?.toString() ?? 'alert',
        level: '',
        severity: json['severity']?.toString() ?? 'unknown',
        severityColor: color['code']?.toString() ?? '',
        type: event['code']?.toString() ?? '',
        typeName: event['name']?.toString() ?? '气象预警',
        text: json['description']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
        alertColor: color,
        instruction: json['instruction']?.toString() ?? '',
        criteria: json['criteria']?.toString() ?? '',
        supersedes:
            (message['supersedes'] as List? ?? []).whereType<String>().toList(),
        attributions: _weatherAttributions(json),
      );
    }
    return WeatherWarningModel(
      id: json['id'],
      sender: json['sender'],
      pubTime: DateTime.parse(json['pubTime']),
      utcOffset:
          json['_utcOffsetMinutes'] is int
              ? Duration(minutes: json['_utcOffsetMinutes'] as int)
              : RegExp(r'[+-]\d{2}(?::?\d{2})?$').hasMatch(json['pubTime'])
              ? WeatherTimeUtils.offsetOf(json['pubTime'])
              : null,
      title: json['title'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'],
      level: json['level'],
      severity: json['severity'],
      severityColor: json['severityColor'],
      type: json['type'],
      typeName: json['typeName'],
      text: json['text'],
      icon: json['_icon']?.toString() ?? '',
      alertColor: DailyForecastDetails.object(json['_alertColor']),
      instruction: json['_instruction']?.toString() ?? '',
      criteria: json['_criteria']?.toString() ?? '',
      supersedes:
          (json['_supersedes'] as List? ?? []).whereType<String>().toList(),
      attributions: _weatherAttributions(json),
      onsetTime: DateTime.tryParse(json['_onsetTime']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'pubTime': pubTime.toIso8601String(),
      '_utcOffsetMinutes': utcOffset?.inMinutes,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'level': level,
      'severity': severity,
      'severityColor': severityColor,
      'type': type,
      'typeName': typeName,
      'text': text,
      '_icon': icon,
      '_alertColor': alertColor,
      '_instruction': instruction,
      '_criteria': criteria,
      '_supersedes': supersedes,
      '_attributions': attributions,
      '_onsetTime': onsetTime?.toIso8601String(),
    };
  }
}

/// A successful feed is a replacement snapshot. Retain message relationships
/// in cache so an updated or cancelled warning cannot reappear while offline.
List<WeatherWarningModel> activeWeatherWarnings(
  Iterable<WeatherWarningModel> warnings, {
  DateTime? now,
}) {
  final messages = <String, WeatherWarningModel>{};
  for (final warning in warnings) {
    final previous = messages[warning.id];
    if (previous == null || !warning.pubTime.isBefore(previous.pubTime)) {
      messages[warning.id] = warning;
    }
  }
  final superseded = <String>{
    for (final message in messages.values)
      if (const {'update', 'cancel'}.contains(message.status.toLowerCase()))
        ...message.supersedes,
  };
  final current = now ?? DateTime.now();
  return messages.values
      .where(
        (warning) =>
            warning.status.toLowerCase() != 'cancel' &&
            warning.status.toLowerCase() != 'cancelled' &&
            !superseded.contains(warning.id) &&
            warning.endTime.isAfter(current),
      )
      .toList();
}
