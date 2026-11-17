import 'dart:math' as math;

import 'package:flutter/material.dart';

class WindDirectionDial extends StatelessWidget {
  final double? degrees;
  final String grade;

  const WindDirectionDial({
    super.key,
    required this.degrees,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: grade.isEmpty ? '风力暂无数据' : '风力$grade级',
    excludeSemantics: true,
    child: FittedBox(
      child: SizedBox.square(
        dimension: 112,
        child: CustomPaint(
          painter: _WindDialPainter(
            Theme.of(context).colorScheme.onSurfaceVariant,
            Theme.of(context).colorScheme.onSurface,
            degrees,
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
          child: Stack(
            children: [
              _dialText(context, grade.isEmpty ? '—' : grade, 26, 48),
              _dialText(context, '级', 14, 73, secondary: true),
            ],
          ),
        ),
      ),
    ),
  );
}

class PressureDial extends StatelessWidget {
  final double pressure;

  const PressureDial({super.key, required this.pressure});

  @override
  Widget build(BuildContext context) {
    final value = pressure.isFinite ? pressure.round().toString() : '—';
    return Semantics(
      label: pressure.isFinite ? '气压$value百帕' : '气压暂无数据',
      excludeSemantics: true,
      child: FittedBox(
        child: SizedBox.square(
          dimension: 120,
          child: CustomPaint(
            painter: _PressureDialPainter(
              Theme.of(context).colorScheme.onSurfaceVariant,
              Theme.of(context).colorScheme.onSurface,
              pressure,
            ),
            child: Stack(
              children: [
                _dialText(context, value, 24, 53),
                _dialText(context, '百帕', 14, 75, secondary: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _dialText(
  BuildContext context,
  String text,
  double fontSize,
  double centerY, {
  bool secondary = false,
}) => Positioned(
  left: 0,
  right: 0,
  top: centerY - fontSize * 1.2 / 2,
  child: Text(
    text,
    textAlign: TextAlign.center,
    // Scale the whole diagram together to preserve its text/arrow geometry.
    textScaler: TextScaler.noScaling,
    style: TextStyle(
      fontSize: fontSize,
      height: 1.2,
      fontWeight: FontWeight.w400,
      color:
          secondary
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  ),
);

Offset _polar(Offset center, double angle, double radius) =>
    center + Offset(math.cos(angle), math.sin(angle)) * radius;

class _WindDialPainter extends CustomPainter {
  final Color color;
  final Color foreground;
  final double? degrees;
  final TextStyle labelStyle;

  _WindDialPainter(this.color, this.foreground, this.degrees, this.labelStyle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final labels = [
      center + const Offset(0, -45.5),
      center + const Offset(45.5, 0),
      center + const Offset(0, 45.5),
      center + const Offset(-45.5, 0),
    ];
    final gaps = Path();
    for (final point in labels) {
      gaps.addOval(Rect.fromCircle(center: point, radius: 10));
    }
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        gaps,
      ),
    );
    final tick =
        Paint()
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 72; index++) {
      final angle = -math.pi / 2 + index * math.pi / 36;
      tick.color = color.withValues(alpha: index % 6 == 0 ? .82 : .28);
      canvas.drawLine(
        _polar(center, angle, 41),
        _polar(center, angle, 49),
        tick,
      );
    }
    canvas.restore();

    if (degrees?.isFinite == true) {
      canvas.save();
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          Path()
            ..addOval(Rect.fromCenter(center: center, width: 44, height: 52)),
        ),
      );
      canvas.translate(center.dx, center.dy);
      canvas.rotate((degrees! - 90) * math.pi / 180);
      final arrow =
          Paint()
            ..color = foreground
            ..strokeWidth = 2.8
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(-47, 0), const Offset(47, 0), arrow);
      canvas.drawPath(
        Path()
          ..moveTo(39, -7)
          ..lineTo(47, 0)
          ..lineTo(39, 7),
        arrow,
      );
      canvas.restore();
    }
    for (var index = 0; index < labels.length; index++) {
      final text = TextPainter(
        text: TextSpan(
          text: ['北', '东', '南', '西'][index],
          style: labelStyle.copyWith(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        labels[index] - Offset(text.width / 2, text.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WindDialPainter oldDelegate) =>
      color != oldDelegate.color ||
      foreground != oldDelegate.foreground ||
      degrees != oldDelegate.degrees ||
      labelStyle != oldDelegate.labelStyle;
}

class _PressureDialPainter extends CustomPainter {
  final Color color;
  final Color foreground;
  final double pressure;

  _PressureDialPainter(this.color, this.foreground, this.pressure);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final tick =
        Paint()
          ..color = color.withValues(alpha: .35)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
    for (var index = 0; index <= 54; index++) {
      final angle = (135 + index * 5) * math.pi / 180;
      canvas.drawLine(
        _polar(center, angle, 44),
        _polar(center, angle, 49),
        tick,
      );
    }
    if (!pressure.isFinite) return;

    final fraction = ((pressure - 950) / 100).clamp(0.0, 1.0);
    final angle = (135 + fraction * 270) * math.pi / 180;
    const midpoint = math.pi * 1.5;
    const radius = 46.5;
    final sweep = angle - midpoint;
    if (sweep.abs() > .00001) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final transparent = foreground.withValues(alpha: 0);
      final white = foreground.withValues(alpha: .5);
      canvas.drawArc(
        rect,
        midpoint,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          // Original ticks span 6.8 including caps; this band covers them.
          ..strokeWidth = 7.2
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            // Keep the wrap-around side transparent too, including the
            // rounded starting cap just before the gradient's zero angle.
            colors:
                sweep > 0
                    ? [transparent, white, white, transparent, transparent]
                    : [white, transparent, transparent, white, white],
            stops: [0, sweep.abs() / (math.pi * 2), .5, .5, 1],
            transform: GradientRotation(sweep > 0 ? midpoint : angle),
          ).createShader(rect),
      );
    }
    canvas.drawLine(
      _polar(center, angle, 43),
      _polar(center, angle, 50),
      Paint()
        ..color = foreground
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PressureDialPainter oldDelegate) =>
      color != oldDelegate.color ||
      foreground != oldDelegate.foreground ||
      pressure != oldDelegate.pressure;
}
