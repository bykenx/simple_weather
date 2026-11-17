import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'weather_card_surface.dart';

/// A common summary height keeps extra detail from stretching the paired card.
/// Larger system text gets more room and is shown in a single column upstream.
class WeatherMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onTap;

  const WeatherMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.onTap,
  });

  static double heightFor(BuildContext context) =>
      160 * math.max(1, MediaQuery.textScalerOf(context).scale(16) / 16);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: heightFor(context),
    width: double.infinity,
    child: WeatherCardSurface(
      child: InkWell(
        onTap: onTap,
        borderRadius: WeatherCardSurface.borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WeatherMetricHeading(icon: icon, title: title),
              const SizedBox(height: 8),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

class WeatherMetricHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const WeatherMetricHeading({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 13, height: 1.4, color: color),
          ),
        ),
      ],
    );
  }
}

class WeatherMetricValue extends StatelessWidget {
  final String value;
  final String? unit;
  final List<String> notes;

  const WeatherMetricValue({
    super.key,
    required this.value,
    this.unit,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: value,
            children: [
              if (unit != null)
                TextSpan(text: ' $unit', style: const TextStyle(fontSize: 15)),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: value == '暂无数据' ? 20 : 36,
            height: 1.15,
            fontWeight: FontWeight.w400,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(),
        for (final note in notes)
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
