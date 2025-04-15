class DailyWeatherModel {
  final DateTime date;
  final String icon;
  final String description;
  final double maxTemp;
  final double minTemp;
  final double humidity;
  final double windSpeed;

  DailyWeatherModel({
    required this.date,
    required this.icon,
    required this.description,
    required this.maxTemp,
    required this.minTemp,
    required this.humidity,
    required this.windSpeed,
  });

  factory DailyWeatherModel.fromJson(Map<String, dynamic> json) {
    return DailyWeatherModel(
      date: DateTime.parse(json['fxDate']),
      icon: json['iconDay'],
      description: json['textDay'],
      maxTemp: double.tryParse(json['tempMax']) ?? double.nan,
      minTemp: double.tryParse(json['tempMin']) ?? double.nan,
      humidity: double.tryParse(json['humidity']) ?? double.nan,
      windSpeed: double.tryParse(json['windSpeedDay']) ?? double.nan,
    );
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
}

class HourlyWeatherModel {
  final DateTime time;
  final double temp;
  final String icon;
  final String text;
  final String windDir;
  final String windScale;
  final double windSpeed;
  final double humidity;
  final double precip;
  final double pressure;
  final double cloud;
  final double dew;

  HourlyWeatherModel({
    required this.time,
    required this.temp,
    required this.icon,
    required this.text,
    required this.windDir,
    required this.windScale,
    required this.windSpeed,
    required this.humidity,
    required this.precip,
    required this.pressure,
    required this.cloud,
    required this.dew,
  });

  factory HourlyWeatherModel.fromJson(Map<String, dynamic> json) {
    return HourlyWeatherModel(
      time: DateTime.parse(json['fxTime']),
      temp: double.tryParse(json['temp']) ?? double.nan,
      icon: json['icon'],
      text: json['text'],
      windDir: json['windDir'],
      windScale: json['windScale'],
      windSpeed: double.tryParse(json['windSpeed']) ?? double.nan,
      humidity: double.tryParse(json['humidity']) ?? double.nan,
      precip: double.tryParse(json['precip']) ?? double.nan,
      pressure: double.tryParse(json['pressure']) ?? double.nan,
      cloud: double.tryParse(json['cloud']) ?? double.nan,
      dew: double.tryParse(json['dew']) ?? double.nan,
    );
  }
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
}
