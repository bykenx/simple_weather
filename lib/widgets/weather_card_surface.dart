import 'dart:ui';

import '../utils/app_theme.dart';

import 'package:flutter/material.dart';

/// Shared glass surface. The filter is clipped before painting sharp content.
class WeatherCardSurface extends StatelessWidget {
  static const borderRadius = AppTheme.cardRadius;

  final Widget child;

  const WeatherCardSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF13283F) : const Color(0xFF376C83);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.025),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          blendMode: BlendMode.src,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  base.withValues(alpha: isDark ? 0.84 : 0.66),
                  base.withValues(alpha: isDark ? 0.78 : 0.58),
                ],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.10),
              ),
            ),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}
