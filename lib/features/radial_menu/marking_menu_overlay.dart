import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import 'marking_menu_controller.dart';

/// Full-screen layer that draws the marking menu.
///
/// Touch mode: the clock keeps the pointer and forwards moves; this layer
/// only paints. Mouse mode: this layer owns input — hover highlights, any
/// click picks, Esc cancels.
class MarkingMenuLayer extends StatefulWidget {
  const MarkingMenuLayer({
    super.key,
    required this.controller,
    required this.mouseMode,
    required this.onPointer,
    required this.onPick,
    required this.onCancel,
    this.itemColor,
  });

  final MarkingMenuController controller;
  final bool mouseMode;
  final void Function(Offset global) onPointer;
  final void Function(Offset global) onPick;
  final VoidCallback onCancel;

  /// Optional per-item accent (e.g. activity colours).
  final Color? Function(MarkingItem item)? itemColor;

  @override
  State<MarkingMenuLayer> createState() => _MarkingMenuLayerState();
}

class _MarkingMenuLayerState extends State<MarkingMenuLayer> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.mouseMode) _focus.requestFocus();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = widget.controller;
    // Name what a release would pick: the highlighted item, or the parent
    // whose sub-fan the pointer is resting in.
    var label = c.levels.last.isList ? null : c.highlightedItem?.label;
    if (label == null && c.levels.length > 1 && c.highlightedItem == null) {
      final parent = c.levels[c.levels.length - 2];
      final ph = parent.highlighted;
      if (ph != null) label = parent.items[ph].label;
    }

    final stack = Stack(
      children: [
        // The dial steps back while the menu is up, so entries, handles and
        // the hub's text don't compete with the items.
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 0.5),
              duration: const Duration(milliseconds: 160),
              builder: (_, a, _) =>
                  ColoredBox(color: scheme.scrim.withValues(alpha: a)),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _SpokesPainter(c, scheme)),
          ),
        ),
        // Once a sub-menu opens, earlier levels keep only the item it came
        // from (the trail back); the rest step aside until it closes.
        for (var li = 0; li < c.levels.length; li++)
          for (var i = 0; i < c.levels[li].items.length; i++)
            if (li == c.levels.length - 1 || c.levels[li].highlighted == i)
              _item(context, c.levels[li], li, i, scheme),
        if (label != null)
          Positioned(
            left: 0,
            right: 0,
            top: (c.levels.first.anchor.dy - 230).clamp(12.0, double.infinity),
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: ShapeDecoration(
                    color: scheme.inverseSurface,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (!widget.mouseMode) return stack;
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onHover: (e) => widget.onPointer(e.position),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => widget.onPick(e.position),
          child: stack,
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    MarkingLevel level,
    int li,
    int i,
    ColorScheme scheme,
  ) {
    final item = level.items[i];
    final pos = level.itemPos(i);
    final highlighted = level.highlighted == i;
    final isTodo = item.isText;
    final accent = widget.itemColor?.call(item);
    const size = MarkingMenuController.itemRadius * 2;
    if (level.isList) return _row(level, i, pos, highlighted, accent, scheme);

    final Widget face = isTodo
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              item.label ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: highlighted ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          )
        : Text(item.glyph, style: emojiStyle.copyWith(fontSize: 24));

    final bubble = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      height: size,
      constraints: const BoxConstraints(minWidth: size),
      padding: EdgeInsets.symmetric(horizontal: isTodo ? 14 : 0),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: highlighted
            ? (accent ?? scheme.primary)
            : scheme.surfaceContainerHigh,
        shape: StadiumBorder(
          side: BorderSide(
            color: accent ?? scheme.outlineVariant,
            width: highlighted ? 0 : 2,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: highlighted ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: face,
    );

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('${level.anchor}-${item.id}'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 260 + 25 * i),
            curve: Curves.elasticOut,
            builder: (_, t, child) => Transform.scale(scale: t, child: child),
            child: AnimatedScale(
              scale: highlighted ? 1.22 : 1,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: bubble,
            ),
          ),
        ),
      ),
    );
  }

  /// One row of a list level: same width as its siblings, glyph (for
  /// non-text items) and label left-aligned.
  Widget _row(
    MarkingLevel level,
    int i,
    Offset pos,
    bool highlighted,
    Color? accent,
    ColorScheme scheme,
  ) {
    final item = level.items[i];
    final fg = highlighted ? scheme.onPrimary : scheme.onSurface;
    return Positioned(
      left: pos.dx - level.rowWidth / 2,
      top: pos.dy - 18,
      width: level.rowWidth,
      height: 36,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey('${level.anchor}-${item.id}'),
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 160 + 30 * i),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * -8),
              child: child,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: ShapeDecoration(
              color: highlighted ? (accent ?? scheme.primary) : null,
              shape: const StadiumBorder(),
            ),
            child: Row(
              children: [
                if (!item.isText) ...[
                  Text(item.glyph, style: emojiStyle.copyWith(fontSize: 18)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    item.label ?? item.glyph,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpokesPainter extends CustomPainter {
  _SpokesPainter(this.c, this.scheme);

  final MarkingMenuController c;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final spoke = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final level in c.levels) {
      if (level.isList) {
        // A card behind the rows so they read over whatever is below.
        final rows = level.rows!;
        final ys = rows.map((r) => r.dy);
        final card = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            rows.first.dx - level.rowWidth / 2,
            ys.reduce(math.min) - 18,
            rows.first.dx + level.rowWidth / 2,
            ys.reduce(math.max) + 18,
          ).inflate(6),
          const Radius.circular(24),
        );
        canvas.drawShadow(Path()..addRRect(card), Colors.black, 6, false);
        canvas.drawRRect(card, Paint()..color = scheme.surfaceContainerHigh);
        continue;
      }
      if (level.center != level.anchor) {
        canvas.drawLine(level.anchor, level.center, spoke);
      }
      canvas.drawCircle(level.center, 6, Paint()..color = scheme.primary);
      if (level.split && c.levels.length == 1) {
        // The lines between the items' slices of the circle.
        for (final a in level.angles) {
          final b = a + level.sector / 2;
          final d = Offset(math.cos(b), math.sin(b));
          canvas.drawLine(
            level.center + d * 14,
            level.center + d * level.radius * 0.8,
            spoke,
          );
        }
      }
      final top = level == c.levels.last;
      for (var i = 0; i < level.items.length; i++) {
        final p = level.itemPos(i);
        final highlighted = level.highlighted == i;
        if (!top && !highlighted) continue;
        canvas.drawLine(
          level.center,
          Offset.lerp(level.center, p, 0.7)!,
          highlighted
              ? (Paint()
                  ..color = scheme.primary
                  ..strokeWidth = 3
                  ..strokeCap = StrokeCap.round)
              : spoke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SpokesPainter old) => true;
}
