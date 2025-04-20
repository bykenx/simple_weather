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
import 'package:simple_weather/services/weather_cache_service.dart';
import 'package:simple_weather/services/weather_service.dart';
import 'package:simple_weather/widgets/empty_city_view.dart';
import 'package:simple_weather/widgets/loading_overlay.dart';
import 'package:simple_weather/widgets/setting_not_complete_view.dart';
import 'package:simple_weather/widgets/weather_app_bar.dart';
import 'package:simple_weather/widgets/weather_content_view.dart';
import 'package:simple_weather/widgets/weather_loading_failed_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final WeatherService _weatherService = WeatherService();
  final CityService _cityService = CityService();
  final SettingsService _settingsService = SettingsService();
  final WeatherCacheService _weatherCacheService = WeatherCacheService();
  bool _isLoading = false;
  bool _isScrolling = false;
  bool _isSettingsComplete = false;

  // 页面滑动处理
  bool _handleSwipe = true;
  double _swipeStartX = 0.0;
  double _swipeDelta = 0.0;
  final double _dragThreshold = 100.0;

  // 城市相关变量
  List<CityModel> _cities = [];
  int _cityIndex = 0;
  final Map<String, CityWeatherData> _cityWeatherDataMap = {};
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCities();
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshWeatherData();
    }
  }

  bool _isValidData(CityWeatherData? data) {
    return data != null && !data.isExpired && data.hasData;
  }

  Future<void> _checkAndRefreshWeatherData() async {
    if (_cities.isEmpty || _cityIndex >= _cities.length) return;

    final city = _cities[_cityIndex];
    final cityData = _cityWeatherDataMap[city.uniqueName];

    if (!_isValidData(cityData)) {
      await _loadCityWeather(city, showOverlay: false);
    }
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
    });

    // 设置当前选中的城市索引
    if (currentCity != null) {
      final index = cities.indexWhere((city) => city == currentCity);
      if (index != -1) {
        setState(() {
          _cityIndex = index;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_cityIndex);
        } else {
          _pageController = PageController(initialPage: _cityIndex);
        }
      }
    }

    // 一次性预加载所有城市的缓存数据
    await _preloadCitiesFromCache();

    // 如果当前城市没有数据或数据过期，则从网络加载
    if (_cityIndex < _cities.length) {
      final currentCity = _cities[_cityIndex];
      final currentCityData = _cityWeatherDataMap[currentCity.uniqueName];
      if (currentCityData == null ||
          !currentCityData.hasData ||
          currentCityData.isExpired) {
        await _loadCityWeather(currentCity);
      }
    }
  }

  // 从缓存预加载所有城市的天气数据
  Future<void> _preloadCitiesFromCache() async {
    for (final city in _cities) {
      final cachedData = await _weatherCacheService.loadWeatherData(city);
      if (_isValidData(cachedData)) {
        setState(() {
          _cityWeatherDataMap[city.uniqueName] = cachedData!;
        });
        if (kDebugMode) {
          print('从缓存预加载 ${city.name} 的天气数据');
        }
      }
    }
  }

  Future<void> _loadSettings() async {
    _isSettingsComplete = await _settingsService.isSettingsComplete();
    setState(() {});
  }

  // 加载指定城市的天气数据
  Future<void> _loadCityWeather(CityModel city, {bool? showOverlay}) async {
    if (!_cityWeatherDataMap.containsKey(city.uniqueName)) {
      _cityWeatherDataMap[city.uniqueName] = CityWeatherData(city);
    }

    final cityData = _cityWeatherDataMap[city.uniqueName]!;

    // 清除之前的错误状态
    cityData.clearError();

    showOverlay = showOverlay ?? !cityData.hasData;

    if (showOverlay) {
      setState(() {
        cityData.isLoading = true;
        _isLoading = true;
      });
    }

    if (!await _weatherService.isApiConfigured()) {
      _showErrorSnackBar('请先完成API配置', showToSettings: true);
      if (showOverlay) {
        setState(() {
          cityData.isLoading = false;
          _isLoading = false;
        });
      }
      return;
    }

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
        if (city == _cities[_cityIndex] && showOverlay == true) {
          _isLoading = false;
        }
      });

      // 将天气数据保存到缓存
      await _weatherCacheService.saveWeatherData(city.uniqueName, cityData);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _showErrorSnackBar(e.toString());
      if (showOverlay) {
        setState(() {
          cityData.isLoading = false;

          if (city == _cities[_cityIndex] && showOverlay == true) {
            _isLoading = false;
          }

          cityData.setError(e.toString());
        });
      }
    }
  }

  Future<void> _loadCurrentCityWeather({
    bool? showOverlay,
    bool forceRefresh = false,
  }) async {
    if (_cities.isEmpty || _cityIndex >= _cities.length) return;

    final city = _cities[_cityIndex];
    final cityData = _cityWeatherDataMap[city.uniqueName];

    // 强制刷新或数据无效时，直接从网络加载
    if (forceRefresh || !_isValidData(cityData)) {
      return _loadCityWeather(city, showOverlay: showOverlay);
    }

    // 数据有效且不需要刷新，只更新UI状态
    if (showOverlay == true) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 页面切换回调
  void _onPageChanged(int index) async {
    if (index < 0 || index >= _cities.length) return;

    final city = _cities[index];
    final cityData = _cityWeatherDataMap[city.uniqueName];

    setState(() {
      _cityIndex = index;
      if (cityData != null) {
        _isLoading = cityData.isLoading;
      }
    });

    // 如果数据无效，直接从网络加载，不再检查缓存
    if (!_isValidData(cityData)) {
      _loadCityWeather(city);
    }
  }

  // 显示错误提示
  void _showErrorSnackBar(String message, {bool showToSettings = false}) {
    if (!mounted) return;

    // 移除当前显示的 SnackBar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action:
            showToSettings
                ? SnackBarAction(label: '去设置', onPressed: _onSettingsPressed)
                : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 城市管理
  void _onCityManagement() async {
    await Navigator.pushNamed(context, AppRoutes.cityManagement);
    _loadCities();
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
          await _loadCurrentCityWeather();
        }
      },
      child: Stack(
        children: [
          GestureDetector(
            onHorizontalDragStart: (details) {
              // 如果没有城市或只有一个城市，不处理滑动
              if (_cities.isEmpty || _cities.length <= 1) {
                return;
              }
              setState(() {
                _swipeStartX = details.localPosition.dx;
                _swipeDelta = 0.0;
                _handleSwipe = true;
              });
            },
            onHorizontalDragUpdate: (details) {
              // 如果不处理滑动，直接返回
              if (!_handleSwipe) return;

              // 计算水平滑动距离
              _swipeDelta = details.localPosition.dx - _swipeStartX;

              // 判断是否应该处理为水平滑动
              double verticalDelta =
                  (details.localPosition.dy - details.globalPosition.dy).abs();
              double horizontalDelta = _swipeDelta.abs();

              // 如果垂直滑动距离大于水平滑动距离的1.2倍，不处理水平滑动
              if (verticalDelta > horizontalDelta * 1.2 &&
                  horizontalDelta < 20) {
                setState(() {
                  _handleSwipe = false;
                });
                return;
              }

              // 直接控制PageView的滚动位置实现过渡效果
              if (_pageController.hasClients) {
                final currentOffset = _pageController.offset;
                final targetOffset = currentOffset - details.delta.dx;

                // 确保不超出边界
                final maxOffset =
                    MediaQuery.of(context).size.width * (_cities.length - 1);
                final boundedOffset = targetOffset.clamp(0.0, maxOffset);

                // 直接设置滚动位置
                _pageController.position.jumpTo(boundedOffset);
              }
            },
            onHorizontalDragEnd: (details) {
              // 如果不处理滑动，直接返回
              if (!_handleSwipe) return;

              double velocity = details.primaryVelocity ?? 0;
              double currentPage =
                  _pageController.page ?? _cityIndex.toDouble();

              // 根据滑动距离和速度决定是否切换页面
              if (_swipeDelta.abs() > _dragThreshold || velocity.abs() > 100) {
                int targetPage;

                if (_swipeDelta > 0 || velocity > 100) {
                  // 向右滑动，显示上一个城市
                  targetPage = currentPage.floor();
                  if (targetPage == currentPage && targetPage > 0) {
                    targetPage -= 1;
                  }
                } else {
                  // 向左滑动，显示下一个城市
                  targetPage = currentPage.ceil();
                  if (targetPage == currentPage &&
                      targetPage < _cities.length - 1) {
                    targetPage += 1;
                  }
                }

                // 确保目标页面在有效范围内
                targetPage = targetPage.clamp(0, _cities.length - 1);

                // 平滑切换到目标页面
                _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              } else {
                // 回弹到当前页面
                _pageController.animateToPage(
                  currentPage.round(),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: Scaffold(
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
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _isScrolling = true;
                              });
                            });
                          } else if (notification is ScrollEndNotification) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _isScrolling = false;
                              });
                            });
                          }
                          return false;
                        },
                        child: NestedScrollView(
                          headerSliverBuilder: (context, innerBoxIsScrolled) {
                            final currentCity = _cities[_cityIndex];
                            final currentCityData =
                                _cityWeatherDataMap[currentCity.uniqueName];

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
                            physics:
                                const BouncingScrollPhysics(), // 使用支持回弹效果的滚动物理
                            itemBuilder: (context, index) {
                              if (index < 0 || index >= _cities.length) {
                                return const SizedBox.shrink();
                              }

                              final city = _cities[index];
                              final cityData =
                                  _cityWeatherDataMap[city.uniqueName];

                              // 显示加载失败视图
                              if (cityData?.hasError == true) {
                                return WeatherLoadingFailedView(
                                  errorMessage: cityData!.errorMessage,
                                  onRetry:
                                      () => _loadCityWeather(
                                        city,
                                        showOverlay: true,
                                      ),
                                );
                              }

                              if (cityData?.weather == null) {
                                return const SizedBox.shrink();
                              }

                              return WeatherContentView(
                                weather: cityData!.weather!,
                                dailyForecast: cityData.dailyForecast,
                                hourlyForecast: cityData.hourlyForecast,
                                warnings: cityData.warnings,
                                airQuality: cityData.airQuality,
                                city: city,
                                onRefresh:
                                    () => _loadCurrentCityWeather(
                                      forceRefresh: true,
                                    ),
                              );
                            },
                          ),
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
