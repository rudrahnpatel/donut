import 'package:drift/drift.dart';

import '../../core/time/hlc.dart';
import '../../data/db/app_database.dart';
import 'merge.dart';

/// Reads the synced tables as a [Snapshot] and writes merged rows back.
class SyncStore {
  SyncStore(this._db, this._clock);

  final AppDatabase _db;
  final HlcClock _clock;

  Future<Snapshot> snapshot(String device) async => Snapshot(device, {
    'blocks': {
      for (final r in await _db.select(_db.blocks).get()) r.id: r.toJson(),
    },
    'activities': {
      for (final r in await _db.select(_db.activities).get()) r.id: r.toJson(),
    },
    'todos': {
      for (final r in await _db.select(_db.todos).get()) r.id: r.toJson(),
    },
    'templates': {
      for (final r in await _db.select(_db.templates).get()) r.id: r.toJson(),
    },
    'series': {
      for (final r in await _db.select(_db.series).get()) r.id: r.toJson(),
    },
    'settings': {
      for (final r in await _db.select(_db.settings).get())
        if (!deviceSettings.contains(r.key)) r.key: r.toJson(),
    },
  });

  /// Writes [rows] (from [rowsToApply]) and moves the local clock past
  /// them. Returns how many rows changed.
  Future<int> apply(Map<String, List<Row>> rows) async {
    var n = 0;
    String? newest;
    await _db.transaction(() async {
      for (final MapEntry(key: table, value: list) in rows.entries) {
        for (final json in list) {
          switch (table) {
            case 'blocks':
              await _db
                  .into(_db.blocks)
                  .insertOnConflictUpdate(BlockRow.fromJson(json));
            case 'activities':
              await _db
                  .into(_db.activities)
                  .insertOnConflictUpdate(ActivityRow.fromJson(json));
            case 'todos':
              await _db
                  .into(_db.todos)
                  .insertOnConflictUpdate(TodoRow.fromJson(json));
            case 'templates':
              await _db
                  .into(_db.templates)
                  .insertOnConflictUpdate(TemplateRow.fromJson(json));
            case 'series':
              await _db
                  .into(_db.series)
                  .insertOnConflictUpdate(SeriesRow.fromJson(json));
            case 'settings':
              await _db
                  .into(_db.settings)
                  .insertOnConflictUpdate(SettingRow.fromJson(json));
          }
          n++;
          final h = json['hlc'] as String?;
          if (h != null && (newest == null || h.compareTo(newest!) > 0)) {
            newest = h;
          }
        }
      }
      // Before stamping anything below, so local writes win over what came in.
      if (newest != null) _clock.receive(newest!);
      if (rows.containsKey('activities')) await mergeDuplicateActivities();
    });
    return n;
  }

  /// Two devices that each set up "Study" (the starter tasks, or the same
  /// task made on both) have two after syncing. Keeps one per name: the
  /// smallest id, so every device keeps the same one, with the fields of the
  /// most recently edited copy. Everything pointing at the others moves to
  /// it, and the others are deleted. Returns how many were merged away.
  Future<int> mergeDuplicateActivities() async {
    final live = await (_db.select(
      _db.activities,
    )..where((t) => t.deleted.equals(false))).get();
    final byName = <String, List<ActivityRow>>{};
    for (final a in live) {
      byName.putIfAbsent(a.name.trim().toLowerCase(), () => []).add(a);
    }
    var n = 0;
    for (final group in byName.values.where((g) => g.length > 1)) {
      group.sort((a, b) => a.id.compareTo(b.id));
      final keep = group.first;
      final newest = group.reduce(
        (a, b) => a.hlc.compareTo(b.hlc) >= 0 ? a : b,
      );
      final pinned = group.any((a) => a.pinned);
      if (newest.id != keep.id || pinned != keep.pinned) {
        await _db
            .update(_db.activities)
            .replace(
              newest.copyWith(id: keep.id, pinned: pinned, hlc: _clock.now()),
            );
      }
      for (final dup in group.skip(1)) {
        await _repointActivity(dup.id, keep.id);
        await (_db.update(
          _db.activities,
        )..where((t) => t.id.equals(dup.id))).write(
          ActivitiesCompanion(
            deleted: const Value(true),
            hlc: Value(_clock.now()),
          ),
        );
        n++;
      }
    }
    return n;
  }

  Future<void> _repointActivity(String from, String to) async {
    await (_db.update(
      _db.blocks,
    )..where((t) => t.activityId.equals(from))).write(
      BlocksCompanion(activityId: Value(to), hlc: Value(_clock.now())),
    );
    await (_db.update(_db.todos)..where((t) => t.activityId.equals(from)))
        .write(TodosCompanion(activityId: Value(to), hlc: Value(_clock.now())));
    await (_db.update(
      _db.series,
    )..where((t) => t.activityId.equals(from))).write(
      SeriesCompanion(activityId: Value(to), hlc: Value(_clock.now())),
    );
    // Sketches are local; they just follow along.
    await (_db.update(_db.blockEdits)..where((t) => t.activityId.equals(from)))
        .write(BlockEditsCompanion(activityId: Value(to)));
    // Templates keep ids inside their JSON; ids are UUIDs, so a plain
    // replace can't hit anything else.
    final templates = await (_db.select(
      _db.templates,
    )..where((t) => t.blocksJson.contains(from))).get();
    for (final t in templates) {
      await (_db.update(_db.templates)..where((x) => x.id.equals(t.id))).write(
        TemplatesCompanion(
          blocksJson: Value(t.blocksJson.replaceAll(from, to)),
          hlc: Value(_clock.now()),
        ),
      );
    }
  }
}
