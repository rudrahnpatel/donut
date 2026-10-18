/// Side-by-side lanes for overlapping blocks.
///
/// Where blocks overlap, the ring is split radially between them (halves
/// for two, thirds for three, ...); where a block is alone it uses the full
/// ring width. The same layout drives drawing and hit-testing, so a press
/// on the outer half of an overlap picks the block drawn there.
library;

/// A block as the dial sees it: day-relative minutes `[start, end)`.
class ClockSpan {
  const ClockSpan(this.id, this.start, this.end);
  final String id;
  final int start;
  final int end;

  bool contains(double u) => start <= u && u < end;
}

/// Part of a block over which the set of overlapping blocks is constant.
/// It occupies sub-lane [index] of [count] across the ring's width.
class LanePiece {
  const LanePiece(this.id, this.start, this.end, this.index, this.count);
  final String id;
  final int start;
  final int end;
  final int index;
  final int count;

  @override
  String toString() => 'LanePiece($id, $start–$end, $index/$count)';
}

/// Splits [spans] at every start and end, giving each slice's blocks
/// consecutive sub-lanes in a stable order (earlier start first, then the
/// longer block, then id). Adjacent slices of one block with the same lane
/// are merged.
List<LanePiece> splitOverlaps(List<ClockSpan> spans) {
  if (spans.isEmpty) return const [];
  final sorted = [...spans]
    ..sort((a, b) {
      final c = a.start.compareTo(b.start);
      if (c != 0) return c;
      final d = b.end.compareTo(a.end);
      return d != 0 ? d : a.id.compareTo(b.id);
    });
  final cuts = <int>{
    for (final s in sorted) ...[s.start, s.end],
  }.toList()..sort();
  final out = <LanePiece>[];
  final last = <String, int>{}; // id → index in out of its latest piece
  for (var i = 0; i < cuts.length - 1; i++) {
    final a = cuts[i], b = cuts[i + 1];
    final active = [
      for (final s in sorted)
        if (s.start <= a && s.end >= b) s,
    ];
    for (var j = 0; j < active.length; j++) {
      final s = active[j];
      final prevAt = last[s.id];
      final prev = prevAt == null ? null : out[prevAt];
      if (prev != null &&
          prev.end == a &&
          prev.index == j &&
          prev.count == active.length) {
        out[prevAt!] = LanePiece(s.id, prev.start, b, j, active.length);
      } else {
        last[s.id] = out.length;
        out.add(LanePiece(s.id, a, b, j, active.length));
      }
    }
  }
  return out;
}

/// The piece under minute [u] at [fraction] (0 = inner edge, 1 = outer
/// edge) of the ring's width, or null if nothing is there.
LanePiece? pieceAt(List<LanePiece> pieces, double u, double fraction) {
  LanePiece? hit;
  for (final p in pieces) {
    if (u < p.start || u >= p.end) continue;
    final lane = (fraction.clamp(0.0, 0.999) * p.count).floor();
    if (p.index == lane) return p;
    hit ??= p;
  }
  return hit;
}
