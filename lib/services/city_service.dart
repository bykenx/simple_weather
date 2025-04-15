import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_weather/models/city_model.dart';

class CityService {
  static const String _citiesKey = 'cities';
  static const String _currentCityKey = 'current_city';
  static final CityService _instance = CityService._internal();
  factory CityService() => _instance;
  CityService._internal();

  Future<List<CityModel>> getCities() async {
    final prefs = await SharedPreferences.getInstance();
    final citiesJson = prefs.getStringList(_citiesKey) ?? [];
    return citiesJson
        .map((json) => CityModel.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addCity(CityModel city) async {
    final cities = await getCities();
    if (cities.any((c) => c.id == city.id)) return;

    final prefs = await SharedPreferences.getInstance();
    cities.add(city);
    await prefs.setStringList(
      _citiesKey,
      cities.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> deleteCity(String cityId) async {
    final cities = await getCities();
    cities.removeWhere((city) => city.id == cityId);
    await _saveCities(cities);
  }

  Future<CityModel?> getCurrentCity() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCityJson = prefs.getString(_currentCityKey);
    if (currentCityJson == null) return null;
    return CityModel.fromJson(jsonDecode(currentCityJson));
  }

  Future<void> setCurrentCity(CityModel city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentCityKey, jsonEncode(city.toJson()));
  }

  Future<void> _saveCities(List<CityModel> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _citiesKey,
      cities.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }
}
