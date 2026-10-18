import 'package:donut/core/time/day_minutes.dart';
import 'package:donut/data/db/app_database.dart';
import 'package:donut/data/repos/block_repo.dart';
import 'package:donut/features/reminders/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = Day(2026, 10, 18).startMin;
  int at(int h, int m) => today + h * 60 + m;
  const travel = ActivityRow(
    id: 'travel',
    name: 'Travel',
    emoji: '🚆',
    color: 0xFF26A69A,
    pinned: false,
    archived: false,
    sortOrder: 0,
    hlc: 'x',
    deleted: false,
  );

  final blocks = [
    PlanBlock(
      id: 'a',
      startMin: at(15, 5),
      durMin: 10,
      note: 'home to stn',
      activityId: 'travel',
    ),
    PlanBlock(id: 'b', startMin: at(15, 15), durMin: 25),
    PlanBlock(
      id: 'c',
      startMin: at(16, 0),
      durMin: 60,
      status: BlockStatus.draft,
    ),
    PlanBlock(id: 'd', startMin: at(14, 0), durMin: 30),
  ];

  test('saved entries after now remind at their start', () {
    final r = planReminders(
      blocks,
      {'travel': travel},
      nowMin: at(14, 50),
      leadMin: 0,
    );
    expect(r.map((x) => x.atMin), [at(15, 5), at(15, 15)]);
    expect(r.first.title, '🚆 home to stn');
    expect(r.first.body, '3:05 PM – 3:15 PM');
    expect(r[1].title, 'Up next');
  });

  test('plan-mode sketches and past entries never remind', () {
    final r = planReminders(blocks, const {}, nowMin: at(14, 50), leadMin: 0);
    expect(r.any((x) => x.atMin == at(16, 0)), isFalse);
    expect(r.any((x) => x.atMin == at(14, 0)), isFalse);
  });

  test('a lead time moves the reminder earlier and says so', () {
    final r = planReminders(blocks, const {}, nowMin: at(14, 50), leadMin: 10);
    expect(r.first.atMin, at(14, 55));
    expect(r.first.body, endsWith('· in 10 min'));
  });

  test('ids are stable per entry', () {
    final a = planReminders(blocks, const {}, nowMin: at(14, 0), leadMin: 0);
    final b = planReminders(blocks, const {}, nowMin: at(14, 0), leadMin: 5);
    expect(a.first.id, b.first.id);
  });
}
