import 'dart:math' as math;
import 'dart:ui';

import '../../core/time/day_minutes.dart';

/// Two rings of hour numerals around the dial's hub: hold the hub, slide to
/// an hour, release to jump there.
///
/// The inner ring is the 12 hours starting at [base]'s hour; the outer ring
/// the 12 after. Each numeral sits at its usual clock position, so at
/// 12:45 the inner "4" is 4 PM today and the outer "7" is 7 AM tomorrow.
class HourPickerController {
  HourPickerController({
    required this.center,
    required this.base,
    required this.innerRadius,
    required this.outerRadius,
    this.onChange,
  }) : assert(base % 60 == 0);

  /// The hub centre, in the same coordinate space as [pointer] positions.
  final Offset center;

  /// Absolute minute of the first hour on the inner ring.
  final int base;
  final double innerRadius;
  final double outerRadius;

  /// Called when the highlighted hour changes (for haptics).
  final void Function()? onChange;

  static const double deadZone = 28;

  int? _ring;
  int? _position;

  int? get ring => _ring;

  /// Clock position 0–11 (0 = 12 o'clock) of the highlighted numeral.
  int? get position => _position;

  /// Absolute start minute of the highlighted hour, or null.
  int? get picked =>
      _ring == null || _position == null ? null : startFor(_ring!, _position!);

  void pointer(Offset p) {
    final v = p - center;
    final d = v.distance;
    int? ring, pos;
    if (d >= deadZone) {
      var a = math.atan2(v.dx, -v.dy);
      if (a < 0) a += 2 * math.pi;
      pos = (a / (2 * math.pi) * 12).round() % 12;
      ring = d < (innerRadius + outerRadius) / 2 ? 0 : 1;
    }
    if (ring != _ring || pos != _position) {
      _ring = ring;
      _position = pos;
      if (pos != null) onChange?.call();
    }
  }

  /// Absolute start minute of the hour at clock [position] on [ring].
  int startFor(int ring, int position) {
    final baseHour12 = (minuteOfDay(base) ~/ 60) % 12;
    final offset = (position - baseHour12 + 12) % 12;
    return base + (ring * 12 + offset) * 60;
  }
}
