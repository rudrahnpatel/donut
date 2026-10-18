import 'dart:math' as math;
import 'dart:ui';

import 'spiral_math.dart';

/// Radii and hit-testing for a dial laid out in a square of [size].
///
/// Proportions are relative to the dial radius `R`: after-lane
/// `[0.95R, R]`, outer ring `[0.72R, 0.91R]`, inner ring `[0.49R, 0.68R]`,
/// before-lane `[0.43R, 0.47R]`, numerals at `0.34R`.
class ClockGeometry {
  ClockGeometry(Size size, this.spec)
    : center = Offset(size.width / 2, size.height / 2),
      radius = math.min(size.width, size.height) / 2;

  final Offset center;
  final double radius;
  final DialSpec spec;

  double get beforeR0 => radius * 0.43;
  double get beforeR1 => radius * 0.47;
  double get innerR0 => radius * 0.49;
  double get innerR1 => radius * 0.68;
  double get outerR0 => radius * 0.72;
  double get outerR1 => radius * 0.91;
  double get afterR0 => radius * 0.95;
  double get afterR1 => radius;
  double get numeralR => radius * 0.34;

  (double, double) laneBounds(Lane lane) => switch (lane) {
    Lane.inner => (innerR0, innerR1),
    Lane.outer => (outerR0, outerR1),
    Lane.before => (beforeR0, beforeR1),
    Lane.after => (afterR0, afterR1),
  };

  double laneMid(Lane lane) {
    final (a, b) = laneBounds(lane);
    return (a + b) / 2;
  }

  double laneWidth(Lane lane) {
    final (a, b) = laneBounds(lane);
    return b - a;
  }

  /// Point at [angle] (clockwise from 12) and distance [r] from the centre.
  Offset pointAt(double angle, double r) =>
      center + Offset(math.sin(angle) * r, -math.cos(angle) * r);

  /// Point for day-relative minute [u], on the middle of its lane.
  Offset pointForMinute(double u) {
    final p = spec.place(u);
    return pointAt(p.angle, laneMid(p.lane));
  }

  /// Point for an interval's exclusive end: a block ending exactly on a
  /// lap boundary ends on the ring it came from, not at the next one's
  /// start.
  Offset pointForEnd(double u) => pointForMinute(u - 0.01);

  double distanceFromCenter(Offset p) => (p - center).distance;

  double angleOf(Offset p) => clockAngle(p, center);

  /// Too close to the centre for the angle to mean anything.
  bool isNearCenter(Offset p) => distanceFromCenter(p) < innerR0 * 0.4;

  /// Inside the inner ring: the hub, used for hour navigation.
  bool isInHub(Offset p) => distanceFromCenter(p) < beforeR0 - 4;

  /// The ring a press at [p] starts on, or null if [p] is off the rings.
  /// The thin overflow bands are display-only and count as the ring next to
  /// them.
  Lane? ringAt(Offset p) {
    final r = distanceFromCenter(p);
    final split = (innerR1 + outerR0) / 2;
    if (r >= beforeR0 - 4 && r < split) return Lane.inner;
    if (r >= split && r <= afterR1 + 8) return Lane.outer;
    return null;
  }

  /// Day-relative minute under [p] on [ring].
  double minuteAt(Offset p, Lane ring) =>
      spec.minuteAt(angleOf(p), ring == Lane.outer ? 1 : 0);
}
