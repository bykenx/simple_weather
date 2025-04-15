import 'package:flutter/material.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/routes/app_routes.dart';
import 'package:simple_weather/services/city_service.dart';
import 'package:simple_weather/widgets/city_card.dart';

class CityManagementScreen extends StatefulWidget {
  const CityManagementScreen({super.key});

  @override
  State<CityManagementScreen> createState() => _CityManagementScreenState();
}

class _CityManagementScreenState extends State<CityManagementScreen> {
  final CityService _cityService = CityService();
  List<CityModel> _cities = [];
  CityModel? _currentCity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _cityService.getCities();
    final currentCity = await _cityService.getCurrentCity();
    setState(() {
      _cities = cities;
      _currentCity = currentCity;
      _isLoading = false;
    });
  }

  Future<void> _deleteCity(CityModel city) async {
    await _cityService.deleteCity(city.id);
    await _loadCities();
  }

  Future<void> _setCurrentCity(CityModel city) async {
    await _cityService.setCurrentCity(city);
    await _loadCities();
    if (mounted) {
      Navigator.pop(context, true);
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
              title: const Text('城市管理'),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  final result = await Navigator.pushNamed<bool>(
                    context,
                    AppRoutes.citySearch,
                  );
                  if (result == true) {
                    _loadCities(); // 如果返回 true，则刷新城市列表
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _cities.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('暂无城市，请添加城市'),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.pushNamed<bool>(
                                context,
                                AppRoutes.citySearch,
                              );
                              if (result == true) {
                                _loadCities();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('添加城市'),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cities.length,
                      itemBuilder: (context, index) {
                        final city = _cities[index];
                        final isCurrent = _currentCity?.id == city.id;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: CityCard(
                            city: city,
                            isCurrent: isCurrent,
                            onDelete: () => _deleteCity(city),
                            onTap: () => _setCurrentCity(city),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
