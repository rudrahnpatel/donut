import 'dart:convert';

import 'package:donut/core/time/day_minutes.dart';
import 'package:donut/data/repos/block_repo.dart';
import 'package:donut/features/widget_bridge/widget_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('entries are clipped to each day, keyed by epoch day', () {
    final today = Day(2026, 10, 18);
    final tomorrow = today.addDays(1);
    final blocks = [
      PlanBlock(
        id: 'a',
        startMin: today.startMin + 9 * 60,
        durMin: 60,
        color: 0xFF3E8ED0,
      ),
      // Sleep across midnight shows on both days.
      PlanBlock(
        id: 'sleep',
        startMin: today.startMin + 23 * 60,
        durMin: 8 * 60,
        color: 0xFF5C6B8A,
      ),
    ];
    final json = jsonDecode(
      encodeWidgetDays(blocks, [today, tomorrow], (_) => null),
    ) as Map<String, dynamic>;
    final t = (json['${today.epochDay}'] as List).cast<List>();
    final n = (json['${tomorrow.epochDay}'] as List).cast<List>();
    expect(
      [for (final e in t) e.sublist(0, 2)],
      [
        [540, 600],
        [1380, 1440],
      ],
    );
    expect(
      [for (final e in n) e.sublist(0, 2)],
      [
        [0, 420],
      ],
    );
    expect(t.first[2], isA<int>());
  });
}
