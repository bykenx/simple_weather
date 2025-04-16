import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/models/city_model.dart';
import 'package:simple_weather/models/forecast_days.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';
import 'package:simple_weather/utils/date_utils.dart';
import 'package:simple_weather/services/weather_service.dart';

class ExtendedForecastScreen extends StatefulWidget {
  final CityModel currentCity;

  const ExtendedForecastScreen({super.key, required this.currentCity});

  @override
  State<ExtendedForecastScreen> createState() => _ExtendedForecastScreenState();
}

class _ExtendedForecastScreenState extends State<ExtendedForecastScreen> {
  final WeatherService _weatherService = WeatherService();
  List<DailyWeatherModel>? _dailyForecast;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExtendedForecast();
  }

  Future<void> _loadExtendedForecast() async {
    if (!await _weatherService.isApiConfigured()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先完成API配置')));
      }
      return;
    }

    try {
      final result = await _weatherService.getWeatherForecast(
        lat: widget.currentCity.lat!,
        lon: widget.currentCity.lon!,
        forecastDays: ForecastDays.thirty,
      );

      if (mounted) {
        setState(() {
          _dailyForecast =
              (result['daily'] as List)
                  .map((item) => DailyWeatherModel.fromJson(item))
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadExtendedForecast,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 100.0,
                  floating: false,
                  backgroundColor: Colors.blue.shade50,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('15天天气预报'),
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
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: List.generate(
                                _dailyForecast?.length ?? 0,
                                (index) {
                                  final day = _dailyForecast![index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              WeatherDateUtils.getDayText(
                                                index,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            WeatherIconUtils.getWeatherIcon(
                                              day.icon,
                                            ),
                                            size: 24,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              day.description,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${day.minTemp.toStringAsFixed(1)}° ~ ${day.maxTemp.toStringAsFixed(1)}°',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                ),
              ],
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
