import 'dart:math' as math;
import 'dart:ui';

/// One entry in the marking menu.
///
/// [children] is evaluated lazily when the item's sub-fan opens; null means
/// the item is a leaf. Items with children can still be chosen themselves by
/// releasing in their sub-fan's centre (e.g. an activity without picking one
/// of its to-dos).
class MarkingItem {
  const MarkingItem({
    required this.id,
    required this.glyph,
    this.label,
    this.children,
    this.isText = false,
  });

  final String id;
  final String glyph;
  final String? label;
  final List<MarkingItem> Function()? children;

  /// Drawn as a text pill showing [label] (to-dos, labels) instead of a
  /// round glyph, so it needs more room in the fan.
  final bool isText;

  bool get hasChildren => children != null;

  /// Rough on-screen width, used to space the fan.
  double get extent => isText
      ? math.min(130, 28 + 7.5 * (label?.length ?? 0)).toDouble()
      : MarkingMenuController.itemRadius * 2;
}

/// One fan of items around [center].
class MarkingLevel {
  MarkingLevel({
    required this.center,
    required this.radius,
    required this.items,
    required this.angles,
    required this.sector,
    required this.collapseDist,
    required this.anchor,
  });

  /// Centre the items fan out from; may be shifted from [anchor] to stay on
  /// screen.
  final Offset center;

  /// Where the fan was opened (the pressed point, or the parent item).
  final Offset anchor;
  final double radius;
  final List<MarkingItem> items;

  /// Screen angle of each item (radians, 0 = +x, clockwise since y is down).
  final List<double> angles;
  final double sector;

  /// Moving closer than this to the *parent* centre collapses this level.
  final double collapseDist;

  int? highlighted;
  Duration highlightedSince = Duration.zero;

  Offset itemPos(int i) =>
      center + Offset(math.cos(angles[i]), math.sin(angles[i])) * radius;
}

/// Hit-tolerant geometry and state for a hierarchical marking menu.
///
/// Selection is by angle sector, never by hit box: once the pointer is
/// [selectDist] from a fan's centre, the item whose direction is nearest is
/// highlighted. A sub-fan opens when the pointer reaches the item, or rests
/// on it for [dwell]; it is centred on that item so the same flick direction
/// keeps working. Moving back towards the parent collapses it.
class MarkingMenuController {
  MarkingMenuController({
    required Offset origin,
    required List<MarkingItem> rootItems,
    required this.bounds,
    this.onHighlight,
  }) {
    final base = _pickBaseAngle(origin);
    levels = [_layout(origin, rootItems, base, rootRadius, collapseDist: 0)];
  }

  static const double rootRadius = 84;
  static const double subRadius = 96;
  static const double itemRadius = 26;
  static const double cancelDist = 24;
  static const double selectDist = 40;
  static const Duration dwell = Duration(milliseconds: 200);

  final Rect bounds;

  /// Called whenever the highlighted item changes (for haptics).
  final void Function()? onHighlight;

  late List<MarkingLevel> levels;

  MarkingItem? get highlightedItem {
    final top = levels.last;
    final h = top.highlighted;
    return h == null ? null : top.items[h];
  }

  /// Feeds a pointer position at time [t].
  void pointer(Offset p, Duration t) {
    // Collapse levels the pointer has retreated from.
    while (levels.length > 1) {
      final parent = levels[levels.length - 2];
      if ((p - parent.center).distance < levels.last.collapseDist) {
        levels.removeLast();
      } else {
        break;
      }
    }

    final top = levels.last;
    final rel = p - top.center;
    final dist = rel.distance;
    int? next;
    if (dist >= selectDist) next = _nearest(top, math.atan2(rel.dy, rel.dx));
    if (next != top.highlighted) {
      top.highlighted = next;
      top.highlightedSince = t;
      if (next != null) onHighlight?.call();
    }

    final h = top.highlighted;
    if (h == null) return;
    final item = top.items[h];
    if (!item.hasChildren) return;
    final reached = dist >= top.radius * 0.9;
    final rested = t - top.highlightedSince >= dwell;
    if (reached || rested) _open(top, h, p);
  }

  /// Advances dwell timing without movement.
  void tick(Offset p, Duration t) => pointer(p, t);

