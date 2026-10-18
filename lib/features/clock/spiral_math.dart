/// Pure math behind the two-ring "spiral" dial.
///
/// A dial shows two laps of [DialSpec.turn] minutes each: the inner ring is
/// the first lap, the outer ring the second. The day dial has 720-minute
/// laps starting at midnight (inner = AM, outer = PM); the hour dial has
/// 60-minute laps starting at an hour, or at "now" for the live hour. A
/// position on the dial always means the same clock reading (on the hour
/// dial the "2" is always :10); the lap decides which ring it is on. Time
/// outside the two laps is drawn on a thin overflow lane outside the outer
/// ring. Everything here works in *day-relative minutes* `u`, where 0 is
/// the page's midnight; `u` may be negative or ≥ 1440.
library;

import 'dart:math' as math;
import 'dart:ui';

const double twoPi = 2 * math.pi;

/// Where a minute is drawn. Time before the inner ring's lap spills onto a
/// thin band *inside* it, time after the outer ring's lap onto a thin band
/// *outside* it, like a spiral: earlier is further in, later further out.
enum Lane {
  before,
  inner,
  outer,
  after;

  bool get isOverflow => this == before || this == after;
}

/// One drawable piece of an interval, confined to a single lane.
typedef ArcPiece = ({
  Lane lane,
  double startAngle,
  double sweep,
  double startMin,
  double endMin,
});

/// How minutes map onto the dial.
class DialSpec {
  const DialSpec({
    required this.turn,
    required this.origin,
    this.slides = false,
  });

  /// The day dial: inner ring AM, outer ring PM.
  const DialSpec.day() : turn = 720, origin = 0, slides = false;

  /// An hour dial whose inner ring starts at [origin] (an hour boundary, or
  /// the current minute for the live hour). It slides an hour at a time
  /// when a drag runs off either end.
  const DialSpec.hour(this.origin) : turn = 60, slides = true;

  /// Minutes in one full turn (one lap).
  final int turn;

  /// Day-relative minute where the inner ring's lap begins.
  final int origin;

  /// Whether the visible laps move when a drag leaves them.
  final bool slides;

  static const int laps = 2;

  bool get isHour => turn == 60;

  /// First minute after the outer ring's lap.
  int get end => origin + laps * turn;

  /// Clock angle where the inner lap starts: 12 o'clock for whole hours,
  /// the minute hand for the live hour.
  double get seamAngle => angleOf(origin.toDouble());

  /// Earliest and latest minutes the dial can show (overflow lane included).
  int get minVisible => origin - turn;
  int get maxVisible => end + turn;

  DialSpec shifted(int turns) =>
      DialSpec(turn: turn, origin: origin + turns * turn, slides: slides);

  /// Clockwise angle from 12 o'clock for minute [u].
  double angleOf(double u) => (((u % turn) + turn) % turn) / turn * twoPi;

  /// 0 = inner ring, 1 = outer ring, anything else is off the rings.
  int lapOf(double u) => ((u - origin) / turn).floor();

  Lane laneOf(double u) => switch (lapOf(u)) {
    0 => Lane.inner,
    1 => Lane.outer,
    < 0 => Lane.before,
    _ => Lane.after,
  };

  /// Where minute [u] is drawn.
  ({Lane lane, double angle}) place(double u) =>
      (lane: laneOf(u), angle: angleOf(u));

  /// The minute shown at clock [angle] on lap [lap] (0 inner, 1 outer).
  double minuteAt(double angle, int lap) {
    final m = angle / twoPi * turn;
    final originPos = ((origin % turn) + turn) % turn;
    var offset = m - originPos;
    if (offset < 0) offset += turn;
    return origin + lap * turn + offset;
  }

  /// Splits `[start, end)` where it changes lane (the seam, the start of
  /// the outer lap, the end of the outer lap) so each piece can be drawn as
  /// one arc. Overflow beyond a full turn is dropped, keeping the turn
  /// nearest the rings.
  List<ArcPiece> pieces(double start, double end) {
    if (end <= start) return const [];
    final cuts = <double>[start];
    for (final b in [origin, origin + turn, this.end]) {
      if (b > start && b < end) cuts.add(b.toDouble());
    }
    cuts.add(end);
    final out = <ArcPiece>[];
    for (var i = 0; i < cuts.length - 1; i++) {
      var a = cuts[i];
      var z = cuts[i + 1];
      final lane = laneOf(a);
      if (lane.isOverflow && z - a > turn) {
        if (lane == Lane.before) {
          a = z - turn;
        } else {
          z = a + turn;
        }
      }
      out.add((
        lane: lane,
        startAngle: angleOf(a),
        sweep: (z - a) / turn * twoPi,
        startMin: a,
        endMin: z,
      ));
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is DialSpec &&
      other.turn == turn &&
      other.origin == origin &&
      other.slides == slides;

  @override
  int get hashCode => Object.hash(turn, origin, slides);
}

/// Clockwise angle from 12 o'clock, in `[0, 2π)`, of [p] around [center].
double clockAngle(Offset p, Offset center) {
  final a = math.atan2(p.dx - center.dx, -(p.dy - center.dy));
  return a < 0 ? a + twoPi : a;
}

/// Wraps [a] into `(-π, π]`.
double wrapPi(double a) {
  var r = a % twoPi;
  if (r > math.pi) r -= twoPi;
  if (r <= -math.pi) r += twoPi;
  return r;
}

/// Rounds [u] to the nearest multiple of [step].
int snapMinutes(double u, int step) => (u / step).round() * step;

/// Follows a finger around the dial.
///
/// The position is a single unbounded number [u] (day-relative minutes).
/// Each move adds the wrapped angle delta scaled to the dial's turn, so the
/// lap is decided by [u], not by the finger's radius: crossing the seam
/// moves to the next ring, and dragging backwards just works.
class SpiralTracker {
  SpiralTracker({
    required double startU,
    required double theta,
    required this.turn,
  }) : _u = startU,
       _lastTheta = theta;

  final int turn;
  double _u;
  double _lastTheta;

  double get u => _u;

  /// Feeds a new finger angle. Callers skip this while the finger is near
  /// the dial centre, where the angle is meaningless.
  void update(double theta) {
    _u += wrapPi(theta - _lastTheta) / twoPi * turn;
    _lastTheta = theta;
  }
}

/// Free space around [anchor] given occupied intervals, as `(lo, hi)`.
///
/// [occupied] holds `[start, end)` pairs in the same minute space as
/// [anchor]. The result is further limited to `anchor ± maxSpan`. An anchor
/// strictly inside an occupied interval has no free space.
({int lo, int hi}) freeRange(
  int anchor,
  Iterable<(int, int)> occupied, {
  int maxSpan = 1440,
}) {
  var lo = anchor - maxSpan;
  var hi = anchor + maxSpan;
  for (final (s, e) in occupied) {
    if (s < anchor && anchor < e) return (lo: anchor, hi: anchor);
    if (e <= anchor && e > lo) lo = e;
    if (s >= anchor && s < hi) hi = s;
  }
  return (lo: lo, hi: hi);
}
