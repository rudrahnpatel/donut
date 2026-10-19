import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/time/day_minutes.dart';
import '../../core/time/hlc.dart';
import '../db/app_database.dart';

/// A worked session as the tracker writes it (epoch milliseconds).
class TrackedSession {
  const TrackedSession({
    required this.start,
    required this.end,
    this.manual = false,
    this.projects = const {},
  });

  factory TrackedSession.fromJson(Map<String, dynamic> j) => TrackedSession(
    start: (j['start'] as num).toInt(),
    end: (j['end'] as num).toInt(),
    manual: j['manual'] as bool? ?? false,
    projects: {
      for (final e in ((j['projects'] as Map?) ?? const {}).entries)
        e.key as String: (e.value as num).round(),
    },
  );

  final int start;
  final int end;
  final bool manual;

  /// Project → seconds.
  final Map<String, int> projects;
}

extension WorkSessionInfo on WorkSessionRow {
  /// Project → seconds.
  Map<String, int> get projects => {
    for (final e in (jsonDecode(projectsJson) as Map).entries)
      e.key as String: (e.value as num).round(),
  };
}

/// Minutes of [sessions] inside `[from, to)`, overlaps counted once.
int workedMinutes(Iterable<WorkSessionRow> sessions, int from, int to) {
  final spans = [
    for (final s in sessions)
      if (!s.deleted && s.endMin > from && s.startMin < to)
        (s.startMin < from ? from : s.startMin, s.endMin > to ? to : s.endMin),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  var total = 0, until = from;
  for (final (s, e) in spans) {
    final start = s > until ? s : until;
    if (e > start) total += e - start;
    if (e > until) until = e;
  }
  return total;
}

/// Worked sessions: imported from the desktop tracker and synced.
class WorkRepo {
  WorkRepo(this._db, this._clock);

  final AppDatabase _db;
  final HlcClock _clock;

  /// Sessions overlapping `[from, to)`.
  Stream<List<WorkSessionRow>> watchRange(int from, int to) =>
      (_db.select(_db.workSessions)
            ..where(
              (t) =>
                  t.deleted.equals(false) &
                  t.endMin.isBiggerThanValue(from) &
                  t.startMin.isSmallerThanValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startMin)]))
          .watch();

  /// Brings [day]'s sessions from [source] in line with [sessions]: new and
  /// grown ones are written, ones no longer there (dropped as "not work" in
  /// the tracker) are deleted. A session excluded in Donut stays excluded,
  /// however long the tracker keeps it. Returns how many rows changed.
  Future<int> importDay(
    Day day,
    List<TrackedSession> sessions, {
    required String source,
  }) => _db.transaction(() async {
    final existing = {
      for (final r
          in await (_db.select(_db.workSessions)..where(
                (t) =>
                    t.source.equals(source) &
                    t.startMin.isBiggerOrEqualValue(day.startMin) &
                    t.startMin.isSmallerThanValue(day.endMin),
              ))
              .get())
        r.id: r,
    };
    var changed = 0;
    final seen = <String>{};
    for (final s in sessions) {
      final id = '$source-${s.start}';
      seen.add(id);
      final startMin = absMinuteOf(
        DateTime.fromMillisecondsSinceEpoch(s.start),
      );
      final endMin = absMinuteOf(DateTime.fromMillisecondsSinceEpoch(s.end))
          .clamp(startMin + 1, startMin + minutesPerDay);
      final projects = jsonEncode(s.projects);
      final old = existing[id];
      if (old != null && old.deleted) continue;
      if (old != null &&
          old.startMin == startMin &&
          old.endMin == endMin &&
          old.projectsJson == projects &&
          old.manual == s.manual) {
        continue;
      }
      await _db
          .into(_db.workSessions)
          .insertOnConflictUpdate(
            WorkSessionsCompanion.insert(
              id: id,
              startMin: startMin,
              endMin: endMin,
              projectsJson: projects,
              source: source,
              manual: Value(s.manual),
              hlc: _clock.now(),
            ),
          );
      changed++;
    }
    for (final r in existing.values) {
      if (r.deleted || seen.contains(r.id)) continue;
      await (_db.update(
        _db.workSessions,
      )..where((t) => t.id.equals(r.id))).write(
        WorkSessionsCompanion(
          deleted: const Value(true),
          hlc: Value(_clock.now()),
        ),
      );
      changed++;
    }
    return changed;
  });

  /// "Not work": hides a session everywhere (it syncs as a deletion).
  Future<void> exclude(String id) =>
      (_db.update(_db.workSessions)..where((t) => t.id.equals(id))).write(
        WorkSessionsCompanion(
          deleted: const Value(true),
          hlc: Value(_clock.now()),
        ),
      );

  /// Whether any session of any source starts on [day].
  Future<bool> hasDay(Day day) async =>
      (await (_db.select(_db.workSessions)
                ..where(
                  (t) =>
                      t.startMin.isBiggerOrEqualValue(day.startMin) &
                      t.startMin.isSmallerThanValue(day.endMin),
                )
                ..limit(1))
              .get())
          .isNotEmpty;
}
