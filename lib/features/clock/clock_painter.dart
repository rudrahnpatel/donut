import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../data/repos/block_repo.dart';
import 'clock_geometry.dart';
import 'overlap_layout.dart';
import 'spiral_math.dart';

/// A block ready to paint, in day-relative minutes.
class PaintBlock {
  const PaintBlock({
    required this.id,
    required this.start,
    required this.end,
    required this.color,
    this.emoji,
    this.status = BlockStatus.saved,
  });

  final String id;
  final int start;
  final int end;
  final Color color;
  final String? emoji;
  final BlockStatus status;
}

class ClockPainter extends CustomPainter {
  ClockPainter({
    required this.spec,
    required this.blocks,
    required this.scheme,
    required this.captions,
    this.preview,
    this.selectedId,
    this.nowU,
    this.dimAll = false,
    this.ghosts = const [],
    this.lapOffset = 0,
  });

  final DialSpec spec;
  final List<PaintBlock> blocks;
  final ColorScheme scheme;

  /// Small labels for the inner and outer rings ("AM"/"PM"); empty strings
  /// draw nothing.
  final (String, String) captions;
  final PaintBlock? preview;
  final String? selectedId;

  /// Day-relative minute of "now" if this day is today.
  final double? nowU;

  /// Whole day is in the past.
  final bool dimAll;

  /// Busy times from other calendars, day-relative.
  final List<(int, int)> ghosts;

  /// While the hour changes, entries glide between rings: each is drawn
  /// [lapOffset] laps further out than its final ring (+1 → 0 when moving
  /// forward an hour, so time visibly flows inward; -1 → 0 going back).
  final double lapOffset;

  bool get _animating => lapOffset != 0;

  @override
  void paint(Canvas canvas, Size size) {
    final g = ClockGeometry(size, spec);
    _tracks(canvas, g);
    _ticks(canvas, g);
    _numerals(canvas, g);
    if (!spec.isHour) _captions(canvas, g);
    for (final (s, e) in ghosts) {
      for (final p in spec.pieces(s.toDouble(), e.toDouble())) {
        final (r0, r1) = g.laneBounds(p.lane);
        canvas.drawPath(
          _sector(g, r0, r1, p.startAngle, p.sweep, inset: 6),
          Paint()..color = scheme.onSurface.withValues(alpha: 0.10),
        );
      }
    }

    // Overlapping blocks share the ring width side by side; each block is
    // still one continuous shape that narrows where it overlaps.
    final shown = [
      for (final b in blocks)
        if (b.id != preview?.id && _inWindow(b.start, b.end)) b,
    ];
    final byId = {for (final b in shown) b.id: b};
    final pieces = splitOverlaps([
      for (final b in shown) ClockSpan(b.id, b.start, b.end),
    ]);
    for (final b in shown) {
      final mine = [
        for (final p in pieces)
          if (p.id == b.id) p,
      ];
      _block(canvas, g, b, mine, selected: b.id == selectedId);
      _emoji(canvas, g, b, mine);
    }
    if (!_animating) _pastScrim(canvas, g);
    if (spec.isHour) _captions(canvas, g);
    if (preview != null) {
      final p = preview!;
      _block(
        canvas,
        g,
        p,
        [LanePiece(p.id, p.start, p.end, 0, 1)],
        selected: true,
        isPreview: true,
      );
    }
    if (selectedId != null && preview == null) {
      final sel = byId[selectedId];
      if (sel != null && !_animating) _handles(canvas, g, sel);
    }
    if (!_animating) _nowHand(canvas, g);
  }

  /// Only blocks touching the two rings are drawn; their parts beyond the
  /// rings spill onto the overflow lane. Blocks wholly outside are not
  /// shown at all, or the lane would fill with unrelated hours.
  /// While animating, the window also covers the hour leaving the rings so
  /// its entries can glide away instead of vanishing.
  bool _inWindow(int s, int e) {
    final lo = spec.origin - (lapOffset > 0 ? spec.turn : 0);
    final hi = spec.end + (lapOffset < 0 ? spec.turn : 0);
    return e > lo && s < hi;
  }

