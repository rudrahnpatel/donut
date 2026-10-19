import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

enum SprinklesMood { happy, cheer, wow }

/// Sprinkles, the tour's donut mascot: pink frosting, sprinkles, a face on
/// the lower half. Bobs gently, blinks now and then, and jumps for joy
/// whenever [cheer] changes.
class Sprinkles extends StatefulWidget {
  const Sprinkles({
    super.key,
    this.size = 120,
    this.mood = SprinklesMood.happy,
    this.cheer = 0,
  });

  final double size;
  final SprinklesMood mood;

  /// Bump to make Sprinkles jump.
  final int cheer;

  @override
  State<Sprinkles> createState() => _SprinklesState();
}

class _SprinklesState extends State<Sprinkles> with TickerProviderStateMixin {
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();
  late final _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );
  final _random = math.Random();
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
    if (widget.cheer > 0) _jump.forward();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 1800 + _random.nextInt(2600)),
      () async {
        if (!mounted) return;
        await _blink.forward(from: 0);
        if (!mounted) return;
        await _blink.reverse();
        _scheduleBlink();
      },
    );
  }

  @override
  void didUpdateWidget(Sprinkles old) {
    super.didUpdateWidget(old);
    if (widget.cheer != old.cheer) _jump.forward(from: 0);
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bob.dispose();
    _jump.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s * 1.2,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bob, _jump, _blink]),
        builder: (context, _) {
          final bob = math.sin(_bob.value * 2 * math.pi) * s * 0.03;
          final j = _jump.value;
          final jumping = _jump.isAnimating;
          // Up and down once, squashing on take-off and landing, with a
          // little wiggle at the top.
          final lift = jumping ? math.sin(j * math.pi) : 0.0;
          final squash = jumping
              ? 1 - 0.12 * math.max(0, math.cos(j * 2 * math.pi))
              : 1.0;
          final wiggle = jumping ? math.sin(j * 4 * math.pi) * 0.14 : 0.0;
          final mood = jumping ? SprinklesMood.cheer : widget.mood;
          return CustomPaint(
            painter: _ShadowPainter(lift: lift),
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, bob - lift * s * 0.3),
                child: Transform.rotate(
                  angle: wiggle,
                  child: Transform.scale(
                    scaleX: 2 - squash,
                    scaleY: squash,
                    alignment: Alignment.bottomCenter,
                    child: CustomPaint(
                      size: Size.square(s),
                      painter: _DonutPainter(mood, blink: _blink.value),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  _ShadowPainter({required this.lift});

  final double lift;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * (0.7 - lift * 0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.9),
        width: w,
        height: w * 0.16,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22 - lift * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.lift != lift;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.mood, {required this.blink});

  final SprinklesMood mood;

  /// 0 = eyes open, 1 = shut.
  final double blink;

  static const _ink = Color(0xFF3B2430);
  static const _sprinkleColors = [
    Color(0xFFFFF176),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFFFFFFF),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.46;

    // Dough, with the hole punched through.
    final dough = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: c, radius: r))
      ..addOval(Rect.fromCircle(center: c, radius: r * 0.27));
    canvas.drawPath(
      dough,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: const [Color(0xFFF8CB91), Color(0xFFD9894B)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r * 0.29,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..color = const Color(0xFFB9692F),
    );

    // Frosting: a wobbly ring.
    Path wobble(double base, double amp, int waves, double phase) {
      final p = Path();
      for (var i = 0; i <= 120; i++) {
        final a = i / 120 * 2 * math.pi;
        final rr =
            base +
            amp * math.sin(waves * a + phase) +
            amp * 0.5 * math.sin((waves * 2 + 1) * a);
        final q = c + Offset(math.cos(a), math.sin(a)) * rr;
        i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
      }
      return p..close();
    }

    final frosting = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(wobble(r * 0.86, r * 0.045, 7, 0.4), Offset.zero)
      ..addPath(wobble(r * 0.37, r * 0.025, 5, 1.1), Offset.zero);
    canvas.drawPath(
      frosting,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          colors: const [Color(0xFFFFA6D2), Color(0xFFFF5FA2)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Gloss.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.68),
      math.pi * 1.08,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.07
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Sprinkles over the top half and the sides, clear of the face.
    for (var i = 0; i < 13; i++) {
      final a = -math.pi - 0.35 + i / 12 * (math.pi + 0.7);
      final rr = r * (i.isEven ? 0.55 : 0.73);
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(i * 1.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 0.16,
            height: r * 0.055,
          ),
          Radius.circular(r * 0.03),
        ),
        Paint()..color = _sprinkleColors[i % _sprinkleColors.length],
      );
      canvas.restore();
    }

    // Face, on the lower half of the frosting.
    final ink = Paint()..color = _ink;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.055;
    for (final side in [-1.0, 1.0]) {
      final eye = c + Offset(side * r * 0.3, r * 0.5);
      // Cheeks.
      canvas.drawOval(
        Rect.fromCenter(
          center: eye + Offset(side * r * 0.17, r * 0.15),
          width: r * 0.17,
          height: r * 0.1,
        ),
        Paint()..color = const Color(0xFFFF2E7E).withValues(alpha: 0.35),
      );
      switch (mood) {
        case SprinklesMood.cheer:
          // ^ ^
          canvas.drawPath(
            Path()
              ..moveTo(eye.dx - r * 0.07, eye.dy + r * 0.03)
              ..lineTo(eye.dx, eye.dy - r * 0.05)
              ..lineTo(eye.dx + r * 0.07, eye.dy + r * 0.03),
            line,
          );
        case SprinklesMood.happy || SprinklesMood.wow:
          final big = mood == SprinklesMood.wow ? 1.25 : 1.0;
          final h = r * 0.15 * big * (1 - blink * 0.9);
          canvas.drawOval(
            Rect.fromCenter(center: eye, width: r * 0.11 * big, height: h),
            ink,
          );
          if (blink < 0.5) {
            canvas.drawCircle(
              eye + Offset(-r * 0.02, -h * 0.22),
              r * 0.022 * big,
              Paint()..color = Colors.white,
            );
          }
      }
    }
    final mouth = c + Offset(0, r * 0.66);
    switch (mood) {
      case SprinklesMood.happy:
        canvas.drawArc(
          Rect.fromCenter(center: mouth, width: r * 0.24, height: r * 0.16),
          0.2,
          math.pi - 0.4,
          false,
          line,
        );
      case SprinklesMood.cheer:
        final open = Path()
          ..moveTo(mouth.dx - r * 0.14, mouth.dy - r * 0.03)
          ..quadraticBezierTo(
            mouth.dx,
            mouth.dy + r * 0.26,
            mouth.dx + r * 0.14,
            mouth.dy - r * 0.03,
          )
          ..close();
        canvas.drawPath(open, ink);
        canvas.drawCircle(
          mouth + Offset(0, r * 0.08),
          r * 0.045,
          Paint()..color = const Color(0xFFFF6F91),
        );
      case SprinklesMood.wow:
        canvas.drawOval(
          Rect.fromCenter(center: mouth, width: r * 0.1, height: r * 0.13),
          ink,
        );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.mood != mood || old.blink != blink;
}
