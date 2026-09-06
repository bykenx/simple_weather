import 'dart:math' as math;

class MoonOrientation {
  final double longitude;
  final double latitude;
  final double rotation;

  const MoonOrientation({
    required this.longitude,
    required this.latitude,
    required this.rotation,
  });
}

/// Low-cost lunar orientation suitable for the textured moon preview.
///
/// It models the dominant optical libration terms and the observer's
/// parallactic angle. This is intentionally visual rather than an ephemeris.
MoonOrientation approximateMoonOrientation({
  required DateTime time,
  required double latitude,
  required double longitude,
}) {
  final utc = time.toUtc();
  final days =
      utc.difference(DateTime.utc(2000, 1, 1, 12)).inMilliseconds /
      Duration.millisecondsPerDay;
  final meanAnomaly = _radians(_normalizeDegrees(134.963 + 13.064993 * days));
  final argumentLatitude = _radians(
    _normalizeDegrees(93.272 + 13.229350 * days),
  );
  final ascendingNode = _radians(_normalizeDegrees(125.045 - 0.0529538 * days));

  final eclipticLongitude = _radians(
    _normalizeDegrees(
      218.316 + 13.176396 * days + 6.289 * math.sin(meanAnomaly),
    ),
  );
  final eclipticLatitude = _radians(5.128 * math.sin(argumentLatitude));
  final obliquity = _radians(23.4393 - 0.0000004 * days);
  final rightAscension = math.atan2(
    math.sin(eclipticLongitude) * math.cos(obliquity) -
        math.tan(eclipticLatitude) * math.sin(obliquity),
    math.cos(eclipticLongitude),
  );
  final declination = math.asin(
    math.sin(eclipticLatitude) * math.cos(obliquity) +
        math.cos(eclipticLatitude) *
            math.sin(obliquity) *
            math.sin(eclipticLongitude),
  );
  final sidereal = _radians(
    _normalizeDegrees(280.46061837 + 360.98564736629 * days + longitude),
  );
  final hourAngle = sidereal - rightAscension;
  final observerLatitude = _radians(latitude.clamp(-89.9, 89.9));
  final parallacticAngle = math.atan2(
    math.sin(hourAngle),
    math.tan(observerLatitude) * math.cos(declination) -
        math.sin(declination) * math.cos(hourAngle),
  );

  // Dominant physical/optical libration terms. Values stay inside the Moon's
  // observed ±8° longitude and ±7° latitude range.
  final librationLongitude = _radians(
    6.29 * math.sin(meanAnomaly) -
        1.27 * math.sin(2 * argumentLatitude - meanAnomaly),
  );
  final librationLatitude = _radians(
    5.13 * math.sin(argumentLatitude) +
        0.28 * math.sin(meanAnomaly + argumentLatitude),
  );
  final poleTilt = _radians(6.68) * math.sin(argumentLatitude - ascendingNode);

  return MoonOrientation(
    longitude: librationLongitude,
    latitude: librationLatitude,
    rotation: parallacticAngle + poleTilt,
  );
}

double _normalizeDegrees(double value) => ((value % 360) + 360) % 360;
double _radians(double degrees) => degrees * math.pi / 180;
