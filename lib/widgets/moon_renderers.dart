import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The original decorative crescent used beside the current conditions.
class WeatherCrescent extends StatefulWidget {
  const WeatherCrescent({super.key});

  @override
  State<WeatherCrescent> createState() => _WeatherCrescentState();
}

class _WeatherCrescentState extends State<WeatherCrescent> {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program =
          await (_program ??= ui.FragmentProgram.fromAsset(
            'shaders/weather_crescent.frag',
          ));
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (error) {
      _program = null;
      debugPrint('弯月着色器不可用，使用弯月轮廓：$error');
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _CrescentPainter(
          _shader,
          MediaQuery.devicePixelRatioOf(context),
        ),
      ),
    ),
  );
}

class _CrescentPainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final double pixelRatio;
  const _CrescentPainter(this.shader, this.pixelRatio);

  @override
  void paint(Canvas canvas, Size size) {
    final effect = shader;
    if (effect != null) {
      effect
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, pixelRatio);
      canvas.drawRect(Offset.zero & size, Paint()..shader = effect);
      return;
    }
    final radius = size.shortestSide * .30;
    final center = size.center(Offset.zero);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      Path()..addOval(
        Rect.fromCircle(
          center: center + Offset(radius * .43, -radius * .22),
          radius: radius * .96,
        ),
      ),
    );
    canvas.drawPath(crescent, Paint()..color = const Color(0xFFE2EAF4));
  }

  @override
  bool shouldRepaint(covariant _CrescentPainter old) =>
      old.shader != shader || old.pixelRatio != pixelRatio;
}
