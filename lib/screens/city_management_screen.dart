import 'package:flutter/material.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/routes/app_routes.dart';
import 'package:simple_weather/services/city_service.dart';
import 'package:simple_weather/widgets/city_card.dart';

class CityManagementScreen extends StatefulWidget {
  final Future<void> Function(List<CityModel>)? saveOrder;
  const CityManagementScreen({super.key, this.saveOrder});

  @override
  State<CityManagementScreen> createState() => _CityManagementScreenState();
}

class _CityManagementScreenState extends State<CityManagementScreen> {
  final CityService _cityService = CityService();
  List<CityModel> _cities = [];
  CityModel? _currentCity;
  bool _isLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _cityService.getCities();
    final currentCity = await _cityService.getCurrentCity();
    if (!mounted) return;
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

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_saving) return;
    final previous = List<CityModel>.of(_cities);
    setState(() {
      _saving = true;
      if (newIndex > oldIndex) newIndex--;
      final city = _cities.removeAt(oldIndex);
      _cities.insert(newIndex, city);
    });
    try {
      await (widget.saveOrder ?? _cityService.reorderCities)(_cities);
    } catch (_) {
      if (mounted) {
        setState(() => _cities = previous);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存城市顺序失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
              title: const Text('城市管理'),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed:
                    _saving
                        ? null
                        : () async {
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
                    : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      onReorder: _reorder,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cities.length,
                      itemBuilder: (context, index) {
                        final city = _cities[index];
                        final isCurrent = _currentCity?.id == city.id;
                        return Container(
                          key: ValueKey(city.id),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: IgnorePointer(
                            ignoring: _saving,
                            child: Row(
                              children: [
                                Expanded(
                                  child: CityCard(
                                    city: city,
                                    isCurrent: isCurrent,
                                    onDelete: () {
                                      if (!_saving) _deleteCity(city);
                                    },
                                    onTap: () {
                                      if (!_saving) _setCurrentCity(city);
                                    },
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  enabled: !_saving,
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.drag_handle,
                                      semanticLabel: '拖动排序',
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
