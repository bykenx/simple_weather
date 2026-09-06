import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import 'moon_renderers.dart';

enum SkyKind {
  clear,
  clouds,
  overcast,
  rain,
  snow,
  sleet,
  thunder,
  fog,
  dust,
  wind,
  unknown,
}

@immutable
class WeatherScene {
  final SkyKind kind;
  final bool night;
  const WeatherScene(this.kind, this.night);
  factory WeatherScene.fromWeather(LiveWeatherModel? weather, {DateTime? now}) {
    final code = int.tryParse(weather?.icon ?? '') ?? 999;
    // Night-specific provider icons take priority; other codes use the city's
    // observation offset, rather than the phone's local timezone.
    final match = RegExp(
      r'([+-])(\d{2}):(\d{2})$',
    ).firstMatch(weather?.obsTime ?? '');
    var local = (now ?? DateTime.now()).toUtc();
    if (match != null) {
      final offset = int.parse(match[2]!) * 60 + int.parse(match[3]!);
      local = local.add(Duration(minutes: match[1] == '-' ? -offset : offset));
    } else {
      local = (now ?? DateTime.now()).toLocal();
    }
    final night =
        {150, 151, 152, 153, 350, 351, 456, 457}.contains(code) ||
        local.hour < 6 ||
        local.hour >= 18;
    final kind = switch (code) {
      100 || 150 || 900 => SkyKind.clear,
      101 || 102 || 103 || 151 || 152 || 153 => SkyKind.clouds,
      104 => SkyKind.overcast,
      >= 200 && <= 213 => SkyKind.wind,
      302 || 303 || 304 => SkyKind.thunder,
      >= 300 && < 400 => SkyKind.rain,
      404 || 405 || 406 || 456 => SkyKind.sleet,
      >= 400 && < 500 || 901 => SkyKind.snow,
      503 || 504 || 507 || 508 => SkyKind.dust,
      >= 500 && < 600 => SkyKind.fog,
      _ => SkyKind.unknown,
    };
    return WeatherScene(kind, night);
  }
  List<Color> get colors {
    if (night) {
      return switch (kind) {
        SkyKind.thunder => const [Color(0xFF101323), Color(0xFF293048)],
        SkyKind.fog ||
        SkyKind.dust => const [Color(0xFF252D3C), Color(0xFF525465)],
        _ => const [Color(0xFF07152F), Color(0xFF244C72)],
      };
    }
    return switch (kind) {
      SkyKind.clear ||
      SkyKind.clouds => const [Color(0xFF1763A5), Color(0xFF75B6DD)],
      SkyKind.rain ||
      SkyKind.sleet => const [Color(0xFF293F59), Color(0xFF718EAA)],
      SkyKind.thunder => const [Color(0xFF202B44), Color(0xFF52667D)],
      SkyKind.snow => const [Color(0xFF536E91), Color(0xFFA5BDCD)],
      SkyKind.fog => const [Color(0xFF596D7B), Color(0xFF9AAEB7)],
      SkyKind.dust => const [Color(0xFF79634F), Color(0xFFB29B7B)],
      _ => const [Color(0xFF456480), Color(0xFF91ABBD)],
    };
  }

  @override
  bool operator ==(Object other) =>
      other is WeatherScene && kind == other.kind && night == other.night;
  @override
  int get hashCode => Object.hash(kind, night);
}

/// A canvas-only atmosphere: no network assets, hit targets, or per-frame builds.
class WeatherSceneBackground extends StatefulWidget {
  final WeatherScene scene;
  final bool paused;
  final bool showDecorativeMoon;

  const WeatherSceneBackground({
    super.key,
    required this.scene,
    this.paused = false,
    this.showDecorativeMoon = true,
  });
  @override
  State<WeatherSceneBackground> createState() => _WeatherSceneBackgroundState();
}

class _WeatherSceneBackgroundState extends State<WeatherSceneBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant WeatherSceneBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused) _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (_active &&
        !widget.paused &&
        TickerMode.of(context) &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedSwitcher(
          duration:
              MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 900),
          child: _SkyCanvas(
            key: ValueKey((widget.scene, widget.showDecorativeMoon)),
            scene: widget.scene,
            clock: _clock,
            animate: !MediaQuery.disableAnimationsOf(context),
            showDecorativeMoon: widget.showDecorativeMoon,
          ),
        ),
      ),
    ),
  );
}

