import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WeatherIconUtils {
  static const String _defaultFontFamily = 'QWeatherIcons';
  static const String _mappingAssetPath = 'assets/qweather_weather_code_map.json';

  static String _qWeatherIconsFontFamily = _defaultFontFamily;
  static Map<String, int> _iconCodeToCodePoint = <String, int>{};
  static Map<String, int> _filledIconCodeToCodePoint = <String, int>{};
  static Map<String, String> _iconCodeToDescription = <String, String>{};
  static Future<void>? _initFuture;

  static Future<void> ensureInitialized() {
    return _initFuture ??= _loadMappingsFromJson();
  }

  static Future<void> _loadMappingsFromJson() async {
    try {
      final raw = await rootBundle.loadString(_mappingAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final root = decoded.cast<String, dynamic>();

      final fontFamily = root['fontFamily'];
      if (fontFamily is String && fontFamily.trim().isNotEmpty) {
        _qWeatherIconsFontFamily = fontFamily.trim();
      }

      _iconCodeToCodePoint = _parseIconMap(root['regular']);
      _filledIconCodeToCodePoint = _parseIconMap(root['filled']);
      _iconCodeToDescription = _parseDescriptionMap(root['descriptions']);
    } catch (_) {
      _qWeatherIconsFontFamily = _defaultFontFamily;
      _iconCodeToCodePoint = <String, int>{};
      _filledIconCodeToCodePoint = <String, int>{};
      _iconCodeToDescription = <String, String>{};
    }
  }

  static Map<String, int> _parseIconMap(Object? source) {
    if (source is! Map) return <String, int>{};
    final result = <String, int>{};
    source.forEach((key, value) {
      if (key is! String) return;
      final codePoint = _parseCodePoint(value);
      if (codePoint == null) return;
      result[key.trim()] = codePoint;
    });
    return result;
  }

  static int? _parseCodePoint(Object? value) {
    if (value is int) return value;
    if (value is! String) return null;

    final s = value.trim().toLowerCase();
    if (s.isEmpty) return null;

    final normalized = s.startsWith('0x') ? s.substring(2) : s;
    final hex = normalized.replaceAll(RegExp(r'[^0-9a-f]'), '');
    if (hex.isEmpty) return null;

    return int.tryParse(hex, radix: 16);
  }

  static Map<String, String> _parseDescriptionMap(Object? source) {
    if (source is! Map) return <String, String>{};
    final result = <String, String>{};
    source.forEach((key, value) {
      if (key is! String) return;
      if (value is! String) return;
      final k = key.trim();
      final v = value.trim();
      if (k.isEmpty || v.isEmpty) return;
      result[k] = v;
    });
    return result;
  }

  static IconData getWeatherIcon(String iconCode, {bool filled = false}) {
    final normalized = iconCode.trim();
    final codePoint =
        filled
            ? (_filledIconCodeToCodePoint[normalized] ??
                _iconCodeToCodePoint[normalized] ??
                _filledIconCodeToCodePoint['999'] ??
                _iconCodeToCodePoint['999'])
            : (_iconCodeToCodePoint[normalized] ?? _iconCodeToCodePoint['999']);
    if (codePoint == null) return Icons.help_outline;
    return IconData(codePoint, fontFamily: _qWeatherIconsFontFamily);
  }

  static String getIconDescription(String iconCode) {
    final normalized = iconCode.trim();
    return _iconCodeToDescription[normalized] ??
        _iconCodeToDescription['999'] ??
        '未知';
  }
}
