import 'package:donut/core/time/hlc.dart';
import 'package:donut/data/db/app_database.dart';
import 'package:donut/features/sync/sync_store.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HlcClock clock;
  late SyncStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = HlcClock('test');
    store = SyncStore(db, clock);
  });
  tearDown(() => db.close());

  Future<void> activity(String id, String name, String hlc, {int color = 1}) =>
      db
          .into(db.activities)
          .insert(
            ActivitiesCompanion.insert(
              id: id,
              name: name,
              emoji: '📚',
              color: color,
              hlc: hlc,
            ),
          );

  Future<List<ActivityRow>> live() =>
      (db.select(db.activities)..where((t) => t.deleted.equals(false))).get();

  test(
    'each device\'s starter "Study" becomes one, references follow',
    () async {
      await activity('aaa', 'Study', '000000000000000-00000-seed');
      await activity('bbb', 'Study', '000000000000000-00000-seed');
      await activity('ccc', 'Gym', '000000000000000-00000-seed');
      await db
          .into(db.blocks)
          .insert(
            BlocksCompanion.insert(
              id: 'b1',
              startMin: 0,
              durMin: 30,
              activityId: const Value('bbb'),
              hlc: clock.now(),
            ),
          );
      await db
          .into(db.todos)
          .insert(
            TodosCompanion.insert(
              id: 't1',
              title: 'ch. 4',
              activityId: const Value('bbb'),
              createdAt: 0,
              hlc: clock.now(),
            ),
          );
      await db
          .into(db.templates)
          .insert(
            TemplatesCompanion.insert(
              id: 'tp',
              name: 'Weekday',
              blocksJson: '[{"s":0,"d":30,"a":"bbb"}]',
              hlc: clock.now(),
            ),
          );

      final before = clock.now();
      expect(await store.mergeDuplicateActivities(), 1);

      expect((await live()).map((a) => a.id), unorderedEquals(['aaa', 'ccc']));
      final block = await (db.select(
        db.blocks,
      )..where((t) => t.id.equals('b1'))).getSingle();
      expect(block.activityId, 'aaa');
      final todo = await (db.select(
        db.todos,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(todo.activityId, 'aaa');
      final template = await (db.select(
        db.templates,
      )..where((t) => t.id.equals('tp'))).getSingle();
      expect(template.blocksJson, contains('"a":"aaa"'));
      // Moved rows get new stamps, so the move syncs to other devices.
      expect(block.hlc.compareTo(before), greaterThan(0));
    },
  );

  test('an edited copy\'s fields survive under the kept id', () async {
    await activity('aaa', 'Study', '000000000000000-00000-seed', color: 1);
    await activity('bbb', 'study', clock.now(), color: 0xFF00FF00);

    await store.mergeDuplicateActivities();

    final [kept] = await live();
    expect(kept.id, 'aaa');
    expect(kept.color, 0xFF00FF00);
    expect(kept.name, 'study');
  });

  test('nothing to merge is a no-op', () async {
    await activity('aaa', 'Study', clock.now());
    await activity('bbb', 'Gym', clock.now());
    expect(await store.mergeDuplicateActivities(), 0);
    expect(await live(), hasLength(2));
  });
}
