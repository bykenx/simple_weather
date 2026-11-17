import 'package:flutter/material.dart';

class WarningColorsUtils {
  static Color background(String severity, {Map<String, dynamic>? rgba}) {
    if (rgba != null) {
      final red = _channel(rgba['red']);
      final green = _channel(rgba['green']);
      final blue = _channel(rgba['blue']);
      final alpha = rgba['alpha'] ?? 1;
      if (red != null &&
          green != null &&
          blue != null &&
          alpha is num &&
          alpha.isFinite &&
          alpha >= 0 &&
          alpha <= 1) {
        return Color.fromRGBO(red, green, blue, alpha.toDouble());
      }
    }
    return switch (severity.trim().toLowerCase()) {
      'white' => Colors.white,
      'gray' => const Color(0xFF808080),
      'green' => const Color(0xFF2E7D32),
      'blue' => const Color(0xFF00A3FF),
      'yellow' => const Color(0xFFFFD700),
      'amber' => const Color(0xFFFFBF00),
      'orange' => const Color(0xFFFF9518),
      'red' => const Color(0xFFED2246),
      'purple' => const Color(0xFF7B1FA2),
      'black' => Colors.black,
      _ => const Color(0xFFD3D3D3),
    };
  }

  static Color foreground(
    String severity, {
    Map<String, dynamic>? rgba,
    Color surface = Colors.white,
  }) {
    final color = Color.alphaBlend(background(severity, rgba: rgba), surface);
    final luminance = color.computeLuminance();
    final blackContrast = (luminance + .05) / .05;
    final whiteContrast = 1.05 / (luminance + .05);
    return blackContrast >= whiteContrast ? Colors.black : Colors.white;
  }

  static int? _channel(dynamic value) =>
      value is num && value.isFinite && value >= 0 && value <= 255
          ? value.round()
          : null;
}
