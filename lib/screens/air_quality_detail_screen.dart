import 'package:flutter/material.dart';
import 'package:simple_weather/models/air_quality_model.dart';

class AirQualityDetailScreen extends StatelessWidget {
  final AirQualityModel airQuality;

  const AirQualityDetailScreen({super.key, required this.airQuality});

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.red.shade900;
  }

  String _formatValue(double value, String code) {
    switch (code) {
      case 'pm2p5':
      case 'pm10':
        return '${value.toStringAsFixed(1)} μg/m³';
      case 'no2':
      case 'o3':
        return '${value.toStringAsFixed(1)} ppb';
      case 'co':
        return '${value.toStringAsFixed(1)} ppm';
      default:
        return value.toStringAsFixed(1);
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
              title: const Text('空气质量'),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _getAqiColor(airQuality.aqi),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          airQuality.aqi.toString(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          airQuality.category,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '健康信息',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    airQuality.healthAdviceSensitive,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '主要污染物',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    airQuality.primaryPollutantName.isEmpty
                        ? '无'
                        : airQuality.primaryPollutantName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '污染物浓度',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
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
                      children: [
                        _buildPollutantRow(
                          'PM2.5',
                          airQuality.pollutants['pm2p5'] ?? 0,
                          'pm2p5',
                        ),
                        const Divider(),
                        _buildPollutantRow(
                          'PM10',
                          airQuality.pollutants['pm10'] ?? 0,
                          'pm10',
                        ),
                        const Divider(),
                        _buildPollutantRow(
                          'NO₂',
                          airQuality.pollutants['no2'] ?? 0,
                          'no2',
                        ),
                        const Divider(),
                        _buildPollutantRow(
                          'SO₂',
                          airQuality.pollutants['so2'] ?? 0,
                          'so2',
                        ),
                        const Divider(),
                        _buildPollutantRow(
                          'CO',
                          airQuality.pollutants['co'] ?? 0,
                          'co',
                        ),
                        const Divider(),
                        _buildPollutantRow(
                          'O₃',
                          airQuality.pollutants['o3'] ?? 0,
                          'o3',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantRow(String name, double value, String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 16)),
          Text(
            _formatValue(value, code),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
