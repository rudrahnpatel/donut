import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/time/day_minutes.dart';
import '../../core/time/hlc.dart';
import '../db/app_database.dart';
import 'block_repo.dart';

/// One block inside a template, relative to the day's midnight.
class TemplateBlock {
  const TemplateBlock(
    this.start,
    this.dur, {
    this.emoji,
    this.activityId,
    this.note,
  });

  factory TemplateBlock.fromJson(Map<String, dynamic> j) => TemplateBlock(
    j['s'] as int,
    j['d'] as int,
    emoji: j['e'] as String?,
    activityId: j['a'] as String?,
    note: j['n'] as String?,
  );

  final int start;
  final int dur;
  final String? emoji;
  final String? activityId;
  final String? note;

  Map<String, Object?> toJson() => {
    's': start,
    'd': dur,
    if (emoji != null) 'e': emoji,
    if (activityId != null) 'a': activityId,
    if (note != null) 'n': note,
  };
}

/// Recurrence rule: `daily` or `weekly:1,3,5` (ISO weekdays).
class RepeatRule {
  const RepeatRule.daily() : weekdays = const {1, 2, 3, 4, 5, 6, 7};
  const RepeatRule.weekly(this.weekdays);

  factory RepeatRule.parse(String s) {
    if (s == 'daily') return const RepeatRule.daily();
    final days = s
        .substring('weekly:'.length)
        .split(',')
        .map(int.parse)
        .toSet();
    return RepeatRule.weekly(days);
  }

  final Set<int> weekdays;

  bool matches(Day d) => weekdays.contains(d.weekday);

  String encode() => weekdays.length == 7
      ? 'daily'
      : 'weekly:${(weekdays.toList()..sort()).join(',')}';

  String describe() {
    if (weekdays.length == 7) return 'Every day';
    if (weekdays.length == 5 &&
        !weekdays.contains(6) &&
        !weekdays.contains(7)) {
      return 'Weekdays';
    }
    if (weekdays.length == 2 && weekdays.containsAll({6, 7})) return 'Weekends';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return (weekdays.toList()..sort()).map((d) => names[d - 1]).join(', ');
  }
}

/// Templates, "copy yesterday", and recurring series.
class PlanToolsRepo {
  PlanToolsRepo(this._db, this._clock, this._blocks);

  final AppDatabase _db;
  final HlcClock _clock;
  final BlockRepo _blocks;
  static const _uuid = Uuid();

  /// How far ahead series instances are generated.
  static const windowDays = 14;

  // ── templates ──────────────────────────────────────────────────────────

  Stream<List<TemplateRow>> watchTemplates() =>
      (_db.select(_db.templates)
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<void> saveDayAsTemplate(String name, Day day) async {
    final plan = await _blocks.loadDay(day);
    final blocks = [
      for (final b in plan.blocks)
        if (b.startMin >= day.startMin && b.startMin < day.endMin)
          TemplateBlock(
            b.startMin - day.startMin,
            b.durMin,
            emoji: b.emoji,
            activityId: b.activityId,
            note: b.note,
          ).toJson(),
    ];
    await _db
        .into(_db.templates)
        .insert(
          TemplatesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            blocksJson: jsonEncode(blocks),
            hlc: _clock.now(),
          ),
        );
  }

  Future<void> deleteTemplate(String id) =>
      (_db.update(_db.templates)..where((t) => t.id.equals(id))).write(
        TemplatesCompanion(
          deleted: const Value(true),
          hlc: Value(_clock.now()),
        ),
      );

  /// Adds the template's blocks to [day] as unsaved edits, skipping any that
  /// would overlap what is already there. Returns how many were added.
  Future<int> applyTemplate(TemplateRow t, Day day) {
    final blocks = [
      for (final j in jsonDecode(t.blocksJson) as List)
        TemplateBlock.fromJson(j as Map<String, dynamic>),
    ];
    return _applyBlocks(blocks, day);
  }

  /// Copies the blocks that start on the previous day into [day].
  Future<int> copyFrom(Day source, Day day) async {
    final plan = await _blocks.loadDay(source);
    return _applyBlocks([
      for (final b in plan.blocks)
        if (b.startMin >= source.startMin && b.startMin < source.endMin)
          TemplateBlock(
            b.startMin - source.startMin,
            b.durMin,
            emoji: b.emoji,
            activityId: b.activityId,
            note: b.note,
          ),
    ], day);
  }

