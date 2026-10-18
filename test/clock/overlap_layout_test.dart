import 'package:donut/features/clock/overlap_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a lone block uses the full width', () {
    final p = splitOverlaps(const [ClockSpan('a', 0, 60)]);
    expect(p.single.count, 1);
    expect((p.single.start, p.single.end), (0, 60));
  });

  test('two overlapping blocks split only where they overlap', () {
    final p = splitOverlaps(const [
      ClockSpan('a', 0, 60),
      ClockSpan('b', 30, 90),
    ]);
    String d(LanePiece x) =>
        '${x.id}:${x.start}-${x.end}:${x.index}/${x.count}';
    expect(p.map(d), [
      'a:0-30:0/1',
      'a:30-60:0/2',
      'b:30-60:1/2',
      'b:60-90:0/1',
    ]);
  });

  test('touching blocks do not overlap', () {
    final p = splitOverlaps(const [
      ClockSpan('a', 0, 30),
      ClockSpan('b', 30, 60),
    ]);
    expect(p.every((x) => x.count == 1), isTrue);
  });

  test('hit-testing an overlap picks the block in that half', () {
    final p = splitOverlaps(const [
      ClockSpan('a', 0, 60),
      ClockSpan('b', 30, 90),
    ]);
    expect(pieceAt(p, 45, 0.25)?.id, 'a');
    expect(pieceAt(p, 45, 0.75)?.id, 'b');
    expect(pieceAt(p, 10, 0.9)?.id, 'a');
    expect(pieceAt(p, 95, 0.5), isNull);
  });
}
