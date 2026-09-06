import '../widgets/weather_bottom_bar.dart';
import '../utils/url_utils.dart';
import '../widgets/weather_refresh_indicator.dart';
import '../widgets/weather_scene.dart';
import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../routes/app_routes.dart';
import '../services/city_service.dart';
import '../services/settings_service.dart';
import '../services/weather_load_controller.dart';
import '../widgets/empty_city_view.dart';
import '../widgets/setting_not_complete_view.dart';
import '../widgets/weather_app_bar.dart';
import '../widgets/weather_content_view.dart';
import '../widgets/weather_loading_failed_view.dart';

class HomeScreen extends StatefulWidget {
  final WeatherLoadController? controller;
  const HomeScreen({super.key, this.controller});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final WeatherLoadController _weather;
  final _cityService = CityService();
  final _settings = SettingsService();
  final _pages = PageController();
  List<CityModel> _cities = [];
  int _index = 0;
  bool _configured = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _weather = widget.controller ?? WeatherLoadController();
    _weather.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _initialize() async {
    final configured = await _settings.isSettingsComplete();
    if (!mounted) return;
    setState(() => _configured = configured);
    await _loadCities();
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _loadCities() async {
    final previousId = _cities.isEmpty ? null : _cities[_index].id;
    final cities = await _cityService.getCities();
    final selected = await _cityService.getCurrentCity();
    if (!mounted) return;
    final selectedId = selected?.id ?? previousId;
    final index = cities.indexWhere((c) => c.id == selectedId);
    setState(() {
      _cities = cities;
      _index = index < 0 ? 0 : index;
    });
    await Future.wait(cities.map(_weather.restore));
    if (mounted) {
      setState(() => _initializing = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients && _cities.isNotEmpty) {
          _pages.jumpToPage(_index);
        }
      });
      _refreshIfNeeded();
    }
  }

  Future<void> _refreshIfNeeded() async {
    if (!_configured || _cities.isEmpty) return;
    final city = _cities[_index];
    if (_weather.data(city).isExpired) await _weather.refresh(city);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshIfNeeded();
  }

  Future<void> _manage() async {
    await Navigator.pushNamed(context, AppRoutes.cityManagement);
    if (mounted) await _loadCities();
  }

  Future<void> _openMap() async {
    if (_cities.isEmpty) return;
    final city = _cities[_index];
    if (city.lat == null || city.lon == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前城市暂无坐标')));
      return;
    }
    try {
      await UrlUtils.launchUrlInBrowser(
        'https://www.openstreetmap.org/?mlat=${city.lat}&mlon=${city.lon}#map=11/${city.lat}/${city.lon}',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂时无法打开地图，请稍后重试')));
      }
    }
  }

  Future<void> _configure() async {
    await Navigator.pushNamed(context, AppRoutes.settings);
    if (!mounted) return;
    final configured = await _settings.isSettingsComplete();
    if (!mounted) return;
    setState(() => _configured = configured);
    if (configured && _cities.isNotEmpty) {
      await _weather.refresh(_cities[_index]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weather.removeListener(_changed);
    if (widget.controller == null) _weather.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing || !_configured || _cities.isEmpty) {
      return _buildScaffold(context);
    }
    final scene = WeatherScene.fromWeather(
      _weather.data(_cities[_index]).weather,
    );
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final homeTheme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        onSurface: Colors.white,
        onSurfaceVariant: const Color(0xFFD6EDF5),
        primary: const Color(0xFFB9E9FF),
        surface: dark ? const Color(0xFF102A40) : const Color(0xFF6395AD),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
    return Theme(
      data: homeTheme,
      child: Builder(
        builder:
            (context) => Stack(
              fit: StackFit.expand,
              children: [
                WeatherSceneBackground(scene: scene),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            dark
                                ? const [Color(0x66071525), Color(0xCC0A192B)]
                                : const [Color(0x001E648F), Color(0x665F98A5)],
                      ),
                    ),
                  ),
                ),
                _buildScaffold(context),
              ],
            ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _configured && _cities.isNotEmpty ? Colors.transparent : null,
      extendBody: true,
      bottomNavigationBar:
          _configured && _cities.isNotEmpty
              ? WeatherBottomBar(
                cityCount: _cities.length,
                currentIndex: _index,
                onCitySelected:
                    (index) => _pages.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                onMap: _openMap,
                onCities: _manage,
              )
              : null,
      body:
          _initializing
              ? const Center(child: WeatherLoadingDots())
              : !_configured
              ? SettingNotCompleteView(onSettings: _configure)
              : _cities.isEmpty
              ? EmptyCityView(onAddCity: _manage)
              : ScrollConfiguration(
                // Stretch overscroll introduces an offscreen layer that changes
                // backdrop-filter sampling while the finger is held at an edge.
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _cities.length,
                  onPageChanged: (index) {
                    if (index >= _cities.length) return;
                    setState(() => _index = index);
                    _cityService.setCurrentCity(_cities[index]);
                    _refreshIfNeeded();
                  },
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final data = _weather.data(city);
                    final daily = data.dailyForecast;
                    return WeatherRefreshIndicator(
                      onRefresh: () => _weather.refresh(city),
                      child: CustomScrollView(
                        key: PageStorageKey('weather-${city.id}'),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        slivers: [
                          WeatherAppBar(
                            weather: data.weather,
                            dailyForecast:
                                daily == null || daily.isEmpty
                                    ? null
                                    : daily.first,
                            cityName: city.name,
                            currentCityIndex: index,
                            totalCities: _cities.length,
                            pageController: _pages,
                            onSettingsPressed: _configure,
                          ),
                          if (!data.hasData)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child:
                                  data.isLoading
                                      ? const Center(child: WeatherLoadingDots())
                                      : WeatherLoadingFailedView(
                                        onRetry: () => _weather.refresh(city),
                                      ),
                            )
                          else
                            WeatherContentView(
                              data: data,
                              onMap: _openMap,
                              onRetry: (module) => _weather.retry(city, module),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