  /// In the window once the animation settles.
  bool _inFinalWindow(int s, int e) => e > spec.origin && s < spec.end;

  /// Ring position of [lane]: -1 inside band, 0 inner, 1 outer, 2 outside.
  static int _lap(Lane lane) => switch (lane) {
    Lane.before => -1,
    Lane.inner => 0,
    Lane.outer => 1,
    Lane.after => 2,
  };

  /// Radii for [lane], shifted by [lapOffset] mid-animation by blending
  /// between neighbouring rings.
  (double, double) _radii(ClockGeometry g, Lane lane) {
    if (!_animating) return g.laneBounds(lane);
    const order = [Lane.before, Lane.inner, Lane.outer, Lane.after];
    final x = (_lap(lane) + lapOffset).clamp(-1.0, 2.0);
    final k = math.min(x.floor(), 1);
    final f = x - k;
    final (a0, a1) = g.laneBounds(order[k + 1]);
    final (b0, b1) = g.laneBounds(order[k + 2]);
    return (a0 + (b0 - a0) * f, a1 + (b1 - a1) * f);
  }

  /// Opacity factor for an entry on [lane]: the bands and the hour dial's
  /// outer (next-hour) ring are faded; blended mid-animation.
  double _laneFade(Lane lane) {
    final levels = [0.55, 1.0, spec.isHour ? 0.5 : 1.0, 0.55];
    final x = (_lap(lane) + lapOffset).clamp(-1.0, 2.0) + 1;
    final k = math.min(x.floor(), 2);
    final f = x - k;
    return levels[k] + (levels[k + 1] - levels[k]) * f;
  }

  void _tracks(Canvas canvas, ClockGeometry g) {
    final track = Paint()..color = scheme.surfaceContainerHighest;
    for (final lane in [Lane.inner, Lane.outer]) {
      canvas.drawPath(_annulus(g, lane), track);
    }
    // The thin bands for time before (inside) and after (outside) the two
    // rings are always there, faintly, so the dial keeps the same shape in
    // every hour whether or not anything spills onto them.
    final band = Paint()..color = scheme.surfaceContainer;
    for (final lane in [Lane.before, Lane.after]) {
      canvas.drawPath(_annulus(g, lane), band);
    }
  }

