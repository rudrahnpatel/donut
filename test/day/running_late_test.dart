import 'package:donut/data/db/app_database.dart';
import 'package:donut/features/day/running_late.dart';
import 'package:flutter_test/flutter_test.dart';

int at(int h, int m) => h * 60 + m;

({String id, int start, int end}) e(String id, int s, int en) =>
    (id: id, start: s, end: en);

PinRow pin(String id, int atMin, String kind) => PinRow(
  id: id,
  atMin: atMin,
  kind: kind,
  draft: false,
  hlc: 'x',
  deleted: false,
);

void main() {
  // The travel chain, with dinner much later.
  final day = [
    e('ready', at(16, 5), at(16, 10)),
    e('home', at(16, 10), at(16, 15)),
    e('train', at(16, 15), at(16, 55)),
    e('dinner', at(19, 0), at(20, 0)),
  ];

  test('late while getting ready: the chain moves, dinner stays', () {
    final s = shiftForLate(day, now: at(16, 7), delay: 10);
    expect(s.map((x) => (x.id, x.newStart, x.newEnd)), [
      ('ready', at(16, 5), at(16, 20)),
      ('home', at(16, 20), at(16, 25)),
      ('train', at(16, 25), at(17, 5)),
    ]);
  });

  test('a gap absorbs what it can', () {
    final s = shiftForLate(
      [
        e('a', at(10, 0), at(11, 0)),
        e('b', at(11, 5), at(12, 0)),
        e('c', at(12, 30), at(13, 0)),
      ],
      now: at(10, 30),
      delay: 10,
    );
    expect(s.map((x) => (x.id, x.newStart, x.newEnd)), [
      ('a', at(10, 0), at(11, 10)),
      ('b', at(11, 10), at(12, 5)),
    ]);
  });

  test('between entries: the next one starts when you will be ready', () {
    final s = shiftForLate(
      [e('next', at(16, 3), at(16, 30))],
      now: at(16, 0),
      delay: 10,
    );
    expect(s.single.newStart, at(16, 10));
    expect(
      shiftForLate(
        [e('later', at(19, 0), at(20, 0))],
        now: at(16, 0),
        delay: 10,
      ),
      isEmpty,
    );
  });

  test('"everything" moves the whole rest of the day', () {
    final s = shiftForLate(day, now: at(16, 7), delay: 10, everything: true);
    expect(s.last.id, 'dinner');
    expect(s.last.newStart, at(19, 10));
  });

  test('pins never move; crossing one is reported', () {
    final s = shiftForLate(day, now: at(16, 7), delay: 10);
    final missed = missedPins(s, [
      pin('reach', at(16, 55), 'reachBy'),
      pin('leave', at(16, 10), 'leaveBy'),
      pin('dinner', at(19, 0), 'meetingAt'),
    ]);
    expect(
      missed.map((m) => (m.$1.id, m.$2.id, m.$3)),
      containsAll([('train', 'reach', false), ('home', 'leave', true)]),
    );
    expect(missed.any((m) => m.$2.id == 'dinner'), isFalse);
  });
}
