import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A chunky button that sits on a darker ledge and presses down into it.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;

  /// Null greys the button out.
  final VoidCallback? onPressed;
  final Color? color;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final face = enabled
        ? (widget.color ?? scheme.primary)
        : scheme.surfaceContainerHighest;
    final hsl = HSLColor.fromColor(face);
    final ledge = hsl
        .withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0))
        .toColor();
    final ink = !enabled
        ? scheme.onSurfaceVariant
        : ThemeData.estimateBrightnessForColor(face) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    const lift = 5.0;
    final pressed = _down && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          height: 56 + lift,
          child: Stack(
            children: [
              Positioned.fill(
                top: lift,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: enabled ? ledge : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: 0,
                right: 0,
                top: pressed ? lift : 0,
                height: 56,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A speech bubble with a tail on its left, for the mascot beside it. The
/// text types itself out; the layout is fixed from the start so lines don't
/// jump as it does.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final chars = text.characters.toList();
    final style = t.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.3,
    );
    final border = BorderSide(color: scheme.outlineVariant, width: 2);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(border),
          ),
          child: TweenAnimationBuilder<int>(
            key: ValueKey(text),
            tween: IntTween(begin: 0, end: chars.length),
            duration: Duration(
              milliseconds: (chars.length * 22).clamp(250, 1600),
            ),
            builder: (_, n, _) => Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: chars.take(n).join()),
                  TextSpan(
                    text: chars.skip(n).join(),
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ],
              ),
              style: style,
            ),
          ),
        ),
        // The tail, pointing at the mascot.
        Positioned(
          left: -8,
          top: 22,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border(left: border, bottom: border),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The tour's progress: a thick rounded bar with a shine along its top.
class ProgressPill extends StatelessWidget {
  const ProgressPill({super.key, required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (_, v, _) => LayoutBuilder(
        builder: (context, c) => Container(
          height: 16,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: math.max(16, c.maxWidth * v),
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
            alignment: Alignment.topCenter,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confetti that bursts from the top middle each time [fire] changes.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.fire, this.pieces = 70});

  final int fire;
  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  final _random = math.Random();
  List<_Piece> _pieces = const [];

  static const _colors = [
    Color(0xFFFF5FA2),
    Color(0xFFFFC94D),
    Color(0xFF4FC3F7),
    Color(0xFF58CC02),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
  ];

  @override
  void didUpdateWidget(ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (widget.fire != old.fire && widget.fire > 0) {
      _pieces = [
        for (var i = 0; i < widget.pieces; i++)
          _Piece(
            angle: -math.pi / 2 + (_random.nextDouble() - 0.5) * 2.2,
            speed: 0.55 + _random.nextDouble() * 0.75,
            spin: (_random.nextDouble() - 0.5) * 14,
            color: _colors[i % _colors.length],
            round: _random.nextBool(),
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
        painter: _t.isAnimating ? _ConfettiPainter(_pieces, _t.value) : null,
      ),
    ),
  );
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.color,
    required this.round,
  });

  final double angle;
  final double speed;
  final double spin;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.3);
    final scale = size.shortestSide;
    final fade = t < 0.7 ? 1.0 : (1 - t) / 0.3;
    for (final p in pieces) {
      final v = Offset(math.cos(p.angle), math.sin(p.angle)) * p.speed * scale;
      final pos = origin + v * t + Offset(0, 1.1 * scale * t * t);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      if (p.round) {
        canvas.drawCircle(Offset.zero, 4, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 12, height: 6),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
