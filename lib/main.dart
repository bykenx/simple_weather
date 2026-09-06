import 'utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:simple_weather/routes/app_routes.dart';
import 'package:simple_weather/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          theme: AppTheme.build(Brightness.light),
          darkTheme: AppTheme.build(Brightness.dark),
          themeMode: darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
          initialRoute:
              kDebugMode && const bool.fromEnvironment('WEATHER_PREVIEW')
                  ? AppRoutes.weatherPreview
                  : AppRoutes.home,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
