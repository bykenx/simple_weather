import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SettingsService {
  static const String _apiKeyKey = 'api_key';
  static const String _apiHostKey = 'api_host';
  static const String _darkModeEnabledKey = 'dark_mode_enabled';
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final ValueNotifier<bool> darkModeEnabled = ValueNotifier<bool>(false);
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    darkModeEnabled.value = prefs.getBool(_darkModeEnabledKey) ?? false;
    _initialized = true;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeEnabledKey, enabled);
    darkModeEnabled.value = enabled;
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<String?> getApiHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiHostKey);
  }

  Future<void> setApiHost(String apiHost) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiHostKey, apiHost);
  }

  Future<bool> isSettingsComplete() async {
    final apiKey = await getApiKey();
    final apiHost = await getApiHost();
    return apiKey != null &&
        apiKey.isNotEmpty &&
        apiHost != null &&
        apiHost.isNotEmpty;
  }
}