  /// A full ring as a filled path. Thick stroked circles hit an Impeller
  /// (OpenGLES SDF) bug when they touch the layer edge, painting the
  /// bounding square's corners.
  Path _annulus(ClockGeometry g, Lane lane) {
    final (r0, r1) = g.laneBounds(lane);
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: g.center, radius: r1))
      ..addOval(Rect.fromCircle(center: g.center, radius: r0));
  }

  void _ticks(Canvas canvas, ClockGeometry g) {
    final major = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    if (spec.isHour) {
      // Hour dial: one quiet tick every five minutes on each ring's inner
      // edge, nothing else.
      for (final lane in [Lane.inner, Lane.outer]) {
        final (r0, r1) = g.laneBounds(lane);
        for (var q = 0; q < 12; q++) {
          final a = q / 12 * twoPi;
          final long = q % 3 == 0;
          canvas.drawLine(
            g.pointAt(a, r0 + 3),
            g.pointAt(a, r0 + (r1 - r0) * (long ? 0.3 : 0.16)),
            major,
          );
        }
      }
      return;
    }
    final minor = Paint()..color = scheme.outlineVariant.withValues(alpha: 0.6);
    for (final lane in [Lane.inner, Lane.outer]) {
      final (r0, r1) = g.laneBounds(lane);
      for (var q = 0; q < 48; q++) {
        final a = q / 48 * twoPi;
        if (q % 4 == 0) {
          canvas.drawLine(
            g.pointAt(a, r0 + 3),
            g.pointAt(a, r0 + (r1 - r0) * 0.28),
            major,
          );
          canvas.drawLine(
            g.pointAt(a, r1 - (r1 - r0) * 0.28),
            g.pointAt(a, r1 - 3),
            major,
          );
        } else {
          canvas.drawCircle(g.pointAt(a, r1 - 4), 0.9, minor);
        }
      }
    }
  }

  void _numerals(Canvas canvas, ClockGeometry g) {
    final fs = g.radius * 0.078;
    // Day dial: the twelve hours. Hour dial: only the quarters, so the hub
    // stays readable.
    final marks = spec.isHour
        ? const [0, 3, 6, 9]
        : List.generate(12, (h) => h);
    for (final h in marks) {
      final major = h % 3 == 0;
      final text = spec.isHour
          ? (h * 5).toString().padLeft(2, '0')
          : '${h == 0 ? 12 : h}';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: spec.isHour ? fs * 0.95 : (major ? fs * 1.15 : fs),
            fontWeight: major ? FontWeight.w900 : FontWeight.w700,
            color: spec.isHour
                ? scheme.onSurfaceVariant
                : (major ? scheme.onSurface : scheme.onSurfaceVariant),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final r = spec.isHour ? g.beforeR0 - fs * 0.8 : g.numeralR;
      final p = g.pointAt(h / 12 * twoPi, r);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  /// Ring captions just before the seam. On the day dial ("AM"/"PM") they
  /// sit under the blocks; on the hour dial the outer ring's hour tag is
  /// drawn over its faded blocks so it always reads.
  void _captions(Canvas canvas, ClockGeometry g) {
    for (final (lane, label) in [
      (Lane.inner, captions.$1),
      (Lane.outer, captions.$2),
    ]) {
      if (label.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: g.radius * 0.042,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final mid = g.laneMid(lane);
      final p = g.pointAt(spec.seamAngle - (tp.width / 2 + 6) / mid, mid);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  /// Draws block [b] from its lane pieces [mine]: one continuous shape per
  /// ring, full width where the block is alone and narrowed to its sub-lane
  /// where it overlaps others. Gaps appear only at the block's own ends.
  void _block(
    Canvas canvas,
    ClockGeometry g,
    PaintBlock b,
    List<LanePiece> mine, {
    required bool selected,
    bool isPreview = false,
  }) {
    final base = b.color;
    final status = isPreview ? BlockStatus.pending : b.status;
    final alpha = switch (status) {
      BlockStatus.saved => 1.0,
      BlockStatus.pending => 0.85,
      BlockStatus.draft => 0.7,
      BlockStatus.conflict => 0.85,
    };

    // Each lane piece, cut further wherever the block changes ring.
    final segs = <_Seg>[];
    for (final lp in [...mine]..sort((x, y) => x.start.compareTo(y.start))) {
      final arcs = spec.pieces(
        math.max(lp.start, spec.minVisible).toDouble(),
        math.min(lp.end, spec.maxVisible).toDouble(),
      );
      for (final arc in arcs) {
        // The overflow lane is too thin to split.
        final onLane = arc.lane.isOverflow;
        final count = onLane ? 1 : lp.count;
        final index = onLane ? 0 : lp.index;
        final (lr0, lr1) = _radii(g, arc.lane);
        final w = (lr1 - lr0) / count;
        // Ring edges keep a 2.5 px margin; an edge shared with another
        // block's sub-lane gives up half of the gap between them.
        final r0 = lr0 + w * index + (index == 0 ? 2.5 : 1.2);
        final r1 = lr0 + w * (index + 1) - (index == count - 1 ? 2.5 : 1.2);
        segs.add(
          _Seg(
            arc.lane,
            arc.startAngle,
            arc.sweep,
            r0,
            r1,
            arc.startMin,
            arc.endMin,
          ),
        );
      }
    }

    // Segments on the same ring that follow on in time form one shape.
    final runs = <List<_Seg>>[];
    for (final seg in segs) {
      final last = runs.isEmpty ? null : runs.last.last;
      if (last != null &&
          last.lane == seg.lane &&
          last.endMin == seg.startMin) {
        runs.last.add(seg);
      } else {
        runs.add([seg]);
      }
    }

    for (final run in runs) {
      final path = _runPath(g, run);
      // Bands and the hour dial's next-hour ring are faded; an entry that
      // is leaving the rings fades out as the animation settles.
      final leaving = _inFinalWindow(b.start, b.end) ? 1.0 : lapOffset.abs();
      final fill = base.withValues(
        alpha: alpha * _laneFade(run.first.lane) * leaving,
      );
      canvas.drawPath(path, Paint()..color = fill);
      // Soften corners: a thin stroke in the same colour with round joins.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2
          ..color = fill,
      );
      if (status == BlockStatus.draft) {
        _dashed(
          canvas,
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = scheme.surface.withValues(alpha: 0.7),
        );
      }
      if (status == BlockStatus.conflict) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = scheme.error,
        );
      }
      if (selected) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round
            ..color = scheme.onSurface,
        );
      }
    }
  }

  /// One closed outline through consecutive segments of a ring: along each
  /// segment's outer edge, then back along the inner edges. Where the
  /// sub-lane changes, the edges step radially instead of breaking.
  Path _runPath(ClockGeometry g, List<_Seg> run) {
    final total = run.fold<double>(0, (t, s) => t + s.sweep);
    final gap = math.min(2.5 / run.first.r1, total / 4);
    // A whole turn would make the outline meet itself; keep a sliver open.
    final excess = math.max(0.0, total - 2 * gap - (twoPi - 0.0002));
    final n = run.length;
    final from = <double>[], to = <double>[];
    for (var i = 0; i < n; i++) {
      from.add(run[i].a0 + (i == 0 ? gap : 0));
      to.add(
        math.max(
          from[i] + 0.0001,
          run[i].a0 + run[i].sweep - (i == n - 1 ? gap + excess : 0),
        ),
      );
    }
    Rect circle(double r) => Rect.fromCircle(center: g.center, radius: r);
    const top = math.pi / 2; // canvas angles start at 3 o'clock
    final path = Path();
    for (var i = 0; i < n; i++) {
      path.arcTo(circle(run[i].r1), from[i] - top, to[i] - from[i], i == 0);
    }
    for (var i = n - 1; i >= 0; i--) {
      path.arcTo(circle(run[i].r0), to[i] - top, from[i] - to[i], false);
    }
    return path..close();
  }

  /// Emoji on the block's longest on-ring piece, if it fits.
  void _emoji(
    Canvas canvas,
    ClockGeometry g,
    PaintBlock b,
    List<LanePiece> mine,
  ) {
    final emoji = b.emoji;
    if (emoji == null) return;
    ({double angle, double r, double room, double size})? best;
    for (final piece in mine) {
      for (final arc in spec.pieces(
        piece.start.toDouble(),
        piece.end.toDouble(),
      )) {
        if (arc.lane.isOverflow) continue;
        final (lr0, lr1) = _radii(g, arc.lane);
        final w = (lr1 - lr0) / piece.count;
        final r = lr0 + w * (piece.index + 0.5);
        final size = math.min(w * 0.62, (lr1 - lr0) * 0.52);
        final room = arc.sweep * r;
        if (best == null || room > best.room) {
          best = (
            angle: arc.startAngle + arc.sweep / 2,
            r: r,
            room: room,
            size: size,
          );
        }
      }
    }
    if (best == null || best.size < 10 || best.room < best.size * 1.1) return;
    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: emojiStyle.copyWith(fontSize: best.size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final p = g.pointAt(best.angle, best.r);
    tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
  }

  void _handles(Canvas canvas, ClockGeometry g, PaintBlock b) {
    final fill = Paint()..color = scheme.surface;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = scheme.onSurface;
    for (final p in [
      g.pointForMinute(b.start.toDouble()),
      g.pointForEnd(b.end.toDouble()),
    ]) {
      canvas.drawCircle(p, 9, fill);
      canvas.drawCircle(p, 9, ring);
    }
  }

  void _pastScrim(Canvas canvas, ClockGeometry g) {
    final double end;
    if (dimAll) {
      end = spec.maxVisible.toDouble();
    } else if (nowU != null) {
      end = math.min(nowU!, spec.maxVisible.toDouble());
    } else {
      return;
    }
    final scrim = Paint()..color = scheme.surface.withValues(alpha: 0.45);
    // Everything on the inside band is earlier than the inner ring, so it
    // is past as soon as the inner ring's hour has started.
    if (end > spec.origin) canvas.drawPath(_annulus(g, Lane.before), scrim);
    if (dimAll) canvas.drawPath(_annulus(g, Lane.after), scrim);
    for (final p in spec.pieces(spec.origin.toDouble(), end)) {
      if (p.lane.isOverflow) continue;
      final (r0, r1) = g.laneBounds(p.lane);
      canvas.drawPath(
        _sector(g, r0, r1, p.startAngle, p.sweep, inset: 0),
        scrim,
      );
    }
  }

  /// The minute hand runs from the hub's edge to its ring, so it never
  /// cuts through the text in the hub.
  void _nowHand(Canvas canvas, ClockGeometry g) {
    final u = nowU;
    if (u == null || u < spec.origin || u >= spec.end) return;
    final place = spec.place(u);
    final (_, r1) = g.laneBounds(place.lane);
    const red = Color(0xFFE5484D);
    final paint = Paint()
      ..color = red
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final tail = g.pointAt(place.angle, g.innerR0 * 0.62);
    final tip = g.pointAt(place.angle, r1 + 2);
    canvas.drawLine(tail, tip, paint);
    canvas.drawCircle(tip, 3.5, Paint()..color = red);
    canvas.drawCircle(tail, 3, Paint()..color = red);
  }

  Path _sector(
    ClockGeometry g,
    double r0,
    double r1,
    double a0,
    double sweep, {
    required double inset,
  }) {
    r0 += inset;
    r1 -= inset;
    // A hair of angular gap so touching blocks stay distinguishable.
    final gap = inset > 0 ? math.min(2.5 / r1, sweep / 4) : 0.0;
    final start = a0 + gap - math.pi / 2;
    // A sweep of exactly 2π makes arcTo degenerate (start == end), so a
    // fully covered ring would vanish.
    final s = (sweep - 2 * gap).clamp(0.0001, twoPi - 0.0001);
    return Path()
      ..arcTo(Rect.fromCircle(center: g.center, radius: r1), start, s, true)
      ..arcTo(
        Rect.fromCircle(center: g.center, radius: r0),
        start + s,
        -s,
        false,
      )
      ..close();
  }

  static void _dashed(Canvas canvas, Path path, Paint paint) {
    const dash = 6.0, gap = 4.0;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(ClockPainter old) =>
      old.spec != spec ||
      old.blocks != blocks ||
      old.preview != preview ||
      old.selectedId != selectedId ||
      old.nowU != nowU ||
      old.dimAll != dimAll ||
      old.scheme != scheme ||
      old.ghosts != ghosts ||
      old.captions != captions ||
      old.lapOffset != lapOffset;
}

/// A stretch of one block on one ring at a fixed sub-lane.
class _Seg {
  const _Seg(
    this.lane,
    this.a0,
    this.sweep,
    this.r0,
    this.r1,
    this.startMin,
    this.endMin,
  );
  final Lane lane;
  final double a0;
  final double sweep;
  final double r0;
  final double r1;
  final double startMin;
  final double endMin;
}
