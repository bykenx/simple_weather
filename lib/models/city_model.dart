class CityModel {
  final String id;
  final String name;
  final String? adm1;
  final String? adm2;
  final String? country;
  final double? lat;
  final double? lon;

  CityModel({
    required this.id,
    required this.name,
    this.adm1,
    this.adm2,
    this.country,
    this.lat,
    this.lon,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'],
      name: json['name'],
      adm1: json['adm1'],
      adm2: json['adm2'],
      country: json['country'],
      lat: double.tryParse(json['lat']),
      lon: double.tryParse(json['lon']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'adm1': adm1,
      'adm2': adm2,
      'country': country,
      'lat': lat?.toString(),
      'lon': lon?.toString(),
    };
  }
} 