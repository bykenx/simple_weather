import 'package:flutter/material.dart';
import '../models/air_quality_model.dart';
import '../utils/air_quality_utils.dart';
import 'weather_detail_sheet.dart';

class AirQualitySheet extends StatelessWidget {
  final AirQualityModel data;
  const AirQualitySheet({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const pollutants = [
      ('co', 'CO', '一氧化碳'),
      ('no2', 'NO₂', '二氧化氮'),
      ('so2', 'SO₂', '二氧化硫'),
      ('pm10', 'PM₁₀', '小于 10 μm 颗粒物'),
      ('pm2p5', 'PM₂.₅', '小于 2.5 μm 颗粒物'),
      ('o3', 'O₃', '臭氧'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detailText(data.category),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text('标准：中国 (AQI)', style: TextStyle(color: colors.onSurfaceVariant)),
        const SizedBox(height: 16),
        DetailPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前 AQI (CN)：${detailNumber(data.aqi, '')}'),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder:
                    (context, constraints) => SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF15CC83),
                                  Color(0xFFF4DA36),
                                  Color(0xFFFF8D28),
                                  Color(0xFFE83E64),
                                  Color(0xFFAB38C2),
                                  Color(0xFF7D1833),
                                ],
                                stops: [0, .1, .2, .3, .4, 1],
                              ),
                            ),
                          ),
                          if (data.aqi.isFinite)
                            Positioned(
                              left:
                                  (constraints.maxWidth - 10) *
                                  (data.aqi / 500).clamp(0, 1),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black54),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ),
        DetailSection(
          title: '健康信息',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('一般人群：${detailText(data.healthAdviceGeneral)}'),
              const SizedBox(height: 12),
              Text('敏感人群：${detailText(data.healthAdviceSensitive)}'),
              if (data.healthEffect.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(data.healthEffect),
              ],
            ],
          ),
        ),
        DetailSection(
          title: '污染物详细信息',
          child: Column(
            children: [
              for (var i = 0; i < pollutants.length; i++) ...[
                if (i > 0) const Divider(height: 28),
                Builder(
                  builder: (context) {
                    final item = pollutants[i];
                    final value = data.pollutants[item.$1];
                    final formatted =
                        value != null && value.isFinite
                            ? AirQualityUtils.formatPollutantValue(
                              value,
                              item.$1,
                            )
                            : '暂无数据';
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final caption = Text('${item.$2}  ${item.$3}');
                        final reading = Text(
                          formatted,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        );
                        if (constraints.maxWidth >= 300 &&
                            MediaQuery.textScalerOf(context).scale(16) <= 20) {
                          return Row(
                            children: [
                              Expanded(child: caption),
                              const SizedBox(width: 16),
                              reading,
                            ],
                          );
                        }
                        return SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              caption,
                              const SizedBox(height: 4),
                              reading,
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('空气质量数据来源：和风天气', style: TextStyle(color: colors.onSurfaceVariant)),
      ],
    );
  }
}
