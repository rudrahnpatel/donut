import 'dart:math' as math;
import 'dart:ui';

import 'package:donut/features/radial_menu/marking_menu_controller.dart';
import 'package:flutter_test/flutter_test.dart';

List<MarkingItem> _emojis() => [
  for (final e in ['😀', '📚', '💪', '🍽️', '😴'])
    MarkingItem(id: 'emoji:$e', glyph: e),
];

List<MarkingItem> _activities() => [
  MarkingItem(
    id: 'activity:study',
    glyph: '📚',
    children: () => const [
      MarkingItem(id: 'todo:ch4', glyph: '•', label: 'Ch. 4 notes'),
      MarkingItem(id: 'todo:pp', glyph: '•', label: 'Past paper'),
    ],
  ),
  const MarkingItem(id: 'activity:gym', glyph: '💪'),
];

List<MarkingItem> _root() => [
  MarkingItem(id: 'group:emoji', glyph: '😀', children: _emojis),
  MarkingItem(id: 'group:tasks', glyph: '✅', children: _activities),
];

void main() {
  const screen = Rect.fromLTWH(0, 0, 400, 800);
  const origin = Offset(200, 500);

  MarkingMenuController make() =>
      MarkingMenuController(origin: origin, rootItems: _root(), bounds: screen);

  test('opens upward when there is room', () {
    final m = make();
    final l = m.levels.single;
    for (var i = 0; i < l.items.length; i++) {
      expect(l.itemPos(i).dy, lessThan(origin.dy));
    }
  });

  test('releasing at the origin cancels', () {
    final m = make();
    m.pointer(origin + const Offset(5, 5), Duration.zero);
    expect(m.release(origin), isNull);
  });

  test('flicking towards an item highlights it by angle, not hit box', () {
    final m = make();
    final l = m.levels.single;
    final dir = Offset(math.cos(l.angles[0]), math.sin(l.angles[0]));
    m.pointer(origin + dir * 50, Duration.zero);
    expect(m.highlightedItem?.id, 'group:emoji');
  });

  test('reaching a group opens its sub-fan centred on it', () {
    final m = make();
    final l = m.levels.single;
    m.pointer(l.itemPos(1), Duration.zero);
    expect(m.levels, hasLength(2));
    expect(m.levels.last.anchor, l.itemPos(1));
  });

  test('resting on a group for the dwell time opens it', () {
    final m = make();
    final l = m.levels.single;
    final dir = Offset(math.cos(l.angles[0]), math.sin(l.angles[0]));
    final p = origin + dir * 50;
    m.pointer(p, Duration.zero);
    expect(m.levels, hasLength(1));
    m.tick(p, const Duration(milliseconds: 250));
    expect(m.levels, hasLength(2));
  });

  test('three-level path: Tasks → Study → to-do', () {
    final m = make();
    var t = Duration.zero;
    void go(Offset p) {
      t += const Duration(milliseconds: 16);
      m.pointer(p, t);
    }

    go(m.levels[0].itemPos(1)); // Tasks
    go(m.levels[1].itemPos(0)); // Study
    expect(m.levels, hasLength(3));
    final todo = m.levels[2].itemPos(1);
    go(todo);
    expect(m.release(todo)?.id, 'todo:pp');
  });

  test('releasing in a sub-fan centre picks its parent item', () {
    final m = make();
    m.pointer(m.levels[0].itemPos(1), Duration.zero);
    final study = m.levels[1].itemPos(0);
    m.pointer(study, const Duration(milliseconds: 16));
    expect(m.release(study)?.id, 'activity:study');
  });

  test('moving back towards the origin collapses the sub-fan', () {
    final m = make();
    m.pointer(m.levels[0].itemPos(0), Duration.zero);
    expect(m.levels, hasLength(2));
    m.pointer(origin + const Offset(0, -10), const Duration(milliseconds: 16));
    expect(m.levels, hasLength(1));
  });

  test('items stay on screen near an edge', () {
    final m = MarkingMenuController(
      origin: const Offset(10, 20),
      rootItems: _root(),
      bounds: screen,
    );
    final l = m.levels.single;
    for (var i = 0; i < l.items.length; i++) {
      final p = l.itemPos(i);
      expect(
        screen.deflate(MarkingMenuController.itemRadius).contains(p),
        isTrue,
        reason: 'item $i at $p',
      );
    }
  });

  group('split root (tasks up, labels down)', () {
    MarkingMenuController split() => MarkingMenuController(
      origin: origin,
      rootItems: [
        MarkingItem(id: 'group:tasks', glyph: '✅', children: _activities),
        MarkingItem(
          id: 'group:label',
          glyph: '✏️',
          children: () => const [
            MarkingItem(id: 'label:a', glyph: '🏷️', label: 'packing'),
            MarkingItem(id: 'label:b', glyph: '🏷️', label: 'cooking'),
          ],
        ),
      ],
      bounds: screen,
      split: true,
    );

    test('first item straight up, second straight down', () {
      final l = split().levels.single;
      expect(l.itemPos(0).dx, closeTo(origin.dx, 0.01));
      expect(l.itemPos(0).dy, lessThan(origin.dy));
      expect(l.itemPos(1).dx, closeTo(origin.dx, 0.01));
      expect(l.itemPos(1).dy, greaterThan(origin.dy));
    });

    test('anywhere in the upper half picks tasks, lower half labels', () {
      for (final (dir, id) in [
        (const Offset(60, -8), 'group:tasks'),
        (const Offset(-60, -8), 'group:tasks'),
        (const Offset(0, -60), 'group:tasks'),
        (const Offset(60, 8), 'group:label'),
        (const Offset(-60, 8), 'group:label'),
        (const Offset(0, 60), 'group:label'),
      ]) {
        final m = split();
        m.pointer(origin + dir, Duration.zero);
        expect(m.highlightedItem?.id, id, reason: '$dir');
      }
    });

    test('the labels fan opens downward', () {
      final m = split();
      m.pointer(origin + const Offset(0, 50), Duration.zero);
      m.pointer(origin + const Offset(0, 90), const Duration(milliseconds: 10));
      expect(m.levels, hasLength(2));
      final sub = m.levels.last;
      for (var i = 0; i < sub.items.length; i++) {
        expect(sub.itemPos(i).dy, greaterThan(origin.dy + 84));
      }
    });
  });

  group('text sub-menus open as a list', () {
    const phone = Rect.fromLTWH(0, 0, 400, 800);
    final labels = [
      for (final l in [
        'home to stn',
        'Sleep',
        'reels',
        'getting fresh',
        'diya and chai nashta',
      ])
        MarkingItem(id: 'label:$l', glyph: '🏷️', label: l, isText: true),
      const MarkingItem(id: 'more:label', glyph: '✏️', label: 'New label…'),
    ];
    MarkingMenuController at(Offset origin) => MarkingMenuController(
      origin: origin,
      rootItems: [
        MarkingItem(id: 'group:tasks', glyph: '✅', children: _activities),
        MarkingItem(id: 'group:label', glyph: '✏️', children: () => labels),
      ],
      bounds: phone,
      split: true,
    );

    MarkingLevel openLabels(MarkingMenuController m, Offset origin) {
      m.pointer(origin + const Offset(0, 50), Duration.zero);
      m.pointer(origin + const Offset(0, 90), const Duration(milliseconds: 16));
      return m.levels.last;
    }

    test('rows stack below the Label item, first row nearest', () {
      const origin = Offset(200, 300);
      final m = at(origin);
      final list = openLabels(m, origin);
      expect(list.isList, isTrue);
      final label = m.levels.first.itemPos(1);
      for (var i = 0; i < labels.length; i++) {
        expect(list.itemPos(i).dx, label.dx, reason: 'centred under it');
        expect(list.itemPos(i).dy, greaterThan(label.dy));
        if (i > 0) {
          expect(list.itemPos(i).dy, greaterThan(list.itemPos(i - 1).dy));
        }
      }
    });

    test('pressed low and to the side, every row stays on screen', () {
      const origin = Offset(380, 600);
      final m = at(origin);
      final list = openLabels(m, origin);
      for (var i = 0; i < labels.length; i++) {
        final r = list.itemPos(i);
        expect(r.dx - list.rowWidth / 2, greaterThanOrEqualTo(phone.left));
        expect(r.dx + list.rowWidth / 2, lessThanOrEqualTo(phone.right));
        expect(r.dy + 18, lessThanOrEqualTo(phone.bottom));
      }
    });

    test('the row level with the finger is picked', () {
      const origin = Offset(200, 300);
      final m = at(origin);
      final list = openLabels(m, origin);
      final third = list.itemPos(3);
      // Anywhere across the row's height and off to the side still counts.
      m.pointer(third + const Offset(60, 8), const Duration(milliseconds: 32));
      expect(m.release(third)?.id, 'label:getting fresh');
    });

    test('a straight flick past the item picks the first row', () {
      const origin = Offset(200, 300);
      final m = at(origin);
      openLabels(m, origin);
      final label = m.levels.first.itemPos(1);
      m.pointer(label + const Offset(0, 30), const Duration(milliseconds: 32));
      expect(m.release(label)?.id, 'label:home to stn');
    });
  });
}
