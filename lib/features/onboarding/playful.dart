import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../clock/clock_geometry.dart';
import '../clock/spiral_math.dart';

/// Tour progress as a little donut: one arc per step, filled in as you go.
class StepRing extends StatelessWidget {
  const StepRing({super.key, required this.step, required this.count});

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: step.toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => CustomPaint(
        size: const Size.square(30),
        painter: _StepRingPainter(
          v,
          count,
          scheme.primary,
          scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _StepRingPainter extends CustomPainter {
  _StepRingPainter(this.done, this.count, this.ink, this.track);

  final double done;
  final int count;
  final Color ink;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    const gap = 0.32;
    final sweep = 2 * math.pi / count;
    for (var i = 0; i < count; i++) {
      final from = -math.pi / 2 + i * sweep + gap / 2;
      final fill = (done - i + 1).clamp(0.0, 1.0);
      arc.color = track;
      canvas.drawArc(rect.deflate(3), from, sweep - gap, false, arc);
      if (fill > 0) {
        arc.color = ink;
        canvas.drawArc(rect.deflate(3), from, (sweep - gap) * fill, false, arc);
      }
    }
  }

  @override
  bool shouldRepaint(_StepRingPainter old) =>
      old.done != done || old.ink != ink || old.track != track;
}

/// Sprinkles bursting out of [origin] (as a fraction of the area) each
/// time [fire] changes, in the entries' palette.
class SprinkleBurst extends StatefulWidget {
  const SprinkleBurst({
    super.key,
    required this.fire,
    this.origin = const Offset(0.5, 0.45),
    this.pieces = 60,
  });

  final int fire;
  final Offset origin;
  final int pieces;

  @override
  State<SprinkleBurst> createState() => _SprinkleBurstState();
}

class _SprinkleBurstState extends State<SprinkleBurst>
    with SingleTickerProviderStateMixin {
  late final _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  final _random = math.Random();
  List<_Sprinkle> _pieces = const [];

  @override
  void didUpdateWidget(SprinkleBurst old) {
    super.didUpdateWidget(old);
    if (widget.fire != old.fire && widget.fire > 0) {
      _pieces = [
        for (var i = 0; i < widget.pieces; i++)
          _Sprinkle(
            angle: _random.nextDouble() * 2 * math.pi,
            speed: 0.25 + _random.nextDouble() * 0.45,
            spin: (_random.nextDouble() - 0.5) * 10,
            tilt: _random.nextDouble() * math.pi,
            color: Color(entryPalette[i % entryPalette.length]),
          ),
      ];
      _t.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _t,
      builder: (_, _) => CustomPaint(
        size: Size.infinite,
        painter: _t.isAnimating
            ? _BurstPainter(
                _pieces,
                Curves.easeOut.transform(_t.value),
                _t.value,
                widget.origin,
              )
            : null,
      ),
    ),
  );
}

class _Sprinkle {
  const _Sprinkle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.tilt,
    required this.color,
  });

  final double angle;
  final double speed;
  final double spin;
  final double tilt;
  final Color color;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.pieces, this.reach, this.t, this.origin);

  final List<_Sprinkle> pieces;

  /// Eased distance travelled (0 → 1) and raw time (0 → 1).
  final double reach;
  final double t;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final o = Offset(size.width * origin.dx, size.height * origin.dy);
    final scale = size.shortestSide;
    final fade = t < 0.6 ? 1.0 : (1 - t) / 0.4;
    for (final p in pieces) {
      final dir = Offset(math.cos(p.angle), math.sin(p.angle));
      // Out from the dial, then drifting down a little.
      final pos = o + dir * p.speed * scale * reach + Offset(0, 40 * t * t);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.tilt + p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 13, height: 5),
          const Radius.circular(2.5),
        ),
        Paint()..color = p.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// A few sprinkles drifting slowly behind the tour.
class DriftingSprinkles extends StatefulWidget {
  const DriftingSprinkles({super.key});

  @override
  State<DriftingSprinkles> createState() => _DriftingSprinklesState();
}

class _DriftingSprinklesState extends State<DriftingSprinkles>
    with SingleTickerProviderStateMixin {
  late final _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _DriftPainter(
            _t.value,
            Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.22,
          ),
        ),
      ),
    ),
  );
}

class _DriftPainter extends CustomPainter {
  _DriftPainter(this.t, this.alpha);

