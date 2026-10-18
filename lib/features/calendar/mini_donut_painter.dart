import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../clock/spiral_math.dart';

class MiniArc {
  const MiniArc(this.start, this.end, this.color, {this.draft = false});

  /// Day-relative minutes; parts outside the day are clipped.
  final int start;
  final int end;
  final Color color;
  final bool draft;
}

/// A tiny two-ring clock: the day at a glance for calendar cells.
class MiniDonutPainter extends CustomPainter {
  MiniDonutPainter({required this.arcs, required this.track});

  final List<MiniArc> arcs;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;
    final w = r * 0.22;
    final rings = {Lane.inner: r * 0.62, Lane.outer: r - w / 2};
    for (final radius in rings.values) {
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = track,
      );
    }
    for (final a in arcs) {
      final s = math.max(a.start, 0).toDouble();
      final e = math.min(a.end, 1440).toDouble();
      for (final p in const DialSpec.day().pieces(s, e)) {
        final radius = rings[p.lane];
        if (radius == null) continue;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: radius),
          p.startAngle - math.pi / 2,
          p.sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..color = a.draft ? a.color.withValues(alpha: 0.4) : a.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MiniDonutPainter old) =>
      old.arcs != arcs || old.track != track;
}
