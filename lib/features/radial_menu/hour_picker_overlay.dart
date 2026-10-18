import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/time/day_minutes.dart';
import 'hour_picker_controller.dart';

/// Full-screen layer that draws the hour picker around the dial's hub.
///
/// Touch mode: the dial keeps the pointer and forwards moves; this layer
/// only paints. Mouse mode: hover highlights, any click picks, Esc cancels.
class HourPickerLayer extends StatefulWidget {
  const HourPickerLayer({
    super.key,
    required this.controller,
    required this.mouseMode,
    required this.labelFor,
    required this.onPointer,
    required this.onPick,
    required this.onCancel,
  });

  final HourPickerController controller;
  final bool mouseMode;

  /// Human label for an hour's absolute start minute, e.g. "4 PM · today".
  final String Function(int absStart) labelFor;
  final void Function(Offset global) onPointer;
  final void Function(Offset global) onPick;
  final VoidCallback onCancel;

  @override
  State<HourPickerLayer> createState() => _HourPickerLayerState();
}

class _HourPickerLayerState extends State<HourPickerLayer> {
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
    final picked = c.picked;
    final discR = c.outerRadius + 34;

    final children = <Widget>[
      Positioned.fill(
        child: IgnorePointer(
          child: ColoredBox(color: scheme.scrim.withValues(alpha: 0.18)),
        ),
      ),
      Positioned(
        left: c.center.dx - discR,
        top: c.center.dy - discR,
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.scale(scale: t, child: child),
            child: Container(
              width: discR * 2,
              height: discR * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHigh,
                boxShadow: const [
                  BoxShadow(blurRadius: 24, color: Color(0x40000000)),
                ],
              ),
            ),
          ),
        ),
      ),
    ];

    for (var ring = 0; ring < 2; ring++) {
      final r = ring == 0 ? c.innerRadius : c.outerRadius;
      for (var pos = 0; pos < 12; pos++) {
        final a = pos / 12 * 2 * math.pi;
        final p = c.center + Offset(math.sin(a), -math.cos(a)) * r;
        final start = c.startFor(ring, pos);
        final hour = minuteOfDay(start) ~/ 60;
        final selected = c.ring == ring && c.position == pos;
        children.add(
          Positioned(
            left: p.dx,
            top: p.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutBack,
                  width: selected ? 46 : 36,
                  height: selected ? 46 : 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? scheme.primary : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${hour % 12 == 0 ? 12 : hour % 12}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: ring == 0 ? 17 : 14,
                          height: 1,
                          color: selected
                              ? scheme.onPrimary
                              : (ring == 0
                                    ? scheme.onSurface
                                    : scheme.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        hour < 12 ? 'am' : 'pm',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          height: 1.1,
                          color: selected ? scheme.onPrimary : scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    children.add(
      Positioned(
        left: 0,
        right: 0,
        top: (c.center.dy - discR - 52).clamp(12.0, double.infinity),
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: ShapeDecoration(
                color: scheme.inverseSurface,
                shape: const StadiumBorder(),
              ),
              child: Text(
                picked == null ? 'Slide to an hour' : widget.labelFor(picked),
                style: TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final stack = Stack(children: children);
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
}
