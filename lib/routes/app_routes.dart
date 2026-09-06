import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../screens/weather_preview_screen.dart';
import 'package:simple_weather/screens/city_management_screen.dart';
import 'package:simple_weather/screens/city_search_screen.dart';
import 'package:simple_weather/screens/home_screen.dart';
import 'package:simple_weather/screens/settings_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String weatherPreview = '/weather-preview';
  static const String cityManagement = '/city-management';
  static const String citySearch = '/city-search';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    if (kDebugMode && routeSettings.name == weatherPreview) {
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => const WeatherPreviewScreen(),
      );
    }
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case cityManagement:
        return MaterialPageRoute(builder: (_) => const CityManagementScreen());
      case citySearch:
        return MaterialPageRoute<bool>(
          builder: (_) => const CitySearchScreen(),
        );
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${routeSettings.name}'),
                ),
              ),
        );
    }
  }
}