  Future<int> _applyBlocks(List<TemplateBlock> blocks, Day day) async {
    final existing = (await _blocks.loadDay(day)).blocks;
    final taken = [for (final b in existing) (b.startMin, b.endMin)];
    var added = 0;
    for (final t in blocks) {
      final s = day.startMin + t.start, e = s + t.dur;
      if (taken.any((x) => x.$1 < e && x.$2 > s)) continue;
      await _blocks.create(
        s,
        e,
        emoji: t.emoji,
        activityId: t.activityId,
        note: t.note,
      );
      taken.add((s, e));
      added++;
    }
    return added;
  }

  // ── series ─────────────────────────────────────────────────────────────

  Stream<List<SeriesRow>> watchSeries() =>
      (_db.select(_db.series)
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.startMinOfDay)]))
          .watch();

  Future<void> createSeries({
    required RepeatRule rule,
    required Day from,
    required int startMinOfDay,
    required int durMin,
    String? emoji,
    String? activityId,
    String? note,
  }) async {
    await _db
        .into(_db.series)
        .insert(
          SeriesCompanion.insert(
            id: _uuid.v4(),
            rule: rule.encode(),
            startMinOfDay: startMinOfDay,
            durMin: durMin,
            emoji: Value(emoji),
            activityId: Value(activityId),
            note: Value(note),
            fromDay: from.epochDay,
            hlc: _clock.now(),
          ),
        );
    await generate(from: from);
  }

  /// Stops a series: removes its untouched future instances from [after]
  /// onwards; hand-edited (detached) ones stay.
  Future<void> endSeries(String id, {required Day after}) =>
      _db.transaction(() async {
        await (_db.update(_db.series)..where((t) => t.id.equals(id))).write(
          SeriesCompanion(
            deleted: const Value(true),
            untilDay: Value(after.epochDay - 1),
            hlc: Value(_clock.now()),
          ),
        );
        await (_db.update(_db.blocks)..where(
              (t) =>
                  t.seriesId.equals(id) &
                  t.detached.equals(false) &
                  t.deleted.equals(false) &
                  t.startMin.isBiggerOrEqualValue(after.startMin),
            ))
            .write(
              BlocksCompanion(
                deleted: const Value(true),
                hlc: Value(_clock.now()),
              ),
            );
      });

  /// Generates series instances as saved blocks for the window starting at
  /// [from]. Ids are UUIDv5(series, day), so re-running — on this device or
  /// another — never duplicates; a slot already occupied is skipped.
  Future<void> generate({required Day from, int days = windowDays}) =>
      _db.transaction(() async {
        final all = await (_db.select(
          _db.series,
        )..where((t) => t.deleted.equals(false))).get();
        if (all.isEmpty) return;
        final windowEnd = from.addDays(days);
        final occupied = [
          for (final b in await _blocks.savedInRange(
            from.startMin - minutesPerDay,
            windowEnd.endMin,
          ))
            (b.startMin, b.endMin),
        ];
        for (final s in all) {
          final rule = RepeatRule.parse(s.rule);
          for (var d = from; d < windowEnd; d = d.addDays(1)) {
            if (d.epochDay < s.fromDay) continue;
            if (s.untilDay != null && d.epochDay > s.untilDay!) continue;
            if (!rule.matches(d)) continue;
            final id = _uuid.v5(
              Namespace.url.value,
              'donut-series:${s.id}/${d.iso}',
            );
            final exists = await (_db.select(
              _db.blocks,
            )..where((t) => t.id.equals(id))).getSingleOrNull();
            if (exists != null) continue; // includes deleted tombstones
            final start = d.startMin + s.startMinOfDay, end = start + s.durMin;
            if (occupied.any((o) => o.$1 < end && o.$2 > start)) continue;
            await _db
                .into(_db.blocks)
                .insert(
                  BlocksCompanion.insert(
                    id: id,
                    startMin: start,
                    durMin: s.durMin,
                    emoji: Value(s.emoji),
                    activityId: Value(s.activityId),
                    note: Value(s.note),
                    seriesId: Value(s.id),
                    hlc: _clock.now(),
                  ),
                );
            occupied.add((start, end));
          }
        }
      });
}
