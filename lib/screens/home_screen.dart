import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/forecast_days.dart';
import 'package:simple_weather/routes/app_routes.dart';
import 'package:simple_weather/services/city_service.dart';
import 'package:simple_weather/services/weather_service.dart';
import 'package:simple_weather/widgets/air_quality_card.dart';
import 'package:simple_weather/widgets/current_weather_info.dart';
import 'package:simple_weather/widgets/daily_forecast_card.dart';
import 'package:simple_weather/widgets/hourly_forecast_card.dart';
import 'package:simple_weather/widgets/weather_details_card.dart';
import 'package:simple_weather/widgets/weather_warning_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final CityService _cityService = CityService();
  final ScrollController _scrollController = ScrollController();
  LiveWeatherModel? _weather;
  List<DailyWeatherModel>? _dailyForecast;
  List<HourlyWeatherModel>? _hourlyForecast;
  List<WeatherWarningModel>? _warnings;
  AirQualityModel? _airQuality;
  CityModel? _currentCity;
  bool _isLoading = false;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentCityWeather();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    if (_scrollController.position.isScrollingNotifier.value) {
      if (!_isScrolling) {
        setState(() {
          _isScrolling = true;
        });
      }
    } else {
      if (_isScrolling) {
        setState(() {
          _isScrolling = false;
        });
      }
    }
  }

  Future<void> _loadCurrentCityWeather({bool showOverlay = false}) async {
    if (showOverlay) {
      setState(() {
        _isLoading = true;
      });
    }

    if (!await _weatherService.isApiConfigured()) {
      _showErrorSnackBar('请先完成API配置', showAddCity: false);
      if (showOverlay) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final currentCity = await _cityService.getCurrentCity();
    if (currentCity == null) {
      _showErrorSnackBar('请先添加城市', showAddCity: true);
      if (showOverlay) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _weatherService.getLiveWeather(
          lat: currentCity.lat!,
          lon: currentCity.lon!,
        ),
        _weatherService.getWeatherForecast(
          lat: currentCity.lat!,
          lon: currentCity.lon!,
          forecastDays: ForecastDays.three,
        ),
        _weatherService.getHourlyWeather(
          lat: currentCity.lat!,
          lon: currentCity.lon!,
        ),
        _weatherService.getWeatherWarnings(
          lat: currentCity.lat!,
          lon: currentCity.lon!,
        ),
        _weatherService.getAirQuality(
          lat: currentCity.lat!,
          lon: currentCity.lon!,
        ),
      ]);

      setState(() {
        _currentCity = currentCity;
        _weather = LiveWeatherModel.fromJson(results[0]['now']);
        _dailyForecast =
            (results[1]['daily'] as List)
                .map((item) => DailyWeatherModel.fromJson(item))
                .toList();
        _hourlyForecast =
            (results[2]['hourly'] as List)
                .map((item) => HourlyWeatherModel.fromJson(item))
                .toList();
        _warnings = results[3] as List<WeatherWarningModel>;
        _airQuality = results[4] as AirQualityModel;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _showErrorSnackBar(e.toString(), showAddCity: false);
      if (showOverlay) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message, {bool showAddCity = false}) {
    if (!mounted) return;

    // 移除当前显示的 SnackBar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: showAddCity ? '添加城市' : '去设置',
          onPressed: () {
            if (showAddCity) {
              Navigator.pushNamed(context, AppRoutes.cityManagement);
            } else {
              Navigator.pushNamed(context, AppRoutes.settings);
            }
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSettingsUpdatedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('设置已更新'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onCityManagement() async {
    final currentCity = _currentCity;
    await Navigator.pushNamed(context, AppRoutes.cityManagement);
    final newCity = await _cityService.getCurrentCity();
    if (newCity?.id != currentCity?.id) {
      _loadCurrentCityWeather(showOverlay: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (ModalRoute.of(context)?.settings.name == '/settings') {
          await _loadCurrentCityWeather(showOverlay: true);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.blue.shade50,
            floatingActionButton: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isScrolling ? 0.5 : 1.0,
              child: FloatingActionButton(
                onPressed: () async {
                  if (!await _weatherService.isApiConfigured()) {
                    _showErrorSnackBar('请先完成API配置', showAddCity: false);
                    return;
                  }
                  _onCityManagement();
                },
                child: const Icon(Icons.location_city),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () => _loadCurrentCityWeather(showOverlay: false),
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollStartNotification) {
                    setState(() {
                      _isScrolling = true;
                    });
                  } else if (notification is ScrollEndNotification) {
                    setState(() {
                      _isScrolling = false;
                    });
                  }
                  return false;
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 100.0,
                      floating: false,
                      backgroundColor: Colors.blue.shade50,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(_currentCity?.name ?? ''),
                        centerTitle: true,
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue.shade200,
                                Colors.blue.shade50,
                              ],
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              AppRoutes.settings,
                            );
                            if (result == true) {
                              _showSettingsUpdatedSnackBar();
                            }
                          },
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child:
                          _weather != null
                              ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    CurrentWeatherInfo(
                                      weather: _weather!,
                                      dailyForecast: _dailyForecast?.first,
                                    ),
                                    if (_warnings != null &&
                                        _warnings!.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      WeatherWarningCard(warnings: _warnings!),
                                    ],
                                    const SizedBox(height: 20),
                                    WeatherDetailsCard(weather: _weather!),
                                    const SizedBox(height: 20),
                                    if (_airQuality != null) ...[
                                      AirQualityCard(airQuality: _airQuality!),
                                      const SizedBox(height: 20),
                                    ],
                                    HourlyForecastCard(
                                      hourlyForecast: _hourlyForecast!,
                                    ),
                                    const SizedBox(height: 20),
                                    DailyForecastCard(
                                      dailyForecast: _dailyForecast!,
                                      currentCity: _currentCity!,
                                    ),
                                  ],
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
