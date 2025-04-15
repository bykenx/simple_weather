class AirQualityModel {
  final int aqi;
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
    var firstIndex = json['indexes'][0];

    final pollutants = <String, double>{};
    for (final pollutant in json['pollutants']) {
      final value = pollutant['concentration']['value'] as double;
      pollutants[pollutant['code']] = value;
    }

    return AirQualityModel(
      aqi: firstIndex?['aqi'] ?? 0,
      code: firstIndex?['code'] ?? '',
      name: firstIndex?['name'] ?? '',
      category: firstIndex?['category'] ?? '',
      primaryPollutantCode: firstIndex?['primaryPollutant']?['code'] ?? '',
      primaryPollutantName: firstIndex?['primaryPollutant']?['name'] ?? '',
      primaryPollutantFullName:
          firstIndex?['primaryPollutant']?['fullName'] ?? '',
      pollutants: pollutants,
      healthEffect: firstIndex?['health']?['effect'] ?? '',
      healthAdviceGeneral:
          firstIndex?['health']?['advice']?['generalPopulation'] ?? '',
      healthAdviceSensitive:
          firstIndex?['health']?['advice']?['sensitivePopulation'] ?? '',
    );
  }
}
