import 'daily_forecast_details.dart';

class DailyWeatherModel {
  final DateTime date;
  final DailyForecastDetails? details;
  final String icon;
  final String description;
  final double maxTemp;
  final double minTemp;
  final double humidity;
  final double windSpeed;

  final String? sunrise, sunset, moonrise, moonset, moonPhase, moonPhaseIcon;
  final String? windDir, windScale;
  final double? uvIndex, precip;
  final List<MoonPhaseHour> moonPhases;

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
    this.moonrise,
    this.moonset,
    this.moonPhase,
    this.moonPhaseIcon,
    this.uvIndex,
    this.precip,
    this.moonPhases = const [],
  });

  factory DailyWeatherModel.fromJson(Map<String, dynamic> json) {
    final moonPhases =
        (json['_moonPhaseHourly'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) => MoonPhaseHour.fromJson(Map<String, dynamic>.from(item)),
            )
            .whereType<MoonPhaseHour>()
            .toList();
    if (json.containsKey('forecastStartTime')) {
      final details = DailyForecastDetails(json);
      final day = details.daytime;
      final astro = details.astro;
      return DailyWeatherModel(
        date: DateTime.parse(
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
        moonrise: DailyForecastDetails.clock(
          json['_moonrise'] ?? astro['moonrise'],
        ),
        moonset: DailyForecastDetails.clock(
          json['_moonset'] ?? astro['moonset'],
        ),
        moonPhase: DailyForecastDetails.moonNames[astro['moonPhase']],
        moonPhases: moonPhases,
      );
    }
    return DailyWeatherModel(
      date: DateTime.parse(json['fxDate']),
      windDir: json['windDirDay']?.toString(),
      windScale: json['windScaleDay']?.toString(),
      sunrise: json['sunrise']?.toString(),
      sunset: json['sunset']?.toString(),
      moonrise:
          DailyForecastDetails.clock(json['_moonrise']) ??
          json['moonrise']?.toString(),
      moonset:
          DailyForecastDetails.clock(json['_moonset']) ??
          json['moonset']?.toString(),
      moonPhase: json['moonPhase']?.toString(),
      moonPhaseIcon: json['moonPhaseIcon']?.toString(),
      moonPhases: moonPhases,
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
      'fxDate': date.toIso8601String(),
      'windDirDay': windDir,
      'windScaleDay': windScale,
      'sunrise': sunrise,
      'sunset': sunset,
      'moonrise': moonrise,
      'moonset': moonset,
      'moonPhase': moonPhase,
      'moonPhaseIcon': moonPhaseIcon,
      '_moonPhaseHourly': moonPhases.map((phase) => phase.toJson()).toList(),
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

  MoonPhaseHour? moonPhaseAt(DateTime time) {
    if (moonPhases.isEmpty) return null;
    return moonPhases.reduce(
      (a, b) =>
          a.time.difference(time).abs() <= b.time.difference(time).abs()
              ? a
              : b,
    );
  }
}

class MoonPhaseHour {
  final DateTime time;
  final double value;
  final double illumination;
  final String name;
  final String icon;

  const MoonPhaseHour({
    required this.time,
    required this.value,
    required this.illumination,
    required this.name,
    required this.icon,
  });

  static MoonPhaseHour? fromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(json['fxTime']?.toString() ?? '');
    final value = double.tryParse(json['value']?.toString() ?? '');
    final illumination = double.tryParse(
      json['illumination']?.toString() ?? '',
    );
    if (time == null ||
        value == null ||
        !value.isFinite ||
        illumination == null ||
        !illumination.isFinite) {
      return null;
    }
    return MoonPhaseHour(
      time: time,
      value: value.clamp(0, 1),
      illumination: illumination.clamp(0, 100),
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'fxTime': time.toIso8601String(),
    'value': value.toString(),
    'illumination': illumination.toString(),
    'name': name,
    'icon': icon,
  };
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
  });

  factory LiveWeatherModel.fromJson(Map<String, dynamic> json) {
    return LiveWeatherModel(
      obsTime: json['obsTime'],
      temp: double.tryParse(json['temp']) ?? double.nan,
      feelsLike: double.tryParse(json['feelsLike']) ?? double.nan,
      icon: json['icon'],
      text: json['text'],
      wind360: json['wind360'],
      windDir: json['windDir'],
      windScale: json['windScale'],
      windSpeed: double.tryParse(json['windSpeed']) ?? double.nan,
      humidity: double.tryParse(json['humidity']) ?? double.nan,
      precip: double.tryParse(json['precip']) ?? double.nan,
      pressure: double.tryParse(json['pressure']) ?? double.nan,
      vis: double.tryParse(json['vis']) ?? double.nan,
      cloud: double.tryParse(json['cloud']) ?? double.nan,
      dew: double.tryParse(json['dew']) ?? double.nan,
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
    };
  }
}

class HourlyWeatherModel {
  final DateTime time;
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
      'fxTime': time.toIso8601String(),
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

/// The 240-hour product can contain 216–240 usable forecast points depending
/// on the provider's issue time. Older v7 caches contain only 24 points and no
/// hourly apparent temperature, so they must be refreshed after this upgrade.
bool hasTenDayHourlyCoverage(List<HourlyWeatherModel> hours) =>
    hours.length >= 216 &&
    hours.every((hour) => hour.feelsLike?.isFinite == true);

DateTime _parseForecastWallClock(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.length >= 19) return DateTime.parse(text.substring(0, 19));
  return DateTime.parse(text);
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

  WeatherWarningModel({
    required this.id,
    required this.sender,
    required this.pubTime,
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
  });

  factory WeatherWarningModel.fromJson(Map<String, dynamic> json) {
    return WeatherWarningModel(
      id: json['id'],
      sender: json['sender'],
      pubTime: DateTime.parse(json['pubTime']),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'pubTime': pubTime.toIso8601String(),
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
    };
  }
}