class _SkyCanvas extends StatefulWidget {
  final WeatherScene scene;
  final Animation<double> clock;
  final bool animate;
  final bool showDecorativeMoon;
  const _SkyCanvas({
    super.key,
    required this.scene,
    required this.clock,
    required this.animate,
    required this.showDecorativeMoon,
  });

  @override
  State<_SkyCanvas> createState() => _SkyCanvasState();
}

class _SkyCanvasState extends State<_SkyCanvas> {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await (_program ??= ui.FragmentProgram.fromAsset(
            'shaders/weather_atmosphere.frag',
          ));
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (error) {
      _program = null;
      debugPrint('天气背景着色器加载失败，使用纯色背景：$error');
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      // Celestial placement belongs to the background and follows its bounds.
      // Derive it on layout so resizing never leaves stale pixel coordinates.
      final safeTop = MediaQuery.paddingOf(context).top.clamp(0.0, size.height);
      final skyHeight = size.height - safeTop;
      final sunCenter = Offset(size.width * .18, safeTop + skyHeight * .16);
      final moonCenter = Offset(size.width * .18, safeTop + skyHeight * .28);
      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _SkyPainter(
              widget.scene,
              widget.clock,
              widget.animate,
              _shader,
              MediaQuery.devicePixelRatioOf(context),
              sunCenter,
            ),
          ),
          if (widget.showDecorativeMoon &&
              widget.scene.night &&
              (widget.scene.kind == SkyKind.clear ||
                  widget.scene.kind == SkyKind.clouds))
            Positioned(
              left: moonCenter.dx - 40,
              top: moonCenter.dy - 40,
              width: 80,
              height: 80,
              child: Opacity(
                opacity: widget.scene.kind == SkyKind.clouds ? .65 : 1,
                child: const WeatherCrescent(),
              ),
            ),
        ],
      );
    },
  );
}

class _SkyGlow {
  final Offset center;
  final Size radius;
  final Color color;
  const _SkyGlow(this.center, this.radius, this.color);
}

