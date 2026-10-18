/// Last-writer-wins merging of synced records.
///
/// Every synced row carries an `hlc` (see `core/time/hlc.dart`); deletions
/// are rows with `deleted: true`, so they merge like any other change.
/// Merging is per row: the copy with the greater HLC wins. Because that rule
/// is commutative, associative and idempotent, devices that exchange
/// snapshots in any order end up with the same data.
library;

/// The tables that sync, with the field that identifies a row in each.
const syncedTables = <String, String>{
  'blocks': 'id',
  'activities': 'id',
  'todos': 'id',
  'templates': 'id',
  'series': 'id',
  'settings': 'key',
};

typedef Row = Map<String, dynamic>;

/// All synced rows of one device, as JSON, keyed by table then row id.
class Snapshot {
  Snapshot(this.device, this.tables);

  factory Snapshot.fromJson(Map<String, dynamic> json) =>
      Snapshot(json['device'] as String, {
        for (final t in syncedTables.keys)
          t: {
            for (final r
                in (json[t] as List? ?? const []).cast<Map<String, dynamic>>())
              '${r[syncedTables[t]]}': r,
          },
      });

  final String device;
  final Map<String, Map<String, Row>> tables;

  Map<String, dynamic> toJson() => {
    'v': 1,
    'device': device,
    for (final t in syncedTables.keys)
      t: tables[t]?.values.toList() ?? const [],
  };

  /// The newest HLC anywhere in this snapshot.
  String? get newestHlc {
    String? best;
    for (final rows in tables.values) {
      for (final r in rows.values) {
        final h = r['hlc'] as String?;
        if (h != null && (best == null || h.compareTo(best) > 0)) best = h;
      }
    }
    return best;
  }
}

/// Rows from [remotes] that should replace or add to [local]: per table,
/// those whose HLC is newer than the local copy (or that are missing
/// locally). When several remotes carry the same row, the newest wins.
Map<String, List<Row>> rowsToApply(Snapshot local, Iterable<Snapshot> remotes) {
  final out = <String, List<Row>>{};
  for (final table in syncedTables.keys) {
    final best = <String, Row>{};
    for (final remote in remotes) {
      for (final MapEntry(key: id, value: row)
          in (remote.tables[table] ?? const {}).entries) {
        final current = best[id] ?? local.tables[table]?[id];
        if (current == null || _newer(row, current)) best[id] = row;
      }
    }
    // Keep only rows that actually change something locally.
    final changed = [
      for (final MapEntry(key: id, value: row) in best.entries)
        if (local.tables[table]?[id] == null ||
            _newer(row, local.tables[table]![id]!))
          row,
    ];
    if (changed.isNotEmpty) out[table] = changed;
  }
  return out;
}

bool _newer(Row a, Row b) =>
    ((a['hlc'] as String?) ?? '').compareTo((b['hlc'] as String?) ?? '') > 0;
