import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';
import '../../data/repos/pin_repo.dart';
import 'plan_mode.dart';

/// One entry's move when running late.
class LateShift {
  const LateShift({
    required this.id,
    required this.oldStart,
    required this.oldEnd,
    required this.newStart,
    required this.newEnd,
  });

  final String id;
  final int oldStart;
  final int oldEnd;
  final int newStart;
  final int newEnd;

  @override
  bool operator ==(Object other) =>
      other is LateShift &&
      other.id == id &&
      other.oldStart == oldStart &&
      other.oldEnd == oldEnd &&
      other.newStart == newStart &&
      other.newEnd == newEnd;

  @override
  int get hashCode => Object.hash(id, oldStart, oldEnd, newStart, newEnd);

  @override
  String toString() => '$id $oldStart–$oldEnd → $newStart–$newEnd';
}

/// How [entries] (absolute minutes) move when you're [delay] minutes late
/// at [now]. Entries under way run [delay] longer. Later entries move only
/// as far as they must to stay clear of what moved before them, so the
/// first gap absorbs the delay and the rest of the day stays put; with
/// [everything], every later entry moves by the full [delay].
List<LateShift> shiftForLate(
  List<({String id, int start, int end})> entries, {
  required int now,
  required int delay,
  bool everything = false,
}) {
  if (delay <= 0) return const [];
  final ahead = [
    for (final e in entries)
      if (e.end > now) e,
  ]..sort((a, b) => a.start.compareTo(b.start));
  final out = <LateShift>[];
  var carry = delay;
  // Where the plan was already busy until, before any move.
  var busyUntil = now;
  for (final e in ahead) {
    if (e.start <= now) {
      out.add(
        LateShift(
          id: e.id,
          oldStart: e.start,
          oldEnd: e.end,
          newStart: e.start,
          newEnd: e.end + delay,
        ),
      );
      busyUntil = math.max(busyUntil, e.end);
      continue;
    }
    if (!everything) {
      carry = math.max(0, carry - math.max(0, e.start - busyUntil));
      if (carry == 0) break;
    }
    out.add(
      LateShift(
        id: e.id,
        oldStart: e.start,
        oldEnd: e.end,
        newStart: e.start + carry,
        newEnd: e.end + carry,
      ),
    );
    busyUntil = math.max(busyUntil, e.end);
  }
  return out;
}

/// Pins a move would now miss: an entry ending after a pin it used to end
/// by ("Reach by 4:55"), or starting after one it used to start by
/// ("Leave by 4:10"). Pins themselves never move.
List<(LateShift, PinRow, bool atStart)> missedPins(
  List<LateShift> shifts,
  Iterable<PinRow> pins,
) => [
  for (final s in shifts)
    for (final p in pins)
      if (!p.deleted)
        if (s.oldEnd <= p.atMin && p.atMin < s.newEnd)
          (s, p, false)
        else if (s.oldStart <= p.atMin && p.atMin < s.newStart)
          (s, p, true),
];

