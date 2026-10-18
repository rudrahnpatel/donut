import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/time/day_minutes.dart';
import '../../core/time/hlc.dart';
import '../db/app_database.dart';

/// Activities ("Study", "Gym") and their to-dos.
class LibraryRepo {
  LibraryRepo(this._db, this._clock);

  final AppDatabase _db;
  final HlcClock _clock;
  static const _uuid = Uuid();

  static const defaultActivities = [
    ('Study', '📚', 0xFF7C6CF2),
    ('Work', '💼', 0xFF3E8ED0),
    ('Gym', '💪', 0xFFE5604D),
    ('Meal', '🍽️', 0xFFF2A541),
    ('Sleep', '😴', 0xFF5C6B8A),
    ('Break', '☕', 0xFF8D6E63),
    ('Fun', '🎮', 0xFF43B581),
  ];

  /// Starter tasks are stamped older than any real edit, so when a new
  /// device's untouched copies meet edited ones from another device during
  /// sync, the edits win (see `SyncStore.mergeDuplicateActivities`).
  static const _seedHlc = '000000000000000-00000-seed';

  /// Seeds starter activities on a fresh install.
  Future<void> seedIfEmpty() async {
    if (await _db.getLocal('seeded') != null) return;
    await _db.batch((b) {
      for (var i = 0; i < defaultActivities.length; i++) {
        final (name, emoji, color) = defaultActivities[i];
        b.insert(
          _db.activities,
          ActivitiesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            emoji: emoji,
            color: color,
            sortOrder: Value(i),
            hlc: _seedHlc,
          ),
        );
      }
    });
    await _db.setLocal('seeded', '1');
  }

  // ── activities ─────────────────────────────────────────────────────────

  Stream<List<ActivityRow>> watchActivities({bool includeArchived = false}) =>
      (_db.select(_db.activities)
            ..where(
              (t) =>
                  t.deleted.equals(false) &
                  (includeArchived
                      ? const Constant(true)
                      : t.archived.equals(false)),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.name),
            ]))
          .watch();

  Future<String> addActivity(String name, String emoji, int color) async {
    final id = _uuid.v4();
    final count = await _db.activities.count().getSingle();
    await _db
        .into(_db.activities)
        .insert(
          ActivitiesCompanion.insert(
            id: id,
            name: name,
            emoji: emoji,
            color: color,
            sortOrder: Value(count),
            hlc: _clock.now(),
          ),
        );
    return id;
  }

  Future<void> updateActivity(
    String id, {
    String? name,
    String? emoji,
    int? color,
    bool? pinned,
    bool? archived,
  }) => (_db.update(_db.activities)..where((t) => t.id.equals(id))).write(
    ActivitiesCompanion(
      name: Value.absentIfNull(name),
      emoji: Value.absentIfNull(emoji),
      color: Value.absentIfNull(color),
      pinned: Value.absentIfNull(pinned),
      archived: Value.absentIfNull(archived),
      hlc: Value(_clock.now()),
    ),
  );

  Future<void> deleteActivity(String id) =>
      (_db.update(_db.activities)..where((t) => t.id.equals(id))).write(
        ActivitiesCompanion(
          deleted: const Value(true),
          hlc: Value(_clock.now()),
        ),
      );

  Future<void> reorderActivities(List<String> idsInOrder) => _db.batch((b) {
    for (var i = 0; i < idsInOrder.length; i++) {
      b.update(
        _db.activities,
        ActivitiesCompanion(sortOrder: Value(i), hlc: Value(_clock.now())),
        where: (t) => t.id.equals(idsInOrder[i]),
      );
    }
  });

  // ── to-dos ─────────────────────────────────────────────────────────────

  Stream<List<TodoRow>> watchTodos({
    String? activityId,
    bool includeDone = true,
  }) {
    final q = _db.select(_db.todos)
      ..where((t) {
        Expression<bool> e = t.deleted.equals(false);
        if (activityId != null) e = e & t.activityId.equals(activityId);
        if (!includeDone) e = e & t.done.equals(false);
        return e;
      })
      ..orderBy([
        (t) => OrderingTerm.asc(t.done),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return q.watch();
  }

  Future<List<TodoRow>> openTodos(String activityId) =>
      (_db.select(_db.todos)
            ..where(
              (t) =>
                  t.deleted.equals(false) &
                  t.done.equals(false) &
                  t.activityId.equals(activityId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<String> addTodo(String title, {String? activityId}) async {
    final id = _uuid.v4();
    await _db
        .into(_db.todos)
        .insert(
          TodosCompanion.insert(
            id: id,
            title: title,
            activityId: Value(activityId),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            hlc: _clock.now(),
          ),
        );
    return id;
  }

  Future<void> updateTodo(
    String id, {
    String? title,
    bool? done,
    Value<String?> activityId = const Value.absent(),
    Value<String?> blockId = const Value.absent(),
  }) => (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
    TodosCompanion(
      title: Value.absentIfNull(title),
      done: Value.absentIfNull(done),
      activityId: activityId,
      blockId: blockId,
      hlc: Value(_clock.now()),
    ),
  );

  Future<void> deleteTodo(String id) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(deleted: const Value(true), hlc: Value(_clock.now())),
      );

  Stream<List<TodoRow>> watchTodosForBlock(String blockId) => (_db.select(
    _db.todos,
  )..where((t) => t.deleted.equals(false) & t.blockId.equals(blockId))).watch();

  // ── quick-slot ranking ─────────────────────────────────────────────────

  /// Most-used emojis over the last 60 days of saved blocks.
  Future<List<String>> topEmojis({int limit = 7}) async {
    final since = nowAbsMinute() - 60 * minutesPerDay;
    final rows = await _db
        .customSelect(
          'SELECT emoji, COUNT(*) AS n FROM blocks '
          'WHERE deleted = 0 AND emoji IS NOT NULL AND start_min > ? '
          'GROUP BY emoji ORDER BY n DESC LIMIT ?',
          variables: [Variable.withInt(since), Variable.withInt(limit)],
          readsFrom: {_db.blocks},
        )
        .get();
    return [for (final r in rows) r.read<String>('emoji')];
  }

  /// Activity ids by use over the last 60 days of saved blocks.
  Future<List<String>> topActivityIds({int limit = 7}) async {
    final since = nowAbsMinute() - 60 * minutesPerDay;
    final rows = await _db
        .customSelect(
          'SELECT activity_id, COUNT(*) AS n FROM blocks '
          'WHERE deleted = 0 AND activity_id IS NOT NULL AND start_min > ? '
          'GROUP BY activity_id ORDER BY n DESC LIMIT ?',
          variables: [Variable.withInt(since), Variable.withInt(limit)],
          readsFrom: {_db.blocks},
        )
        .get();
    return [for (final r in rows) r.read<String>('activity_id')];
  }

  /// Labels (block notes) used most recently, newest first.
  Stream<List<String>> watchRecentLabels({int limit = 6}) => _db
      .customSelect(
        'SELECT note FROM blocks WHERE deleted = 0 AND note IS NOT NULL '
        'GROUP BY note ORDER BY MAX(hlc) DESC LIMIT ?',
        variables: [Variable.withInt(limit)],
        readsFrom: {_db.blocks},
      )
      .watch()
      .map((rows) => [for (final r in rows) r.read<String>('note')]);
}
