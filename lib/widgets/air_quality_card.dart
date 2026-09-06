import 'package:flutter/material.dart';
import '../models/air_quality_model.dart';
import 'air_quality_sheet.dart';
import 'weather_detail_sheet.dart';
import '../utils/air_quality_utils.dart';
import 'weather_card_surface.dart';

class AirQualityCard extends StatelessWidget {
  final AirQualityModel airQuality;
  const AirQualityCard({super.key, required this.airQuality});

  @override
  Widget build(BuildContext context) {
    final value = AirQualityUtils.getAqiDisplayValue(airQuality.aqi);
    return WeatherCardSurface(
      child: InkWell(
        borderRadius: WeatherCardSurface.borderRadius,
        onTap:
            () => showWeatherDetailSheet(
              context,
              title: '空气质量',
              icon: Icons.blur_on,
              child: AirQualitySheet(data: airQuality),
            ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value · ${airQuality.category}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final position =
                      airQuality.aqi.isFinite
                          ? (airQuality.aqi / 500).clamp(0.0, 1.0)
                          : 0.0;
                  return SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF15CC83),
                                Color(0xFFF4DA36),
                                Color(0xFFFF8D28),
                                Color(0xFFE83E64),
                                Color(0xFFAB38C2),
                                Color(0xFF7D1833),
                              ],
                              stops: [0, 0.1, 0.2, 0.3, 0.4, 1],
                            ),
                          ),
                        ),
                        if (airQuality.aqi.isFinite)
                          Positioned(
                            left: (constraints.maxWidth - 8) * position,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black26),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                '当前 AQI (CN) 为 $value。',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
