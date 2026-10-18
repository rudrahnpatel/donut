import 'dart:io';
import 'dart:ui' as ui;

import 'package:donut/features/clock/clock_painter.dart';
import 'package:donut/features/clock/spiral_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // Dev aid: renders three frames of the 4 PM → 5 PM glide to $OUT.
  test(
    'render hour-change animation frames',
    skip: Platform.environment['OUT'] == null,
    () async {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF3E8ED0),
        brightness: Brightness.dark,
      );
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1200, 400),
        Paint()..color = Colors.black,
      );
      for (final (i, offset) in [1.0, 0.5, 0.0].indexed) {
        canvas.save();
        canvas.translate(i * 400.0, 0);
        ClockPainter(
          spec: const DialSpec.hour(17 * 60),
          captions: ('', '6 PM'),
          blocks: const [
            PaintBlock(
              id: 'pack',
              start: 960,
              end: 1020,
              color: Color(0xFF7FCFA8),
            ),
            PaintBlock(
              id: 'cook',
              start: 1020,
              end: 1080,
              color: Color(0xFFADD47E),
            ),
            PaintBlock(
              id: 'tv',
              start: 1095,
              end: 1110,
              color: Color(0xFFE2AE6B),
            ),
          ],
          scheme: scheme,
          lapOffset: offset,
        ).paint(canvas, const Size(400, 400));
        canvas.restore();
      }
      final img = await rec.endRecording().toImage(1200, 400);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File(Platform.environment['OUT']!)
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    },
  );
}
