import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Renders a textured moon for a continuous synodic phase.
/// [phase] is normalized to 0–1: new moon is 0, first quarter .25,
/// full moon .5, and last quarter .75.
class MoonPhaseSphere extends StatefulWidget {
  final double phase;
  final double librationLongitude;
  final double librationLatitude;
  final double orientation;
  const MoonPhaseSphere({
    super.key,
    required this.phase,
    this.librationLongitude = 0,
    this.librationLatitude = 0,
    this.orientation = 0,
  });

  @override
  State<MoonPhaseSphere> createState() => _MoonPhaseSphereState();
}

class _MoonResources {
  final ui.FragmentProgram program;
  final ui.Image texture;
  final ui.Image normalMap;
  const _MoonResources(this.program, this.texture, this.normalMap);
}

class _MoonPhaseSphereState extends State<MoonPhaseSphere> {
  static Future<_MoonResources>? _resources;
  ui.FragmentShader? _shader;
  _MoonResources? _loaded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resources = await (_resources ??= _loadResources());
      if (!mounted) return;
      setState(() {
        _loaded = resources;
        _shader = resources.program.fragmentShader();
      });
    } catch (error) {
      _resources = null;
      debugPrint('月相着色器不可用，使用简化月相：$error');
    }
  }

  static Future<_MoonResources> _loadResources() async {
    final values = await Future.wait([
      ui.FragmentProgram.fromAsset('shaders/moon_phase_sphere.frag'),
      _loadImage('assets/moon/Moon02.jpg'),
      _loadImage('assets/moon/Moon03Bump.jpg'),
    ]);
    return _MoonResources(
      values[0] as ui.FragmentProgram,
      values[1] as ui.Image,
      values[2] as ui.Image,
    );
  }

  static Future<ui.Image> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
    final bytes = Uint8List.sublistView(data);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
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
        painter: _MoonPainter(
          shader: _shader,
          resources: _loaded,
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
          phase: ((widget.phase % 1) + 1) % 1,
          librationLongitude: widget.librationLongitude,
          librationLatitude: widget.librationLatitude,
          orientation: widget.orientation,
        ),
      ),
    ),
  );
}

class _MoonPainter extends CustomPainter {
  final ui.FragmentShader? shader;
  final _MoonResources? resources;
  final double pixelRatio;
  final double phase;
  final double librationLongitude;
  final double librationLatitude;
  final double orientation;
  _MoonPainter({
    required this.shader,
    required this.resources,
    required this.pixelRatio,
    required this.phase,
    required this.librationLongitude,
    required this.librationLatitude,
    required this.orientation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final effect = shader;
    final images = resources;
    if (effect != null && images != null) {
      effect
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, pixelRatio)
        ..setFloat(3, phase)
        ..setFloat(4, librationLongitude)
        ..setFloat(5, librationLatitude)
        ..setFloat(6, orientation)
        ..setImageSampler(0, images.texture)
        ..setImageSampler(1, images.normalMap);
      canvas.drawRect(Offset.zero & size, Paint()..shader = effect);
      return;
    }
    _paintFallback(canvas, size);
  }

  void _paintFallback(Canvas canvas, Size size) {
    final radius = size.shortestSide * .46;
    final center = size.center(Offset.zero);
    final disk =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(disk);
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF111722));
    final litFromRight = phase <= .5;
    final illumination = (1 - math.cos(phase * 2 * math.pi)) / 2;
    final offset = radius * 2 * (1 - illumination);
    canvas.drawCircle(
      center + Offset(litFromRight ? offset : -offset, 0),
      radius,
      Paint()..color = const Color(0xFFD6E2F5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) =>
      old.shader != shader ||
      old.pixelRatio != pixelRatio ||
      old.phase != phase ||
      old.librationLongitude != librationLongitude ||
      old.librationLatitude != librationLatitude ||
      old.orientation != orientation;
}
