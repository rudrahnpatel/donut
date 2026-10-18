import 'dart:io';
import 'dart:ui' as ui;

import 'package:donut/features/clock/clock_painter.dart';
import 'package:donut/features/clock/spiral_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // Dev aid: renders the painter to $OUT for a visual check.
  test(
    'render clock painter to png',
    skip: Platform.environment['OUT'] == null,
    () async {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF3E8ED0),
        brightness: Brightness.dark,
      );
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 600, 600),
        Paint()..color = Colors.black,
      );
      ClockPainter(
        spec: const DialSpec.hour(15 * 60),
        captions: ('', '4 PM'),
        blocks: const [
          PaintBlock(
            id: 'ready',
            start: 895,
            end: 905,
            color: Color(0xFFC27FD2),
          ),
          PaintBlock(id: 'stn', start: 905, end: 915, color: Color(0xFFE56E95)),
          PaintBlock(
            id: 'late',
            start: 1010,
            end: 1030,
            color: Color(0xFF7FCFA8),
          ),
        ],
        scheme: scheme,
      ).paint(canvas, const Size(600, 600));
      final img = await rec.endRecording().toImage(600, 600);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File(Platform.environment['OUT']!)
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    },
  );
}