class _SkyPainter extends CustomPainter {
  final WeatherScene scene;
  final Animation<double> clock;
  final bool animate;
  final ui.FragmentShader? shader;
  final double pixelRatio;
  final Offset sunCenter;
  _SkyPainter(
    this.scene,
    this.clock,
    this.animate,
    this.shader,
    this.pixelRatio,
    this.sunCenter,
  ) : super(repaint: clock);
  double seed(int i, int salt) =>
      ((math.sin(i * 127.1 + salt * 311.7) * 43758.5453) % 1);
  void _atmosphere(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final glows = <_SkyGlow>[];
    final clear = scene.kind == SkyKind.clear || scene.kind == SkyKind.clouds;
    if (clear && !scene.night) {
      final sun = sunCenter;
      glows.add(
        _SkyGlow(
          sun,
          Size.square(w * (.6 + .02 * math.sin(t * math.pi / 15))),
          const Color(0x18FFF7EA),
        ),
      );
      glows.add(_SkyGlow(sun, Size.square(w * .20), const Color(0x18F7FAFF)));
    }
    if (scene.kind != SkyKind.clear && scene.kind != SkyKind.unknown) {
      final thick = scene.kind != SkyKind.clouds;
      for (var i = 0; i < (thick ? 11 : 5); i++) {
        final drift = math.sin(t * math.pi / 30 + i * 1.7) * w * .15;
        final center = Offset(
          seed(i, 4) * w * 1.4 - w * .2 + drift,
          h * (.05 + seed(i, 5) * (thick ? .5 : .24)),
        );
        final radius = w * (.25 + seed(i, 6) * .35);
        glows.add(
          _SkyGlow(
            center,
            Size(radius * 1.7, radius * .48),
            (scene.night ? const Color(0xFF8798B7) : Colors.white).withValues(
              alpha: thick ? .19 : .25,
            ),
          ),
        );
      }
    }
    if ({SkyKind.fog, SkyKind.dust, SkyKind.wind}.contains(scene.kind)) {
      for (var i = 0; i < 7; i++) {
        glows.add(
          _SkyGlow(
            Offset(
              w * (.5 + .2 * math.sin(t * math.pi / 15 + i)),
              h * (.15 + i * .12),
            ),
            Size(w * .6 * 2.5, w * .6 * .16),
            Colors.white.withValues(alpha: .1),
          ),
        );
      }
    }
    if (scene.kind == SkyKind.thunder && animate && t % 12 < 1.2) {
      glows.add(
        _SkyGlow(
          Offset(w * .7, h * .08),
          Size.square(w * 1.1),
          Colors.white.withValues(
            alpha: math.sin((t % 12) / 1.2 * math.pi) * .13,
          ),
        ),
      );
    }
    final effect = shader;
    if (effect == null) {
      canvas.drawColor(scene.colors.first, BlendMode.src);
      return;
    }
    final colors = scene.colors;
    final header = [
      w,
      h,
      pixelRatio,
      colors.first.r,
      colors.first.g,
      colors.first.b,
      colors.last.r,
      colors.last.g,
      colors.last.b,
      glows.length.toDouble(),
    ];
    for (var i = 0; i < header.length; i++) {
      effect.setFloat(i, header[i]);
    }
    // uSun follows the two fixed arrays of 24 vec4s in the shader.
    final sun = sunCenter;
    effect.setFloat(202, sun.dx);
    effect.setFloat(203, sun.dy);
    effect.setFloat(204, (w * .055).clamp(18.0, 28.0));
    effect.setFloat(205, clear && !scene.night ? 1 : 0);
    // A 60-second round trip, smoothly reversing at +/-22.5 degrees.
    effect.setFloat(206, math.sin(t * math.pi / 30) * math.pi / 8);
    assert(glows.length <= 24);
    for (var i = 0; i < glows.length; i++) {
      final glow = glows[i];
      final bounds = [
        glow.center.dx,
        glow.center.dy,
        glow.radius.width,
        glow.radius.height,
      ];
      final rgba = [glow.color.r, glow.color.g, glow.color.b, glow.color.a];
      for (var j = 0; j < 4; j++) {
        effect.setFloat(10 + i * 4 + j, bounds[j]);
        effect.setFloat(106 + i * 4 + j, rgba[j]);
      }
    }
    canvas.drawRect(Offset.zero & size, Paint()..shader = effect);
  }

