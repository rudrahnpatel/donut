import 'package:donut/core/time/hlc.dart';
import 'package:donut/data/db/app_database.dart';
import 'package:donut/data/repos/pin_repo.dart';
import 'package:donut/features/sync/sync_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PinRepo repo;
  late HlcClock clock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = HlcClock('test');
    repo = PinRepo(db, clock);
  });
  tearDown(() => db.close());

  Future<List<PinRow>> all() => repo.watchRange(0, 1 << 40).first;

  test('pins read as "<verb> <time>", custom ones by their text', () async {
    await repo.create(16 * 60 + 55, PinKind.reachBy, draft: false);
    await repo.create(
      17 * 60,
      PinKind.custom,
      label: 'train leaves',
      draft: false,
    );
    final [reach, custom] = await all();
    expect(reach.describe(), 'Reach by 4:55 PM');
    expect(custom.describe(), 'train leaves · 5:00 PM');
    expect(custom.pinKind.glyph, '📌');
  });

  test(
    '✓ keeps sketched pins, ✕ drops them and Undo brings them back',
    () async {
      await repo.create(600, PinKind.meetingAt, draft: true);
      await repo.create(700, PinKind.leaveBy, draft: false);
      expect(await repo.watchDraftCount().first, 1);

      final gone = await repo.discardDrafts();
      expect(gone, hasLength(1));
      expect((await all()).map((p) => p.atMin), [700]);

      await repo.restore(gone);
      expect((await all()).map((p) => p.atMin), [600, 700]);
      expect(await repo.watchDraftCount().first, 1);

      expect(await repo.commitDrafts(), 1);
      expect(await repo.watchDraftCount().first, 0);
    },
  );

  test('deleting a saved pin leaves a tombstone that syncs', () async {
    final id = await repo.create(600, PinKind.reachBy, draft: false);
    final row = await repo.delete(id);
    expect(row?.deleted, isFalse, reason: 'returns the pin as it was');
    expect(await all(), isEmpty);
    final snap = await SyncStore(db, clock).snapshot('me');
    expect(snap.tables['pins']![id]!['deleted'], isTrue);
  });

  test('sketched pins stay on the device until ✓', () async {
    final sketch = await repo.create(600, PinKind.reachBy, draft: true);
    final kept = await repo.create(700, PinKind.reachBy, draft: false);
    final snap = await SyncStore(db, clock).snapshot('me');
    expect(snap.tables['pins']!.keys, [kept]);
    expect(snap.tables['pins']!.containsKey(sketch), isFalse);
  });

  test('recent custom texts, newest first, no repeats', () async {
    for (final t in ['a', 'b', 'a', 'c', 'd']) {
      await repo.create(600, PinKind.custom, label: t, draft: false);
    }
    await repo.create(600, PinKind.reachBy, draft: false);
    expect(await repo.watchRecentCustom().first, ['d', 'c', 'a']);
  });
}
