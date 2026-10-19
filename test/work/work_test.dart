import 'package:donut/core/time/day_minutes.dart';
import 'package:donut/core/time/hlc.dart';
import 'package:donut/data/db/app_database.dart';
import 'package:donut/data/repos/work_repo.dart';
import 'package:donut/features/work/work_import.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = Day.today();
  int ms(int h, int m) => day
      .toLocalDateTime()
      .add(Duration(hours: h, minutes: m))
      .millisecondsSinceEpoch;

  test('log moments join into sessions; a long gap starts a new one', () {
    final byDay = sessionsFromEvents([
      (ms(10, 0), 'timemng'),
      (ms(10, 4), 'timemng'),
      (ms(10, 9), 'neubitat'),
      (ms(10, 12), 'neubitat'),
      (ms(14, 0), 'timemng'), // after a long break
    ]);
    final sessions = byDay[day.epochDay]!;
    expect(sessions, hasLength(2));
    expect(sessions[0].start, ms(10, 0));
    expect(sessions[0].end, ms(10, 12));
    expect(sessions[0].projects, {'timemng': 9 * 60, 'neubitat': 3 * 60});
    // A lone message is a minute's work.
    expect(sessions[1].end - sessions[1].start, 60000);
  });

  group('importing a day', () {
    late AppDatabase db;
    late WorkRepo repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = WorkRepo(db, HlcClock('test'));
    });
    tearDown(() => db.close());

    Future<List<WorkSessionRow>> live() =>
        repo.watchRange(day.startMin, day.endMin).first;

    test('sessions grow in place and overlaps count once', () async {
      await repo.importDay(day, [
        TrackedSession(
          start: ms(10, 0),
          end: ms(10, 30),
          projects: {'a': 1800},
        ),
      ], source: 'tracker');
      await repo.importDay(day, [
        TrackedSession(start: ms(10, 0), end: ms(11, 0), projects: {'a': 3600}),
        TrackedSession(
          start: ms(10, 45),
          end: ms(11, 15),
          projects: {'b': 1800},
        ),
      ], source: 'tracker');
      final rows = await live();
      expect(rows, hasLength(2));
      expect(rows.first.endMin - rows.first.startMin, 60);
      expect(workedMinutes(rows, day.startMin, day.endMin), 75);
    });

    test(
      'dropped in the tracker → gone; excluded in Donut → stays out',
      () async {
        final keep = TrackedSession(start: ms(9, 0), end: ms(9, 30));
        final drop = TrackedSession(start: ms(12, 0), end: ms(12, 30));
        final personal = TrackedSession(start: ms(15, 0), end: ms(16, 0));
        await repo.importDay(day, [keep, drop, personal], source: 'tracker');
        await repo.exclude('tracker-${personal.start}');
        // Next import: "drop" was removed in the tracker, "personal" is still
        // listed there.
        await repo.importDay(day, [keep, personal], source: 'tracker');
        final rows = await live();
        expect(rows.map((r) => r.id), ['tracker-${keep.start}']);
      },
    );
  });
}
