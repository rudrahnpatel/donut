import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The hub's analog clock: hour, minute and second hands showing the time
/// now, sized from the dial's [radius] so they sit inside its numerals.
/// Ticks once a second; only this layer repaints.
class AnalogHands extends StatefulWidget {
  const AnalogHands({super.key, required this.radius});

  final double radius;

  @override
  State<AnalogHands> createState() => _AnalogHandsState();
}

class _AnalogHandsState extends State<AnalogHands> {
  DateTime _now = DateTime.now();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  /// On the next whole second, so the hand steps with the system clock.
  void _schedule() {
    final now = DateTime.now();
    _tick = Timer(Duration(milliseconds: 1000 - now.millisecond), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _schedule();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _HandsPainter(
        _now,
        widget.radius,
        Theme.of(context).colorScheme,
      ),
    ),
  );
}

class _HandsPainter extends CustomPainter {
  _HandsPainter(this.now, this.r, this.scheme);

  final DateTime now;
  final double r;
  final ColorScheme scheme;

  static const red = Color(0xFFE5484D);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = now.second;
    final m = now.minute + s / 60;
    final h = now.hour % 12 + m / 60;
    Offset at(double turns, double len) {
      final a = turns * 2 * math.pi;
      return c + Offset(math.sin(a), -math.cos(a)) * len;
    }

    void hand(double turns, double len, double tail, double width, Color ink) {
      final from = at(turns, -tail), to = at(turns, len);
      // A soft shadow lifts the hands off the dial.
      canvas.drawLine(
        from + const Offset(0, 1.5),
        to + const Offset(0, 1.5),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = ink
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    final ink = scheme.onSurface;
    hand(h / 12, r * 0.19, r * 0.03, math.max(4, r * 0.026), ink);
    hand(m / 60, r * 0.29, r * 0.03, math.max(3, r * 0.016), ink);
    hand(s / 60, r * 0.32, r * 0.07, 1.6, red);
    canvas.drawCircle(c, math.max(4, r * 0.022), Paint()..color = ink);
    canvas.drawCircle(c, math.max(2, r * 0.01), Paint()..color = red);
  }

  @override
  bool shouldRepaint(_HandsPainter old) =>
      old.now != now || old.r != r || old.scheme != scheme;
}
