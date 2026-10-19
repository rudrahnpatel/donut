/// Side-by-side lanes for overlapping blocks.
///
/// Blocks that overlap (directly or through a chain of overlaps) form a
/// cluster that shares the ring's width as columns, the way a calendar lays
/// out clashing events: while it overlaps others a block keeps one column
/// (widened into neighbouring columns free for its whole length), so it
/// never zig-zags as the overlaps around it come and go. Wherever a block
/// is alone it uses the full width. The same layout drives drawing and hit-testing, so a press on
/// the outer half of an overlap picks the block drawn there.
library;

/// A block as the dial sees it: day-relative minutes `[start, end)`.
class ClockSpan {
  const ClockSpan(this.id, this.start, this.end);
  final String id;
  final int start;
  final int end;

  bool contains(double u) => start <= u && u < end;
}

/// Part of a block's place across the ring's width: columns [index] to
/// `index + span - 1` of [count] over `[start, end)`.
class LanePiece {
  const LanePiece(
    this.id,
    this.start,
    this.end,
    this.index,
    this.count, {
    this.span = 1,
  });
  final String id;
  final int start;
  final int end;
  final int index;
  final int count;
  final int span;

  @override
  String toString() => 'LanePiece($id, $start–$end, $index+$span/$count)';
}

/// Lays out [spans] in columns per cluster of overlapping blocks: each block
/// takes the first column free at its start (earlier start first, then the
/// longer block, then id), then widens over the next columns while none of
/// their blocks overlaps it. Stretches where it overlaps nothing are full
/// width. A block's pieces come in time order.
List<LanePiece> splitOverlaps(List<ClockSpan> spans) {
  if (spans.isEmpty) return const [];
  final sorted = [...spans]
    ..sort((a, b) {
      final c = a.start.compareTo(b.start);
      if (c != 0) return c;
      final d = b.end.compareTo(a.end);
      return d != 0 ? d : a.id.compareTo(b.id);
    });
  final out = <LanePiece>[];
  var cluster = <(ClockSpan, int)>[];
  final columnEnds = <int>[];
  var clusterEnd = sorted.first.start;

  void flush() {
    final count = columnEnds.length;
    bool overlaps(ClockSpan a, ClockSpan b) =>
        a.start < b.end && b.start < a.end;
    for (final (s, col) in cluster) {
      var span = 1;
      while (col + span < count &&
          !cluster.any((o) => o.$2 == col + span && overlaps(o.$1, s))) {
        span++;
      }
      // Where others overlap it, merged and clipped to this block.
      final shared = <(int, int)>[];
      for (final (o, _) in [
        ...cluster,
      ]..sort((a, b) => a.$1.start.compareTo(b.$1.start))) {
        if (identical(o, s) || !overlaps(o, s)) continue;
        final a = o.start < s.start ? s.start : o.start;
        final b = o.end > s.end ? s.end : o.end;
        if (shared.isNotEmpty && a <= shared.last.$2) {
          if (b > shared.last.$2) shared.last = (shared.last.$1, b);
        } else {
          shared.add((a, b));
        }
      }
      var at = s.start;
      for (final (a, b) in shared) {
        if (a > at) out.add(LanePiece(s.id, at, a, 0, 1));
        out.add(LanePiece(s.id, a, b, col, count, span: span));
        at = b;
      }
      if (at < s.end) out.add(LanePiece(s.id, at, s.end, 0, 1));
    }
    cluster = [];
    columnEnds.clear();
  }

  for (final s in sorted) {
    if (cluster.isNotEmpty && s.start >= clusterEnd) flush();
    var col = columnEnds.indexWhere((end) => end <= s.start);
    if (col < 0) {
      col = columnEnds.length;
      columnEnds.add(s.end);
    } else {
      columnEnds[col] = s.end;
    }
    cluster.add((s, col));
    if (cluster.length == 1 || s.end > clusterEnd) clusterEnd = s.end;
  }
  flush();
  return out;
}

/// The piece under minute [u] at [fraction] (0 = inner edge, 1 = outer
/// edge) of the ring's width, or null if nothing is there.
LanePiece? pieceAt(List<LanePiece> pieces, double u, double fraction) {
  LanePiece? hit;
  for (final p in pieces) {
    if (u < p.start || u >= p.end) continue;
    final lane = (fraction.clamp(0.0, 0.999) * p.count).floor();
    if (lane >= p.index && lane < p.index + p.span) return p;
    hit ??= p;
  }
  return hit;
}
