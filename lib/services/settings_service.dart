import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _apiKeyKey = 'api_key';
  static const String _apiHostKey = 'api_host';
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

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
