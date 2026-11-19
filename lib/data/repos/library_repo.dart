import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/time/day_minutes.dart';
import '../../core/time/hlc.dart';
import '../db/app_database.dart';
import 'refile.dart';

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
    // Added later (see [addedLater]); they take the palette's colours the
    // first seven left unused.
    ('Chores', '🧹', 0xFF26A69A),
    ('Job hunt', '📨', 0xFFE86A92),
    ('Projects', '🛠️', 0xFFAB47BC),
  ];

  /// Starter activities get the same id on every device, so two devices
  /// that each create "Chores" end up with one row, not two to merge.
  static String starterId(String name) => _uuid.v5(
    Namespace.url.value,
    'donut-activity:${name.trim().toLowerCase()}',
  );

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
            id: starterId(name),
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

  // ── one-time: new categories for the daily routine ─────────────────────

  /// Starters that existing installs get from
  /// [fileRoutineIntoNewCategories] rather than from seeding.
  static const addedLater = {'Chores', 'Job hunt', 'Projects'};

  static const routineMigrationKey = 'migrated_routine_categories_v1';

  /// Entries the first seven activities had no home for: (label, the
  /// activity they sit under now or null for none, the new one).
  static const routineRefiles = [
    ('Home chores', null, 'Chores'),
    ('Job applications', null, 'Job hunt'),
    ('Personal project', 'Fun', 'Projects'),
  ];

  /// Once per device: adds Chores, Job hunt and Projects if missing, and
  /// files the routine's matching entries, repeats and templates under
  /// them, with fresh HLCs so the change syncs. Only entries still filed
  /// where the rule expects are touched, so a second run (or a device that
  /// already received the change by sync) writes nothing. Returns how many
  /// rows changed, or null if it had already run.
  ///
  /// Call it after this launch's first sync (see `startRoutineMigration`):
  /// on a device with stale data it would otherwise stamp old rows newer
  /// than the edits waiting for it on Drive.
  Future<int?> fileRoutineIntoNewCategories() => _db.transaction(() async {
    if (await _db.getLocal(routineMigrationKey) != null) return null;
    var changed = 0;
    final all = await _db.select(_db.activities).get();
    final live = {
      for (final a in all.where((a) => !a.deleted))
        a.name.trim().toLowerCase(): a,
    };
    var order = all.fold<int>(-1, (m, a) => a.sortOrder > m ? a.sortOrder : m);
    final ids = <String, String>{};
    for (final (name, emoji, color) in defaultActivities) {
      if (!addedLater.contains(name)) continue;
      final key = name.toLowerCase();
      if (live[key] case final a?) {
        ids[key] = a.id;
        continue;
      }
      final id = starterId(name);
      // Deleted on another device and synced here: leave it deleted.
      if (all.any((a) => a.id == id)) continue;
      await _db
          .into(_db.activities)
          .insert(
            ActivitiesCompanion.insert(
              id: id,
              name: name,
              emoji: emoji,
              color: color,
              sortOrder: Value(++order),
              hlc: _clock.now(),
            ),
          );
      ids[key] = id;
      changed++;
    }
    final rules = [
      for (final (label, from, to) in routineRefiles)
        if (ids[to.toLowerCase()] case final toId?)
          if (from == null || live[from.toLowerCase()] != null)
            RefileRule(
              label: label,
              from: from == null ? null : live[from.toLowerCase()]!.id,
              to: toId,
            ),
    ];
    if (rules.isNotEmpty) changed += await _refile(rules);
    await _db.setLocal(routineMigrationKey, '1');
    return changed;
  });

  /// Applies [rules] to saved entries, sketches, repeats and templates.
  Future<int> _refile(List<RefileRule> rules) async {
    var n = 0;
    final edits = await _db.select(_db.blockEdits).get();
    for (final e in edits) {
      final to = refiledActivity(e.note, e.activityId, rules);
      if (to == null) continue;
      // Sketches are local; they just follow along (no HLC).
      await (_db.update(_db.blockEdits)
            ..where((t) => t.blockId.equals(e.blockId)))
          .write(BlockEditsCompanion(activityId: Value(to)));
    }
    // A saved entry with a sketch over it takes the sketch's activity when
    // it is saved, so it is left alone here.
    final sketched = {for (final e in edits) e.blockId};
    final blocks = await (_db.select(
      _db.blocks,
    )..where((t) => t.deleted.equals(false) & t.note.isNotNull())).get();
    for (final b in blocks) {
      if (sketched.contains(b.id)) continue;
      final to = refiledActivity(b.note, b.activityId, rules);
      if (to == null) continue;
      await (_db.update(_db.blocks)..where((t) => t.id.equals(b.id))).write(
        BlocksCompanion(activityId: Value(to), hlc: Value(_clock.now())),
      );
      n++;
    }
    final series = await (_db.select(
      _db.series,
    )..where((t) => t.deleted.equals(false))).get();
    for (final s in series) {
      final to = refiledActivity(s.note, s.activityId, rules);
      if (to == null) continue;
      await (_db.update(_db.series)..where((t) => t.id.equals(s.id))).write(
        SeriesCompanion(activityId: Value(to), hlc: Value(_clock.now())),
      );
      n++;
    }
    final templates = await (_db.select(
      _db.templates,
    )..where((t) => t.deleted.equals(false))).get();
    for (final t in templates) {
      final json = refileTemplateJson(t.blocksJson, rules);
      if (json == null) continue;
      await (_db.update(_db.templates)..where((x) => x.id.equals(t.id))).write(
        TemplatesCompanion(blocksJson: Value(json), hlc: Value(_clock.now())),
      );
      n++;
    }
    return n;
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