/// "I'm running late": shifts today's entries ahead of now, after a
/// preview sheet, or straight away with [delay] (from a notification
/// button). Plan-mode edits become sketches; the rest save at once, with
/// Undo.
Future<void> runLate(BuildContext context, WidgetRef ref, {int? delay}) async {
  final today = ref.read(todayProvider);
  final plan = await ref.read(dayPlanProvider(today).future);
  final pins = await ref.read(dayPinsProvider(today).future);
  final now = nowAbsMinute();
  final entries = [
    for (final b in plan.blocks) (id: b.id, start: b.startMin, end: b.endMin),
  ];
  final byId = {for (final b in plan.blocks) b.id: b};
  final activities = ref.read(activityMapProvider);
  final use24h = ref.read(settingsProvider).use24h;
  String titleOf(String id) {
    final b = byId[id]!;
    return b.titleWith(activities[b.activityId]?.name) ??
        formatClock(minuteOfDay(b.startMin), use24h: use24h);
  }

  if (!context.mounted) return;
  final List<LateShift> shifts;
  if (delay != null) {
    shifts = shiftForLate(entries, now: now, delay: delay);
  } else {
    final picked = await showModalBottomSheet<List<LateShift>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RunningLateSheet(
        entries: entries,
        pins: pins,
        now: now,
        titleOf: titleOf,
        use24h: use24h,
      ),
    );
    if (picked == null) return;
    shifts = picked;
  }
  if (shifts.isEmpty) {
    if (context.mounted) {
      _snack(context, 'Nothing is in the way; your plan already fits');
    }
    return;
  }

  final repo = ref.read(blockRepoProvider);
  final sketching = ref.read(planningProvider);
  Future<void> move(String id, int start, int end) {
    PlanBlock change(PlanBlock b) =>
        b.copyWith(startMin: start, durMin: end - start);
    final b = byId[id];
    return sketching || (b != null && b.status != BlockStatus.saved)
        ? repo.update(id, change)
        : repo.updateSaved(id, change);
  }

  for (final s in shifts) {
    await move(s.id, s.newStart, s.newEnd);
  }
  HapticFeedback.mediumImpact();
  final missed = missedPins(shifts, pins);
  if (!context.mounted) return;
  _snack(
    context,
    [
      'Moved ${shifts.length} ${shifts.length == 1 ? 'entry' : 'entries'} '
          'later',
      if (missed.isNotEmpty)
        '⚠ misses ${missed.first.$2.describe(use24h: use24h)}',
    ].join(' · '),
    undo: () async {
      for (final s in shifts) {
        await move(s.id, s.oldStart, s.oldEnd);
      }
    },
  );
}

void _snack(BuildContext context, String text, {VoidCallback? undo}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: undo == null
            ? null
            : SnackBarAction(label: 'Undo', onPressed: undo),
        persist: false,
        duration: const Duration(seconds: 4),
      ),
    );
}

class _RunningLateSheet extends StatefulWidget {
  const _RunningLateSheet({
    required this.entries,
    required this.pins,
    required this.now,
    required this.titleOf,
    required this.use24h,
  });

  final List<({String id, int start, int end})> entries;
  final List<PinRow> pins;
  final int now;
  final String Function(String id) titleOf;
  final bool use24h;

  @override
  State<_RunningLateSheet> createState() => _RunningLateSheetState();
}

class _RunningLateSheetState extends State<_RunningLateSheet> {
  var _delay = 10;
  var _everything = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final shifts = shiftForLate(
      widget.entries,
      now: widget.now,
      delay: _delay,
      everything: _everything,
    );
    final missed = missedPins(shifts, widget.pins);
    String clock(int abs) =>
        formatClock(minuteOfDay(abs), use24h: widget.use24h);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Running late?',
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              "Pins stay put. Everything else in the way moves.",
              style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final d in const [5, 10, 15, 20, 30])
                  ChoiceChip(
                    label: Text('$d min'),
                    selected: _delay == d,
                    onSelected: (_) => setState(() => _delay = d),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Move everything after now'),
              subtitle: Text(
                _everything
                    ? 'The whole rest of today moves'
                    : 'Only until a gap absorbs the delay',
              ),
              value: _everything,
              onChanged: (v) => setState(() => _everything = v),
            ),
            const Divider(),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: shifts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nothing is in the way; your plan already fits.',
                        style: t.bodyMedium,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final s in shifts)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(widget.titleOf(s.id)),
                            subtitle: Text(
                              '${clock(s.oldStart)} – ${clock(s.oldEnd)}  →  '
                              '${clock(s.newStart)} – ${clock(s.newEnd)}',
                            ),
                          ),
                        for (final (s, p, atStart) in missed)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.warning_amber_rounded,
                              color: scheme.error,
                            ),
                            title: Text(
                              '${widget.titleOf(s.id)} would '
                              '${atStart ? 'start ${clock(s.newStart)}' : 'end ${clock(s.newEnd)}'}',
                              style: TextStyle(color: scheme.error),
                            ),
                            subtitle: Text(
                              'after ${p.pinKind.glyph} '
                              '${p.describe(use24h: widget.use24h)}',
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              onPressed: shifts.isEmpty
                  ? null
                  : () => Navigator.pop(context, shifts),
              child: Text(
                'Move ${shifts.length} '
                '${shifts.length == 1 ? 'entry' : 'entries'}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
