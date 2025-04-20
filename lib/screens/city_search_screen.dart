import 'package:flutter/material.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/services/weather_service.dart';
import 'package:simple_weather/services/city_service.dart';
import 'package:simple_weather/services/weather_cache_service.dart';
import 'package:simple_weather/utils/debounce_utils.dart';
import 'package:flutter/foundation.dart';

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final WeatherService _weatherService = WeatherService();
  final CityService _cityService = CityService();
  final WeatherCacheService _weatherCacheService = WeatherCacheService();
  final TextEditingController _searchController = TextEditingController();
  final DebounceUtils _debounce = DebounceUtils();
  List<CityModel> _hotCities = [];
  List<CityModel> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotCities();
  }

  Future<void> _loadHotCities() async {
    try {
      // 尝试从缓存加载热门城市列表
      final cachedHotCities = await _weatherCacheService.loadHotCities();
      
      if (cachedHotCities != null) {
        setState(() {
          _hotCities = cachedHotCities;
          _isLoading = false;
        });
        if (kDebugMode) {
          print('从缓存加载热门城市成功');
        }
        return;
      }
      
      // 如果缓存不存在或已过期，从网络加载
      final hotCitiesJson = await _weatherService.getHotCities();
      final cities =
          (hotCitiesJson['topCityList'] as List)
              .map((json) => CityModel.fromJson(json))
              .toList();
      
      // 保存到缓存
      await _weatherCacheService.saveHotCities(cities);
      
      setState(() {
        _hotCities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载热门城市失败: $e')));
      }
    }
  }

  void _onSearchTextChanged(String query) {
    _debounce(() {
      _searchCity(query);
    });
  }

  Future<void> _searchCity(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _weatherService.searchCity(query);
      final cities =
          (response['location'] as List)
              .map((json) => CityModel.fromJson(json))
              .toList();
      setState(() {
        _searchResults = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('搜索城市失败: $e')));
      }
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
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100.0,
            floating: false,
            backgroundColor: Colors.blue.shade50,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('添加城市'),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade200, Colors.blue.shade50],
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
                _isLoading
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
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: _hotCities.length,
                          itemBuilder: (context, index) {
                            final city = _hotCities[index];
                            return InkWell(
                              onTap: () => _addCity(city),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.location_city,
                                      color: Colors.blue,
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
                          },
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
    _searchController.dispose();
    _debounce.dispose();
    super.dispose();
  }
}
