import 'package:flutter/material.dart';
import 'package:simple_weather/screens/city_management_screen.dart';
import 'package:simple_weather/screens/city_search_screen.dart';
import 'package:simple_weather/screens/home_screen.dart';
import 'package:simple_weather/screens/settings_screen.dart';
import 'package:simple_weather/screens/warning_detail_screen.dart';
import 'package:simple_weather/screens/air_quality_detail_screen.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/air_quality_model.dart';

class AppRoutes {
  static const String home = '/';
  static const String cityManagement = '/city-management';
  static const String citySearch = '/city-search';
  static const String settings = '/settings';
  static const String warningDetail = '/warning-detail';
  static const String airQualityDetail = '/air-quality-detail';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
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
      case warningDetail:
        final warning = routeSettings.arguments as WeatherWarningModel;
        return MaterialPageRoute(
          builder: (_) => WarningDetailScreen(warning: warning),
        );
      case airQualityDetail:
        final airQuality = routeSettings.arguments as AirQualityModel;
        return MaterialPageRoute(
          builder: (_) => AirQualityDetailScreen(airQuality: airQuality),
        );
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
