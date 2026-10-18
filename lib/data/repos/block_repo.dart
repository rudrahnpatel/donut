import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/time/day_minutes.dart';
import '../../core/time/hlc.dart';
import '../db/app_database.dart';

enum BlockStatus { saved, pending, draft, conflict }

/// A block as the UI sees it: the saved row with any unsaved edit applied.
class PlanBlock {
  const PlanBlock({
    required this.id,
    required this.startMin,
    required this.durMin,
    this.emoji,
    this.activityId,
    this.note,
    this.color,
    this.seriesId,
    this.status = BlockStatus.saved,
    this.isNew = false,
  });

  final String id;

  /// Absolute floating minutes; see `day_minutes.dart`.
  final int startMin;
  final int durMin;
  final String? emoji;
  final String? activityId;
  final String? note;

  /// The entry's own colour (ARGB); an activity's colour wins over it.
  final int? color;
  final String? seriesId;
  final BlockStatus status;

  /// Exists only as an unsaved edit.
  final bool isNew;

  int get endMin => startMin + durMin;

  bool overlaps(int from, int to) => startMin < to && endMin > from;

  /// What the entry is called, if anything: its label, else its activity.
  /// Unnamed entries are fine; the UI shows their times instead.
  String? titleWith(String? activityName) => note ?? activityName;

  PlanBlock copyWith({
    int? startMin,
    int? durMin,
    Object? emoji = _keep,
    Object? activityId = _keep,
    Object? note = _keep,
  }) => PlanBlock(
    id: id,
    startMin: startMin ?? this.startMin,
    durMin: durMin ?? this.durMin,
    emoji: emoji == _keep ? this.emoji : emoji as String?,
    activityId: activityId == _keep ? this.activityId : activityId as String?,
    note: note == _keep ? this.note : note as String?,
    color: color,
    seriesId: seriesId,
    status: status,
    isNew: isNew,
  );
}

const Object _keep = Object();

/// Everything the day screen needs about one day.
class DayPlan {
  const DayPlan({
    required this.day,
    required this.blocks,
    required this.pendingCount,
    required this.draftCount,
    required this.otherDaysTouched,
  });

  final Day day;

  /// Blocks overlapping the day and its neighbours (neighbours matter for
  /// drag clamping across midnight). Deleted-in-edit blocks are omitted.
  final List<PlanBlock> blocks;

  /// Unsaved edits touching this day, by state.
  final int pendingCount;
  final int draftCount;

  /// Other days a Save of this day would also change (spilling blocks).
  final Set<Day> otherDaysTouched;

  bool get hasEdits => pendingCount + draftCount > 0;

  Iterable<PlanBlock> get onDay =>
      blocks.where((b) => b.overlaps(day.startMin, day.endMin));
}

/// What an edit replaced, so it can be undone.
class EditUndo {
  const EditUndo(this.blockId, this.previous);
  final String blockId;
  final BlockEditRow? previous;
}

class BlockRepo {
  BlockRepo(this._db, this._clock);

  final AppDatabase _db;
  final HlcClock _clock;
  static const _uuid = Uuid();

  // ── reading ────────────────────────────────────────────────────────────

