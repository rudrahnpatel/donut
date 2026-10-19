import 'package:donut/features/clock/overlap_layout.dart';
import 'package:flutter_test/flutter_test.dart';

String d(LanePiece x) =>
    '${x.id}:${x.start}-${x.end}:${x.index}+${x.span}/${x.count}';

void main() {
  test('a lone block uses the full width', () {
    final p = splitOverlaps(const [ClockSpan('a', 0, 60)]);
    expect(p.map(d), ['a:0-60:0+1/1']);
  });

  test('blocks split only where they overlap', () {
    final p = splitOverlaps(const [
      ClockSpan('a', 0, 60),
      ClockSpan('b', 30, 90),
    ]);
    expect(p.map(d), [
      'a:0-30:0+1/1',
      'a:30-60:0+1/2',
      'b:30-60:1+1/2',
      'b:60-90:0+1/1',
    ]);
  });

  test('while sharing, a block keeps one column: no zig-zag', () {
    // A long entry with shorter ones coming and going.
    final p = splitOverlaps(const [
      ClockSpan('long', 0, 60),
      ClockSpan('b', 10, 30),
      ClockSpan('c', 40, 50),
    ]);
    expect(p.map(d), [
      'long:0-10:0+1/1',
      'long:10-30:0+1/2',
      'long:30-40:0+1/1',
      'long:40-50:0+1/2',
      'long:50-60:0+1/1',
      'b:10-30:1+1/2',
      'c:40-50:1+1/2',
    ]);
  });

  test('a block overlapped all along is one even band', () {
    // Red and purple in the screenshot: always beside others.
    final p = splitOverlaps(const [
      ClockSpan('blue', 30, 58),
      ClockSpan('purple', 30, 45),
      ClockSpan('red', 33, 54),
      ClockSpan('orange', 38, 45),
    ]);
    // Blue runs on alone at the end (full width there); the others are
    // beside it all along.
    for (final id in ['purple', 'red', 'orange']) {
      final mine = p.where((x) => x.id == id);
      expect(
        mine.map((x) => (x.index, x.span, x.count)).toSet(),
        hasLength(1),
        reason: '$id keeps one place',
      );
    }
  });

  test('a block widens into columns free for its whole length', () {
    final p = splitOverlaps(const [
      ClockSpan('a', 0, 60),
      ClockSpan('b', 0, 20),
      ClockSpan('c', 10, 20),
      ClockSpan('d', 30, 50),
    ]);
    expect(p.map(d), [
      'a:0-20:0+1/3',
      'a:20-30:0+1/1',
      'a:30-50:0+1/3',
      'a:50-60:0+1/1',
      'b:0-20:1+1/3',
      'c:10-20:2+1/3',
      'd:30-50:1+2/3',
    ]);
  });

  test('touching blocks do not overlap', () {
    final p = splitOverlaps(const [
      ClockSpan('a', 0, 30),
      ClockSpan('b', 30, 60),
    ]);
    expect(p.every((x) => x.count == 1), isTrue);
  });

  test('hit-testing picks the block drawn under the finger', () {
    final p = splitOverlaps(const [
      ClockSpan('a', 0, 60),
      ClockSpan('b', 30, 90),
      ClockSpan('w', 100, 160),
      ClockSpan('x', 100, 110),
      ClockSpan('y', 100, 105),
      ClockSpan('z', 120, 150),
    ]);
    expect(pieceAt(p, 45, 0.25)?.id, 'a');
    expect(pieceAt(p, 45, 0.75)?.id, 'b');
    expect(pieceAt(p, 10, 0.9)?.id, 'a', reason: 'alone: full width');
    expect(pieceAt(p, 95, 0.5), isNull);
    // "z" widened over two of three columns.
    expect(pieceAt(p, 130, 0.5)?.id, 'z');
    expect(pieceAt(p, 130, 0.9)?.id, 'z');
  });
}