  /// The chosen item on release, or null to cancel.
  ///
  /// Releasing in a sub-fan's centre chooses the item that opened it.
  MarkingItem? release(Offset p) {
    final top = levels.last;
    final h = top.highlighted;
    if (h != null) return top.items[h];
    if (levels.length == 1) return null;
    final parent = levels[levels.length - 2];
    final ph = parent.highlighted;
    return ph == null ? null : parent.items[ph];
  }

  // ── layout ─────────────────────────────────────────────────────────────

  void _open(MarkingLevel parent, int index, Offset p) {
    final item = parent.items[index];
    final children = item.children!();
    if (children.isEmpty) return;
    final at = parent.itemPos(index);
    final forward = parent.angles[index];
    final fromParent = (p - parent.center).distance;
    final collapse = math.min(parent.radius - 12, fromParent - 16);
    levels.add(
      _layout(at, children, forward, subRadius, collapseDist: collapse),
    );
  }

  MarkingLevel _layout(
    Offset anchor,
    List<MarkingItem> items,
    double forward,
    double radius, {
    required double collapseDist,
  }) {
    final n = items.length;
    // Glyphs need ~36–43° each; wide text pills push the fan out and apart
    // until their chords stop overlapping.
    final extent = items.map((i) => i.extent).reduce(math.max);
    const maxSpread = 4 * math.pi / 3;
    if (extent > itemRadius * 2) {
      radius = math.max(radius, n * (extent + 10) / maxSpread);
    }
    final perItem = math.max(n <= 3 ? 0.75 : 0.62, (extent + 10) / radius);
    final spread = math.min(maxSpread, n * perItem);
    final sector = spread / n;
    final angles = [
      for (var i = 0; i < n; i++) forward - spread / 2 + sector * (i + 0.5),
    ];
    // Slide the whole fan inward if any item would leave the screen.
    var center = anchor;
    final pad = itemRadius + 8;
    final safe = bounds.deflate(pad);
    var dx = 0.0, dy = 0.0;
    for (final a in angles) {
      final q = anchor + Offset(math.cos(a), math.sin(a)) * radius;
      if (q.dx < safe.left) dx = math.max(dx, safe.left - q.dx);
      if (q.dx > safe.right) dx = math.min(dx, safe.right - q.dx);
      if (q.dy < safe.top) dy = math.max(dy, safe.top - q.dy);
      if (q.dy > safe.bottom) dy = math.min(dy, safe.bottom - q.dy);
    }
    center = center.translate(dx, dy);
    return MarkingLevel(
      center: center,
      anchor: anchor,
      radius: radius,
      items: items,
      angles: angles,
      sector: sector,
      collapseDist: collapseDist,
    );
  }

  /// Opens upward when there is room, otherwise towards the most space, so
  /// the finger never covers the fan.
  double _pickBaseAngle(Offset origin) {
    const reach = rootRadius + subRadius + itemRadius;
    const candidates = [
      -math.pi / 2, // up
      -math.pi / 4, // up-right
      -3 * math.pi / 4, // up-left
      0.0, // right
      math.pi, // left
      math.pi / 2, // down
    ];
    double room(double a) {
      final q = origin + Offset(math.cos(a), math.sin(a)) * reach;
      return math.min(
        math.min(q.dx - bounds.left, bounds.right - q.dx),
        math.min(q.dy - bounds.top, bounds.bottom - q.dy),
      );
    }

    for (final a in candidates) {
      if (room(a) >= 0) return a;
    }
    return candidates.reduce((a, b) => room(a) >= room(b) ? a : b);
  }

  int? _nearest(MarkingLevel level, double angle) {
    int? best;
    var bestDiff = double.infinity;
    for (var i = 0; i < level.angles.length; i++) {
      final d = _angleDiff(angle, level.angles[i]).abs();
      if (d < bestDiff) {
        bestDiff = d;
        best = i;
      }
    }
    final tolerance = math.max(level.sector / 2, 0.45) + 0.35;
    return bestDiff <= tolerance ? best : null;
  }

  static double _angleDiff(double a, double b) {
    var d = (a - b) % (2 * math.pi);
    if (d > math.pi) d -= 2 * math.pi;
    if (d < -math.pi) d += 2 * math.pi;
    return d;
  }
}
