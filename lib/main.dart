import 'package:flutter/material.dart';
import 'package:simple_weather/routes/app_routes.dart';
import 'package:simple_weather/services/settings_service.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WeatherIconUtils.ensureInitialized();
  await SettingsService().ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    return ValueListenableBuilder<bool>(
      valueListenable: settingsService.darkModeEnabled,
      builder: (context, darkModeEnabled, _) {
        return MaterialApp(
          title: '简单天气',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