  final double t;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 16; i++) {
      // Fixed lanes, each sprinkle rising slowly at its own pace.
      final x = (i * 0.618 % 1) * size.width;
      final speed = 0.5 + (i * 0.37 % 1);
      final y = (1 - ((t * speed + i * 0.13) % 1)) * (size.height + 40) - 20;
      canvas.save();
      canvas.translate(x + math.sin(t * 2 * math.pi * speed + i) * 12, y);
      canvas.rotate(i * 0.9 + t * 2 * math.pi * (i.isEven ? 1 : -1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 16, height: 6),
          const Radius.circular(3),
        ),
        Paint()
          ..color = Color(entryPalette[i % entryPalette.length])
              .withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DriftPainter old) => old.t != t;
}

/// The gesture a [GhostFinger] demonstrates.
enum GhostMove { drag, holdFlick, tap }

/// A translucent fingertip looping over a dial to show a gesture: drag
/// along a ring (leaving a trail), hold then flick up, or tap.
class GhostFinger extends StatefulWidget {
  const GhostFinger({
    super.key,
    required this.move,
    required this.spec,
    required this.from,
    this.to = 0,
  });

  final GhostMove move;
  final DialSpec spec;

  /// Day-relative minutes: where the finger lands, and (for a drag) where
  /// it lifts.
  final int from;
  final int to;

  @override
  State<GhostFinger> createState() => _GhostFingerState();
}

class _GhostFingerState extends State<GhostFinger>
    with SingleTickerProviderStateMixin {
  late final _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final side = math.min(c.maxWidth, c.maxHeight);
          final g = ClockGeometry(Size.square(side), widget.spec);
          return AnimatedBuilder(
            animation: _t,
            builder: (_, _) => CustomPaint(
              size: Size.square(side),
              painter: _GhostPainter(widget, g, _t.value, scheme),
            ),
          );
        },
      ),
    );
  }
}

class _GhostPainter extends CustomPainter {
  _GhostPainter(this.w, this.g, this.t, this.scheme);

  final GhostFinger w;
  final ClockGeometry g;
  final double t;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final start = g.pointForMinute(w.from.toDouble());
    final ink = scheme.onSurface;
    void finger(Offset p, {double press = 0, double alpha = 1}) {
      if (alpha <= 0) return;
      canvas.drawCircle(
        p,
        22 - press * 4,
        Paint()..color = ink.withValues(alpha: 0.18 * alpha),
      );
      canvas.drawCircle(
        p,
        22 - press * 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = ink.withValues(alpha: 0.55 * alpha),
      );
    }

    void ripple(Offset p, double k) {
      if (k <= 0 || k >= 1) return;
      canvas.drawCircle(
        p,
        22 + 26 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = scheme.primary.withValues(alpha: 0.6 * (1 - k)),
      );
    }

    double phase(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
    final appear = phase(0, 0.12);
    switch (w.move) {
      case GhostMove.drag:
        final k = Curves.easeInOut.transform(phase(0.15, 0.7));
        final u = w.from + (w.to - w.from) * k;
        final lift = phase(0.75, 0.9);
        if (k > 0) {
          // The entry the drag would draw.
          final (r0, r1) = g.laneBounds(g.spec.laneOf(w.from.toDouble()));
          final mid = (r0 + r1) / 2;
          final a0 = g.spec.angleOf(w.from.toDouble()) - math.pi / 2;
          final sweep = (u - w.from) / g.spec.turn * 2 * math.pi;
          canvas.drawArc(
            Rect.fromCircle(center: g.center, radius: mid),
            a0,
            sweep,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = (r1 - r0) * 0.8
              ..color = scheme.primary.withValues(alpha: 0.35 * (1 - lift)),
          );
        }
        finger(
          g.pointForMinute(u),
          press: k > 0 ? 1 : 0,
          alpha: appear * (1 - lift),
        );
      case GhostMove.holdFlick:
        final hold = phase(0.15, 0.55);
        final flick = Curves.easeOut.transform(phase(0.6, 0.78));
        final gone = phase(0.8, 0.92);
        ripple(start, hold);
        finger(
          start + Offset(0, -90 * flick),
          press: hold > 0 ? 1 : 0,
          alpha: appear * (1 - gone),
        );
      case GhostMove.tap:
        final press = phase(0.2, 0.3) - phase(0.3, 0.4);
        ripple(start, phase(0.3, 0.7));
        finger(start, press: press, alpha: appear * (1 - phase(0.6, 0.8)));
    }
  }

  @override
  bool shouldRepaint(_GhostPainter old) => old.t != t || old.g != g;
}