  Stream<DayPlan> watchDay(Day day) async* {
    yield await loadDay(day);
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.blocks, _db.blockEdits]),
    )) {
      yield await loadDay(day);
    }
  }

  Future<DayPlan> loadDay(Day day) async {
    final from = day.startMin - minutesPerDay;
    final to = day.endMin + minutesPerDay;
    final saved = await _savedIn(from, to);
    final edits = await _db.select(_db.blockEdits).get();
    final blocks = _merge(saved, edits, from, to);

    var pending = 0, drafts = 0;
    final others = <Day>{};
    final savedById = {for (final s in saved) s.id: s};
    for (final e in edits) {
      final base = savedById[e.blockId];
      if (!_editTouches(e, base, day.startMin, day.endMin)) continue;
      if (e.state == EditState.pending) {
        pending++;
      } else {
        drafts++;
      }
      for (final (s, end) in [
        (e.startMin, e.startMin + e.durMin),
        if (base != null) (base.startMin, base.startMin + base.durMin),
      ]) {
        for (var d = Day.containing(s); d.startMin < end; d = d.addDays(1)) {
          if (d != day) others.add(d);
        }
      }
    }
    return DayPlan(
      day: day,
      blocks: blocks,
      pendingCount: pending,
      draftCount: drafts,
      otherDaysTouched: others,
    );
  }

  /// Saved blocks only (no edits) overlapping `[from, to)`.
  Future<List<PlanBlock>> savedInRange(int from, int to) async => [
    for (final r in await _savedIn(from, to)) _fromSaved(r),
  ];

  Stream<List<PlanBlock>> watchSavedInRange(int from, int to) =>
      (_db.select(_db.blocks)..where(
            (t) =>
                t.deleted.equals(false) &
                t.startMin.isSmallerThanValue(to) &
                t.startMin.isBiggerThanValue(from - minutesPerDay),
          ))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                if (r.startMin + r.durMin > from) _fromSaved(r),
            ],
          );

  /// Saved + edited blocks overlapping `[from, to)` (for the month view).
  Stream<List<PlanBlock>> watchEffectiveInRange(int from, int to) async* {
    Future<List<PlanBlock>> load() async => _merge(
      await _savedIn(from, to),
      await _db.select(_db.blockEdits).get(),
      from,
      to,
    );
    yield await load();
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.blocks, _db.blockEdits]),
    )) {
      yield await load();
    }
  }

  Future<List<BlockRow>> _savedIn(int from, int to) =>
      (_db.select(_db.blocks)..where(
            (t) =>
                t.deleted.equals(false) &
                t.startMin.isSmallerThanValue(to) &
                // Blocks are at most a day long, so this bounds the scan.
                t.startMin.isBiggerThanValue(from - minutesPerDay - 1),
          ))
          .get()
          .then(
            (rows) => [
              for (final r in rows)
                if (r.startMin + r.durMin > from) r,
            ],
          );

  List<PlanBlock> _merge(
    List<BlockRow> saved,
    List<BlockEditRow> edits,
    int from,
    int to,
  ) {
    final editById = {for (final e in edits) e.blockId: e};
    final out = <PlanBlock>[];
    for (final s in saved) {
      final e = editById.remove(s.id);
      if (e == null) {
        out.add(_fromSaved(s));
      } else if (!e.deleted &&
          e.startMin < to &&
          e.startMin + e.durMin > from) {
        out.add(_fromEdit(e, isNew: false, conflict: e.baseHlc != s.hlc));
      }
    }
    // Remaining edits are new blocks, or edits of saved blocks that moved
    // into this range from outside it.
    for (final e in editById.values) {
      if (e.deleted) continue;
      if (e.startMin < to && e.startMin + e.durMin > from) {
        out.add(_fromEdit(e, isNew: e.baseHlc == null, conflict: false));
      }
    }
    out.sort((a, b) => a.startMin.compareTo(b.startMin));
    return out;
  }

  static bool _editTouches(BlockEditRow e, BlockRow? base, int from, int to) {
    if (e.startMin < to && e.startMin + e.durMin > from) return true;
    return base != null &&
        base.startMin < to &&
        base.startMin + base.durMin > from;
  }

  static PlanBlock _fromSaved(BlockRow r) => PlanBlock(
    id: r.id,
    startMin: r.startMin,
    durMin: r.durMin,
    emoji: r.emoji,
    activityId: r.activityId,
    note: r.note,
    color: r.color,
    seriesId: r.seriesId,
  );

  static PlanBlock _fromEdit(
    BlockEditRow e, {
    required bool isNew,
    required bool conflict,
  }) => PlanBlock(
    id: e.blockId,
    startMin: e.startMin,
    durMin: e.durMin,
    emoji: e.emoji,
    activityId: e.activityId,
    note: e.note,
    color: e.color,
    seriesId: e.seriesId,
    status: conflict
        ? BlockStatus.conflict
        : (e.state == EditState.draft
              ? BlockStatus.draft
              : BlockStatus.pending),
    isNew: isNew,
  );

  // ── editing (writes go to the overlay only) ─────────────────────────────

  Future<(String, EditUndo)> create(
    int startMin,
    int endMin, {
    String? emoji,
    String? activityId,
    String? note,
    int? color,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.blockEdits)
        .insert(
          BlockEditsCompanion.insert(
            blockId: id,
            startMin: startMin,
            durMin: endMin - startMin,
            emoji: Value(emoji),
            activityId: Value(activityId),
            note: Value(note),
            color: Value(color),
            // Every edit lands as a draft straight away; Save commits it.
            state: EditState.draft,
            editedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return (id, EditUndo(id, null));
  }

  /// Applies [change] to the block's current effective state.
  Future<EditUndo?> update(String id, PlanBlock Function(PlanBlock) change) =>
      _db.transaction(() async {
        final prev = await _edit(id);
        final saved = await _saved(id);
        final current = prev != null
            ? _fromEdit(prev, isNew: prev.baseHlc == null, conflict: false)
            : (saved != null ? _fromSaved(saved) : null);
        if (current == null) return null;
        final next = change(current);
        await _db
            .into(_db.blockEdits)
            .insertOnConflictUpdate(
              BlockEditsCompanion.insert(
                blockId: id,
                startMin: next.startMin,
                durMin: next.durMin,
                emoji: Value(next.emoji),
                activityId: Value(next.activityId),
                note: Value(next.note),
                color: Value(next.color),
                seriesId: Value(next.seriesId),
                baseHlc: Value(prev?.baseHlc ?? saved?.hlc),
                state: EditState.draft,
                editedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
        return EditUndo(id, prev);
      });

  Future<EditUndo?> delete(String id) => _db.transaction(() async {
    final prev = await _edit(id);
    final saved = await _saved(id);
    if (saved == null) {
      // Never saved: just drop the overlay row.
      await (_db.delete(
        _db.blockEdits,
      )..where((t) => t.blockId.equals(id))).go();
      return EditUndo(id, prev);
    }
    await _db
        .into(_db.blockEdits)
        .insertOnConflictUpdate(
          BlockEditsCompanion.insert(
            blockId: id,
            deleted: const Value(true),
            startMin: saved.startMin,
            durMin: saved.durMin,
            seriesId: Value(saved.seriesId),
            baseHlc: Value(prev?.baseHlc ?? saved.hlc),
            state: EditState.draft,
            editedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return EditUndo(id, prev);
  });

  Future<void> undo(EditUndo u) => _db.transaction(() async {
    await (_db.delete(
      _db.blockEdits,
    )..where((t) => t.blockId.equals(u.blockId))).go();
    if (u.previous != null) await _db.into(_db.blockEdits).insert(u.previous!);
  });

  /// Parks this day's unsaved edits as a draft.
  Future<void> markDraft(Day day) async {
    final rows = await _editsTouching(day);
    await (_db.update(_db.blockEdits)
          ..where((t) => t.blockId.isIn(rows.map((r) => r.blockId))))
        .write(const BlockEditsCompanion(state: Value(EditState.draft)));
  }

  /// Throws away this day's edits. Returns them for undo.
  Future<List<BlockEditRow>> discard(Day day) => _db.transaction(() async {
    final rows = await _editsTouching(day);
    await (_db.delete(
      _db.blockEdits,
    )..where((t) => t.blockId.isIn(rows.map((r) => r.blockId)))).go();
    return rows;
  });

  Future<void> restore(List<BlockEditRow> rows) => _db.batch((b) {
    for (final r in rows) {
      b.insert(_db.blockEdits, r, mode: InsertMode.insertOrReplace);
    }
  });

  /// Commits this day's edits to the saved table. Returns the saved block
  /// ids so callers can schedule reminders and sync.
  /// Commits this day's drafts to the saved table. Returns the saved block
  /// ids so callers can schedule reminders and sync.
  Future<List<String>> save(Day day) =>
      _db.transaction(() async => _commit(await _editsTouching(day)));

  /// Commits every draft (leaving plan mode with ✓).
  Future<List<String>> saveAll() => _db.transaction(
    () async => _commit(await _db.select(_db.blockEdits).get()),
  );

  /// Throws away every draft (leaving plan mode with ✕). Returns them for
  /// undo.
  Future<List<BlockEditRow>> discardAll() => _db.transaction(() async {
    final rows = await _db.select(_db.blockEdits).get();
    await _db.delete(_db.blockEdits).go();
    return rows;
  });

  /// Number of drafts across all days; non-zero means a plan is open.
  Stream<int> watchDraftCount() =>
      _db.select(_db.blockEdits).watch().map((rows) => rows.length);

  Future<List<String>> _commit(List<BlockEditRow> rows) async {
    for (final e in rows) {
      final saved = await _saved(e.blockId);
      final hlc = _clock.now();
      if (e.deleted) {
        if (saved != null) {
          await (_db.update(
            _db.blocks,
          )..where((t) => t.id.equals(e.blockId))).write(
            BlocksCompanion(deleted: const Value(true), hlc: Value(hlc)),
          );
        }
        continue;
      }
      await _db
          .into(_db.blocks)
          .insertOnConflictUpdate(
            BlocksCompanion.insert(
              id: e.blockId,
              startMin: e.startMin,
              durMin: e.durMin,
              emoji: Value(e.emoji),
              activityId: Value(e.activityId),
              note: Value(e.note),
              color: Value(e.color),
              seriesId: Value(e.seriesId),
              // A hand-edited series instance stops following the series.
              detached: Value(saved != null && e.seriesId != null),
              hlc: hlc,
            ),
          );
    }
    await (_db.delete(
      _db.blockEdits,
    )..where((t) => t.blockId.isIn(rows.map((r) => r.blockId)))).go();
    return [for (final r in rows) r.blockId];
  }

  // ── instant edits (outside plan mode) ───────────────────────────────────

  /// Creates a saved entry directly, skipping the draft overlay.
  Future<String> createSaved(
    int startMin,
    int endMin, {
    String? activityId,
    String? note,
    int? color,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.blocks)
        .insert(
          BlocksCompanion.insert(
            id: id,
            startMin: startMin,
            durMin: endMin - startMin,
            activityId: Value(activityId),
            note: Value(note),
            color: Value(color),
            hlc: _clock.now(),
          ),
        );
    return id;
  }

  /// Applies [change] to a saved entry directly.
  Future<void> updateSaved(String id, PlanBlock Function(PlanBlock) change) =>
      _db.transaction(() async {
        final saved = await _saved(id);
        if (saved == null) return;
        final next = change(_fromSaved(saved));
        await (_db.update(_db.blocks)..where((t) => t.id.equals(id))).write(
          BlocksCompanion(
            startMin: Value(next.startMin),
            durMin: Value(next.durMin),
            emoji: Value(next.emoji),
            activityId: Value(next.activityId),
            note: Value(next.note),
            color: Value(next.color),
            detached: Value(saved.detached || saved.seriesId != null),
            hlc: Value(_clock.now()),
          ),
        );
      });

  /// Deletes (tombstones) a saved entry directly; [restoreSaved] undoes it.
  Future<void> deleteSaved(String id) => _setDeleted(id, true);

  Future<void> restoreSaved(String id) => _setDeleted(id, false);

  Future<void> _setDeleted(String id, bool deleted) =>
      (_db.update(_db.blocks)..where((t) => t.id.equals(id))).write(
        BlocksCompanion(deleted: Value(deleted), hlc: Value(_clock.now())),
      );

  Future<List<BlockEditRow>> _editsTouching(Day day) async {
    final edits = await _db.select(_db.blockEdits).get();
    final out = <BlockEditRow>[];
    for (final e in edits) {
      if (_editTouches(e, await _saved(e.blockId), day.startMin, day.endMin)) {
        out.add(e);
      }
    }
    return out;
  }

  Future<BlockEditRow?> _edit(String id) => (_db.select(
    _db.blockEdits,
  )..where((t) => t.blockId.equals(id))).getSingleOrNull();

  Future<BlockRow?> _saved(String id) => (_db.select(
    _db.blocks,
  )..where((t) => t.id.equals(id) & t.deleted.equals(false))).getSingleOrNull();
}
