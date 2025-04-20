class AirQualityModel {
  final double aqi;
  final String code;
  final String name;
  final String category;
  final String primaryPollutantCode;
  final String primaryPollutantName;
  final String primaryPollutantFullName;
  final Map<String, double> pollutants;
  final String healthEffect;
  final String healthAdviceGeneral;
  final String healthAdviceSensitive;

  AirQualityModel({
    required this.aqi,
    required this.code,
    required this.name,
    required this.category,
    required this.primaryPollutantCode,
    required this.primaryPollutantName,
    required this.primaryPollutantFullName,
    required this.pollutants,
    required this.healthEffect,
    required this.healthAdviceGeneral,
    required this.healthAdviceSensitive,
  });

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    final pollutants = <String, double>{};
    if (json.containsKey('pollutants')) {
      for (final pollutant in json['pollutants']) {
        if (pollutant is Map &&
            pollutant.containsKey('code') &&
            pollutant.containsKey('concentration') &&
            pollutant['concentration'] is Map &&
            pollutant['concentration'].containsKey('value')) {
          final value = pollutant['concentration']['value'] as double;
          pollutants[pollutant['code']] = value;
        }
      }
    }

    return AirQualityModel(
      aqi:
          json['aqi'] is double
              ? json['aqi']
              : json['aqi'] is int
              ? json['aqi'].toDouble()
              : 0.0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      primaryPollutantCode: json['primaryPollutant']?['code'] ?? '',
      primaryPollutantName: json['primaryPollutant']?['name'] ?? '',
      primaryPollutantFullName: json['primaryPollutant']?['fullName'] ?? '',
      pollutants: pollutants,
      healthEffect: json['health']?['effect'] ?? '',
      healthAdviceGeneral:
          json['health']?['advice']?['generalPopulation'] ?? '',
      healthAdviceSensitive:
          json['health']?['advice']?['sensitivePopulation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'code': code,
      'name': name,
      'category': category,
      'primaryPollutant': {
        'code': primaryPollutantCode,
        'name': primaryPollutantName,
        'fullName': primaryPollutantFullName,
      },
      'health': {
        'effect': healthEffect,
        'advice': {
          'generalPopulation': healthAdviceGeneral,
          'sensitivePopulation': healthAdviceSensitive,
        },
      },
      'pollutants':
          pollutants.entries
              .map(
                (entry) => {
                  'code': entry.key,
                  'concentration': {'value': entry.value},
                },
              )
              .toList(),
    };
  }
}
