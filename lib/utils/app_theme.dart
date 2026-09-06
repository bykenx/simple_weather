import 'package:flutter/material.dart';

class AppTheme {
  static const cardRadius = BorderRadius.all(Radius.circular(20));

  static ThemeData build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      cardColor: colors.surfaceContainerLow,
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  static BoxDecoration cardDecoration(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: cardRadius,
      border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
    );
  }
}
