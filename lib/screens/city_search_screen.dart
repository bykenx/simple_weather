import '../utils/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/services/weather_service.dart';
import 'package:simple_weather/services/city_service.dart';
import 'package:simple_weather/services/weather_cache_service.dart';
import 'package:simple_weather/utils/debounce.dart';

class CitySearchScreen extends StatefulWidget {
  final WeatherService? service;
  final WeatherCacheService? cache;
  const CitySearchScreen({super.key, this.service, this.cache});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  late final WeatherService _weatherService;
  final CityService _cityService = CityService();
  late final WeatherCacheService _weatherCacheService;
  final TextEditingController _searchController = TextEditingController();
  final DebounceUtils _debounce = DebounceUtils();
  List<CityModel> _hotCities = [];
  List<CityModel> _searchResults = [];
  bool _loadingHotCities = true;
  bool _isSearching = false;
  String _query = '';
  String? _searchError;
  String? _hotCitiesError;
  int _searchGeneration = 0;
  CancelToken? _searchCancel;
  final _hotCitiesCancel = CancelToken();

  bool _validQuery(String query) =>
      RegExp(r'[\u4e00-\u9fa5]').hasMatch(query) || query.length >= 2;

  @override
  void initState() {
    super.initState();
    _weatherService = widget.service ?? WeatherService();
    _weatherCacheService = widget.cache ?? WeatherCacheService();
    _loadHotCities();
  }

  Future<void> _loadHotCities() async {
    setState(() {
      _loadingHotCities = true;
      _hotCitiesError = null;
    });
    try {
      final cachedHotCities = await _weatherCacheService.loadHotCities();
      if (!mounted) return;

      if (cachedHotCities != null) {
        setState(() {
          _hotCities = cachedHotCities;
          _loadingHotCities = false;
        });
        return;
      }

      final hotCitiesJson = await _weatherService.getHotCities(
        cancelToken: _hotCitiesCancel,
      );
      if (!mounted) return;
      final cities =
          (hotCitiesJson['topCityList'] as List)
              .map((json) => CityModel.fromJson(json))
              .toList();

      await _weatherCacheService.saveHotCities(cities);
      if (!mounted) return;

      setState(() {
        _hotCities = cities;
        _loadingHotCities = false;
      });
    } catch (e) {
      if (!mounted || _hotCitiesCancel.isCancelled) return;
      setState(() {
        _loadingHotCities = false;
        _hotCitiesError = '加载热门城市失败：$e';
      });
    }
  }

  void _onSearchTextChanged(String value) {
    final query = value.trim();
    final generation = ++_searchGeneration;
    _debounce.cancel();
    _searchCancel?.cancel();
    _searchCancel = null;
    setState(() {
      _query = query;
      _searchResults = [];
      _searchError = null;
      _isSearching = _validQuery(query);
    });
    if (_validQuery(query)) {
      _debounce(() => _searchCity(query, generation));
    }
  }

  Future<void> _searchCity(String query, int generation) async {
    if (!mounted || generation != _searchGeneration) return;
    final cancel = CancelToken();
    _searchCancel = cancel;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final response = await _weatherService.searchCity(
        query,
        cancelToken: cancel,
      );
      if (!mounted || generation != _searchGeneration) return;
      final cities =
          (response['location'] as List)
              .map((json) => CityModel.fromJson(json))
              .toList();
      setState(() {
        _searchResults = cities;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted || generation != _searchGeneration || cancel.isCancelled) {
        return;
      }
      setState(() {
        _isSearching = false;
        _searchError = '搜索城市失败：$e';
      });
    }
  }

  Future<void> _addCity(CityModel city) async {
    try {
      await _cityService.addCity(city);
      await _cityService.setCurrentCity(city);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('城市添加成功')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('添加城市失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100.0,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('添加城市'),
              centerTitle: true,
              expandedTitleScale: 1.5,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorScheme.primaryContainer, colorScheme.surface],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索城市',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: _onSearchTextChanged,
                  ),
                ),
                _isSearching || (_query.isEmpty && _loadingHotCities)
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isNotEmpty
                    ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final city = _searchResults[index];
                        return ListTile(
                          title: Text(city.name),
                          subtitle: Text(
                            '${(city.adm2?.isEmpty ?? true) || city.adm2 == city.name ? '' : '${city.adm2},'}${city.adm1 ?? ''} ${city.country ?? ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addCity(city),
                          ),
                        );
                      },
                    )
                    : _query.isNotEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _searchError ??
                                (_validQuery(_query)
                                    ? '未找到匹配的城市'
                                    : '请输入至少一个汉字或两个字符'),
                          ),
                          if (_searchError != null)
                            TextButton(
                              onPressed:
                                  () => _searchCity(_query, _searchGeneration),
                              child: const Text('重试'),
                            ),
                        ],
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hotCitiesError != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(_hotCitiesError!),
                                TextButton(
                                  onPressed: _loadHotCities,
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            '热门城市',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final tileWidth = (constraints.maxWidth - 20) / 3;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: List.generate(_hotCities.length, (
                                  index,
                                ) {
                                  final city = _hotCities[index];
                                  return InkWell(
                                    onTap: () => _addCity(city),
                                    child: Container(
                                      width: tileWidth,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      decoration: AppThemeUtils.cardDecoration(
                                        context,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_city,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            city.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchGeneration++;
    _searchCancel?.cancel();
    _hotCitiesCancel.cancel();
    _searchController.dispose();
    _debounce.dispose();
    super.dispose();
  }
}
