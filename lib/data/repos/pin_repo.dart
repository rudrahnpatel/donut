import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/time/day_minutes.dart';
import '../../core/time/hlc.dart';
import '../db/app_database.dart';

/// What a pin marks. The first three read as "Reach by 4:55 PM".
enum PinKind {
  reachBy('🏁', 'Reach by'),
  meetingAt('🤝', 'Meeting at'),
  leaveBy('🚶', 'Leave by'),
  custom('📌', 'Pin');

  const PinKind(this.glyph, this.verb);

  final String glyph;
  final String verb;

  static PinKind parse(String name) =>
      values.firstWhere((k) => k.name == name, orElse: () => custom);
}

/// Where a pin dropped from an entry `[start, end)` lands when held at
/// minute [held]: that moment, snapped to [step], or the entry's start or
/// end when held within a few minutes of it (the larger of [step] and a
/// tenth of the entry, at most 10 minutes), so "Reach by" the end of a
/// train needs no precise aim.
int pinSpotInEntry({
  required int start,
  required int end,
  required double held,
  required int step,
}) {
  final edge = math.max(step, math.min(10, (end - start) ~/ 10));
  final toStart = held - start, toEnd = end - held;
  if (math.min(toStart, toEnd) <= edge) return toStart <= toEnd ? start : end;
  final snapped = (held / step).round() * step;
  return snapped.clamp(start, end);
}

extension PinText on PinRow {
  PinKind get pinKind => PinKind.parse(kind);

  /// "Reach by", "Meeting at", or a custom pin's text.
  String get title =>
      pinKind == PinKind.custom ? (label ?? PinKind.custom.verb) : pinKind.verb;

  /// "Reach by 4:55 PM", or "train leaves · 4:55 PM" for a custom pin.
  String describe({bool use24h = false}) {
    final time = formatClock(minuteOfDay(atMin), use24h: use24h);
    return pinKind == PinKind.custom ? '$title · $time' : '$title $time';
  }
}

/// Pins: points in time to plan around ("Reach by 4:55"). Unlike entries
/// they have no edit overlay: a pin dropped in plan mode is a [PinRow.draft]
/// until ✓ commits or ✕ discards it, and drafts never sync or remind.
class PinRepo {
  PinRepo(this._db, this._clock);

  final AppDatabase _db;
  final HlcClock _clock;
  static const _uuid = Uuid();

  /// Pins (sketches included) at minutes in `[from, to)`, in time order.
  Stream<List<PinRow>> watchRange(int from, int to) =>
      (_db.select(_db.pins)
            ..where(
              (t) =>
                  t.deleted.equals(false) &
                  t.atMin.isBiggerOrEqualValue(from) &
                  t.atMin.isSmallerThanValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.atMin)]))
          .watch();

  Future<String> create(
    int atMin,
    PinKind kind, {
    String? label,
    required bool draft,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.pins)
        .insert(
          PinsCompanion.insert(
            id: id,
            atMin: atMin,
            kind: kind.name,
            label: Value(label),
            draft: Value(draft),
            hlc: _clock.now(),
          ),
        );
    return id;
  }

  Future<void> move(String id, int atMin) =>
      _write(id, PinsCompanion(atMin: Value(atMin)));

  /// Removes a pin (a sketch just disappears). Returns it for [restore].
  Future<PinRow?> delete(String id) async {
    final row = await (_db.select(
      _db.pins,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    if (row.draft) {
      await (_db.delete(_db.pins)..where((t) => t.id.equals(id))).go();
    } else {
      await _write(id, const PinsCompanion(deleted: Value(true)));
    }
    return row;
  }

  /// Puts back pins removed by [delete] or [discardDrafts].
  Future<void> restore(Iterable<PinRow> rows) => _db.batch((b) {
    for (final r in rows) {
      b.insert(
        _db.pins,
        r.copyWith(deleted: false, hlc: _clock.now()),
        mode: InsertMode.insertOrReplace,
      );
    }
  });

  /// ✓ in plan mode: sketched pins become real, so they sync and remind.
  Future<int> commitDrafts() =>
      (_db.update(_db.pins)..where((t) => t.draft.equals(true))).write(
        PinsCompanion(draft: const Value(false), hlc: Value(_clock.now())),
      );

  /// ✕ in plan mode. Returns the removed sketches for Undo.
  Future<List<PinRow>> discardDrafts() => _db.transaction(() async {
    final rows = await (_db.select(
      _db.pins,
    )..where((t) => t.draft.equals(true))).get();
    await (_db.delete(_db.pins)..where((t) => t.draft.equals(true))).go();
    return rows;
  });

  Stream<int> watchDraftCount() => (_db.select(
    _db.pins,
  )..where((t) => t.draft.equals(true))).watch().map((rows) => rows.length);

  /// The texts of recent custom pins, newest first, for the pin fan.
  Stream<List<String>> watchRecentCustom({int limit = 3}) =>
      (_db.select(_db.pins)
            ..where(
              (t) => t.kind.equals(PinKind.custom.name) & t.label.isNotNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.hlc)])
            ..limit(40))
          .watch()
          .map(
            (rows) => rows.map((r) => r.label!).toSet().take(limit).toList(),
          );

  Future<void> _write(String id, PinsCompanion change) =>
      (_db.update(_db.pins)..where((t) => t.id.equals(id))).write(
        change.copyWith(hlc: Value(_clock.now())),
      );
}
