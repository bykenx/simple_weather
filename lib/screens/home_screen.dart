import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simple_weather/models/air_quality_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/city_weather_data.dart';
import 'package:simple_weather/models/forecast_days.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/routes/app_routes.dart';
import 'package:simple_weather/services/city_service.dart';
import 'package:simple_weather/services/settings_service.dart';
import 'package:simple_weather/services/weather_service.dart';
import 'package:simple_weather/widgets/empty_city_view.dart';
import 'package:simple_weather/widgets/loading_overlay.dart';
import 'package:simple_weather/widgets/setting_not_complete_view.dart';
import 'package:simple_weather/widgets/weather_app_bar.dart';
import 'package:simple_weather/widgets/weather_content_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final CityService _cityService = CityService();
  final SettingsService _settingsService = SettingsService();
  CityModel? _currentCity;
  bool _isLoading = false;
  bool _isScrolling = false;
  bool _isSettingsComplete = false;

  // 城市相关变量
  List<CityModel> _cities = [];
  int _cityIndex = 0;
  List<CityWeatherData> _cityWeatherDataList = [];
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 加载城市列表
  Future<void> _loadCities() async {
    final cities = await _cityService.getCities();
    final currentCity = await _cityService.getCurrentCity();

    if (cities.isEmpty) {
      return;
    }

    setState(() {
      _cities = cities;
      _cityWeatherDataList =
          cities.map((city) => CityWeatherData(city)).toList();
    });

    // 设置当前选中的城市索引
    if (currentCity != null) {
      final index = cities.indexWhere(
        (city) => city.id == currentCity.id && city.name == currentCity.name,
      );
      if (index != -1) {
        setState(() {
          _cityIndex = index;
        });
        _pageController = PageController(initialPage: _cityIndex);
      }
    }

    _loadCityWeather(_cityIndex, showOverlay: false);
  }

  Future<void> _loadSettings() async {
    _isSettingsComplete = await _settingsService.isSettingsComplete();
    setState(() {});
  }

  // 加载指定城市的天气数据
  Future<void> _loadCityWeather(
    int cityIndex, {
    bool showOverlay = false,
  }) async {
    if (cityIndex < 0 || cityIndex >= _cityWeatherDataList.length) return;

    final cityData = _cityWeatherDataList[cityIndex];

    if (showOverlay) {
      setState(() {
        cityData.isLoading = true;
        _isLoading = true;
      });
    }

    if (!await _weatherService.isApiConfigured()) {
      _showErrorSnackBar('请先完成API配置', showAddCity: false);
      if (showOverlay) {
        setState(() {
          cityData.isLoading = false;
          _isLoading = false;
        });
      }
      return;
    }

    final city = cityData.city;

    try {
      final results = await Future.wait<dynamic>([
        _weatherService.getLiveWeather(lat: city.lat!, lon: city.lon!),
        _weatherService.getWeatherForecast(
          lat: city.lat!,
          lon: city.lon!,
          forecastDays: ForecastDays.three,
        ),
        _weatherService.getHourlyWeather(lat: city.lat!, lon: city.lon!),
        _weatherService.getWeatherWarnings(lat: city.lat!, lon: city.lon!),
        _weatherService.getAirQuality(lat: city.lat!, lon: city.lon!),
      ]);

      setState(() {
        cityData.weather = LiveWeatherModel.fromJson(results[0]['now']);
        cityData.lastUpdated = DateTime.now();
        cityData.dailyForecast =
            (results[1]['daily'] as List)
                .map((item) => DailyWeatherModel.fromJson(item))
                .toList();
        cityData.hourlyForecast =
            (results[2]['hourly'] as List)
                .map((item) => HourlyWeatherModel.fromJson(item))
                .toList();
        cityData.warnings = results[3] as List<WeatherWarningModel>;
        cityData.airQuality = results[4] as AirQualityModel;
        cityData.isLoading = false;

        // 更新当前页面的数据
        if (cityIndex == _cityIndex) {
          _currentCity = city;
          // 只有在显示遮罩时才设置 _isLoading 为 false
          if (showOverlay) {
            _isLoading = false;
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _showErrorSnackBar(e.toString(), showAddCity: false);
      if (showOverlay) {
        setState(() {
          cityData.isLoading = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCurrentCityWeather({bool showOverlay = false}) async {
    return _loadCityWeather(_cityIndex, showOverlay: showOverlay);
  }

  // 页面切换回调
  void _onPageChanged(int index) {
    final cityData = _cityWeatherDataList[index];
    setState(() {
      _cityIndex = index;
      _currentCity = cityData.city;
      _isLoading = cityData.isLoading;
    });

    _cityService.setCurrentCity(_cities[index]);
    if (cityData.isExpired || !cityData.hasData) {
      _loadCityWeather(index, showOverlay: !cityData.hasData);
    }
  }

  // 显示错误提示
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
              _onCityManagement();
            } else {
              _onSettingsPressed();
            }
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 城市管理
  void _onCityManagement() async {
    final currentCity = _currentCity;
    await Navigator.pushNamed(context, AppRoutes.cityManagement);
    final newCity = await _cityService.getCurrentCity();
    if (newCity?.id != currentCity?.id) {
      _loadCurrentCityWeather(showOverlay: true);
    }
  }

  // 设置按钮点击回调
  Future<void> _onSettingsPressed() async {
    final result = await Navigator.pushNamed(context, AppRoutes.settings);
    if (result == true) {
      _loadSettings();
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
            floatingActionButton:
                _cities.isEmpty
                    ? null
                    : AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isScrolling ? 0.5 : 1.0,
                      child: FloatingActionButton(
                        onPressed: _onCityManagement,
                        tooltip: '城市管理',
                        child: const Icon(Icons.location_city),
                      ),
                    ),
            body:
                !_isSettingsComplete
                    ? SettingNotCompleteView(onSettings: _onSettingsPressed)
                    : _cities.isEmpty
                    ? EmptyCityView(onAddCity: _onCityManagement)
                    : NotificationListener<ScrollNotification>(
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
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          final currentCityData =
                              _cityIndex < _cityWeatherDataList.length
                                  ? _cityWeatherDataList[_cityIndex]
                                  : null;

                          return [
                            WeatherAppBar(
                              weather: currentCityData?.weather,
                              dailyForecast:
                                  currentCityData?.dailyForecast?.first,
                              cityName: currentCityData?.city.name,
                              currentCityIndex: _cityIndex,
                              totalCities: _cities.length,
                              pageController: _pageController,
                              onSettingsPressed: _onSettingsPressed,
                            ),
                          ];
                        },
                        body: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: _cities.length,
                          itemBuilder: (context, index) {
                            final cityData = _cityWeatherDataList[index];

                            if (cityData.weather == null) {
                              return const SizedBox.shrink();
                            }

                            return WeatherContentView(
                              weather: cityData.weather!,
                              dailyForecast: cityData.dailyForecast,
                              hourlyForecast: cityData.hourlyForecast,
                              warnings: cityData.warnings,
                              airQuality: cityData.airQuality,
                              city: cityData.city,
                              onRefresh: () => _loadCurrentCityWeather(),
                            );
                          },
                        ),
                      ),
                    ),
          ),
          LoadingOverlay(isLoading: _isLoading),
        ],
      ),
    );
  }
}