  void _stars(Canvas canvas, Size size, double t) {
    final cloudVisibility = scene.kind == SkyKind.clouds ? .55 : 1.0;
    for (var i = 0; i < 85; i++) {
      final point = Offset(
        seed(i, 1) * size.width,
        seed(i, 2) * size.height * .65,
      );
      // Different phases and integer cycle counts keep the 60s loop seamless.
      final phase = t / 60 * (4 + (seed(i, 21) * 6).floor()) + seed(i, 22);
      final pulse =
          math.pow(math.max(0.0, math.sin(phase * math.pi * 2)), 8).toDouble();
      final sparkle = animate ? pulse : .12;
      final opacity =
          (.16 + seed(i, 23) * .25 + sparkle * .55) * cloudVisibility;
      final radius = .4 + seed(i, 3) * .85;
      final tint =
          Color.lerp(
            const Color(0xFFBBD8FF),
            const Color(0xFFFFF7E8),
            seed(i, 24),
          )!;
      if (sparkle > .15 && i % 4 == 0) {
        final haloRadius = radius * 5;
        canvas.drawCircle(
          point,
          haloRadius,
          Paint()
            ..shader = ui.Gradient.radial(point, haloRadius, [
              tint.withValues(alpha: sparkle * .22 * cloudVisibility),
              tint.withValues(alpha: 0),
            ]),
        );
      }
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = tint.withValues(alpha: opacity),
      );
    }
  }

  void _meteors(Canvas canvas, Size size, double t) {
    if (!animate) return;
    const starts = [6.0, 23.0, 43.0];
    for (var i = 0; i < starts.length; i++) {
      final progress = (t - starts[i]) / (1.5 + i * .15);
      if (progress <= 0 || progress >= 1) continue;
      final start = Offset(size.width * 1.12, size.height * (.08 + i * .045));
      final end = Offset(-size.width * .18, start.dy + size.height * .16);
      final head = Offset.lerp(start, end, progress)!;
      final direction = (end - start) / (end - start).distance;
      final tail = head - direction * (size.width * .23).clamp(55.0, 115.0);
      final fade =
          math.min(1.0, progress / .12) *
          math.min(1.0, (1 - progress) / .22) *
          (scene.kind == SkyKind.clouds ? .45 : .85);
      const tint = Color(0xFFDCEEFF);
      // The faint tail points back to the right; the bright head travels left.
      final trail = ui.Gradient.linear(
        tail,
        head,
        [
          tint.withValues(alpha: 0),
          tint.withValues(alpha: fade * .2),
          Colors.white.withValues(alpha: fade),
        ],
        [0, .65, 1],
      );
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..shader = trail
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        head,
        5,
        Paint()
          ..shader = ui.Gradient.radial(head, 5, [
            tint.withValues(alpha: fade * .4),
            tint.withValues(alpha: 0),
          ]),
      );
      canvas.drawCircle(
        head,
        1.1,
        Paint()..color = Colors.white.withValues(alpha: fade),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final t = animate ? clock.value * 60 : 0.0;
    final w = size.width, h = size.height;
    canvas.save();
    canvas.clipRect(rect);
    _atmosphere(canvas, size, t);
    final clear = scene.kind == SkyKind.clear || scene.kind == SkyKind.clouds;
    if (scene.night && clear) {
      _stars(canvas, size, t);
      _meteors(canvas, size, t);
    }
    final rain = {
      SkyKind.rain,
      SkyKind.thunder,
      SkyKind.sleet,
    }.contains(scene.kind);
    final snow = scene.kind == SkyKind.snow || scene.kind == SkyKind.sleet;
    if (rain) {
      for (var i = 0; i < 95; i++) {
        final depth = .4 + seed(i, 7) * .6;
        final progress =
            (seed(i, 8) + clock.value * (30 + (seed(i, 9) * 25).floor())) % 1;
        final x = seed(i, 10) * (w + 120) - 60 - progress * 45;
        final y = progress * (h + 50) - 25;
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 4 * depth, y + 22 * depth),
          Paint()
            ..color = const Color(
              0xFFD9EDFF,
            ).withValues(alpha: .13 + depth * .25)
            ..strokeWidth = depth
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (snow) {
      for (var i = 0; i < 65; i++) {
        final depth = .3 + seed(i, 11) * .7;
        final y =
            ((seed(i, 12) + clock.value * (3 + (depth * 5).floor())) % 1) *
                (h + 20) -
            10;
        final x =
            seed(i, 13) * w + math.sin(t * math.pi / 6 + i) * (10 + depth * 20);
        canvas.drawCircle(
          Offset(x, y),
          1 + depth * 2.5,
          Paint()..color = Colors.white.withValues(alpha: .35 + depth * .5),
        );
      }
    }
    if (scene.kind == SkyKind.wind) {
      for (var i = 0; i < 12; i++) {
        final x = ((seed(i, 15) + clock.value * 6) % 1) * (w + 180) - 90;
        final y = h * (.12 + seed(i, 16) * .7);
        final path =
            Path()
              ..moveTo(x, y)
              ..quadraticBezierTo(x + 35, y - 10, x + 90, y - 4);
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: .16)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
    if (scene.kind == SkyKind.dust) {
      for (var i = 0; i < 50; i++) {
        final x = ((seed(i, 17) + clock.value * 3) % 1) * w;
        final y = seed(i, 18) * h + math.sin(t * math.pi / 6 + i) * 8;
        canvas.drawCircle(
          Offset(x, y),
          .6 + seed(i, 19),
          Paint()..color = const Color(0xFFE6D1A9).withValues(alpha: .2),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.scene != scene ||
      oldDelegate.animate != animate ||
      oldDelegate.shader != shader ||
      oldDelegate.sunCenter != sunCenter ||
      oldDelegate.pixelRatio != pixelRatio;
}
