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
    });
    if (newest != null) _clock.receive(newest!);
    return n;
  }
}
