import 'package:flutter/material.dart';

import '../models/precipitation_summary.dart';
import 'weather_metric_card.dart';

class PrecipitationSummaryCard extends StatelessWidget {
  final PrecipitationSummary summary;
  final VoidCallback? onTap;

  const PrecipitationSummaryCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final probability = summary.maximumProbability;
    final amount = summary.totalPrecipitation;
    final amountText =
        amount == null
            ? '累计量暂无完整数据'
            : '预计累计 ${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 1)} 毫米';
    return WeatherMetricCard(
      icon: Icons.water_drop_outlined,
      title: '降水',
      onTap: onTap,
      child: WeatherMetricValue(
        value: probability == null ? '暂无数据' : '${probability.round()}%',
        notes: [
          summary.completeProbability ? '24h内最高小时概率' : '已获取时段最高概率',
          summary.timingText,
          amountText,
        ],
      ),
    );
  }
}
