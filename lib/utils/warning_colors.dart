import 'package:flutter/material.dart';

class WarningColors {
  static Color background(String severity) => switch (severity.toLowerCase()) {
    'red' => const Color(0xFFED2246),
    'yellow' => const Color(0xFFFFD700),
    'orange' => const Color(0xFFFF9518),
    'blue' => const Color(0xFF00A3FF),
    _ => const Color(0xFFD3D3D3),
  };

  static Color foreground(String severity) =>
      severity.toLowerCase() == 'red' ? Colors.white : const Color(0xFF142334);
}
