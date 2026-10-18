import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../app/theme/theme.dart';
import '../../core/time/day_minutes.dart';
import '../../data/repos/block_repo.dart';
import 'mini_donut_painter.dart';

final _monthProvider = NotifierProvider<_MonthNotifier, Day>(
  _MonthNotifier.new,
);

class _MonthNotifier extends Notifier<Day> {
  @override
  Day build() => Day.today().firstOfMonth;

  void shift(int months) {
    final d = state.toLocalDateTime();
    state = Day(d.year, d.month + months, 1);
  }

  void set(Day d) => state = d.firstOfMonth;
}

/// Blocks (saved + unsaved) for the grid's visible weeks.
final _monthBlocksProvider = StreamProvider.family<List<PlanBlock>, Day>((
  ref,
  first,
) {
  final gridStart = first.addDays(-(first.weekday - 1));
  return ref
      .watch(blockRepoProvider)
      .watchEffectiveInRange(
        gridStart.startMin,
        gridStart.addDays(42).startMin,
      );
});

/// Month grid where every day is a tiny donut of its plan.
class MonthScreen extends ConsumerWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = ref.watch(_monthProvider);
    final today = ref.watch(todayProvider);
    final blocks =
        ref.watch(_monthBlocksProvider(first)).value ?? const <PlanBlock>[];
    final activities = ref.watch(activityMapProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    final gridStart = first.addDays(-(first.weekday - 1));
    final weeks = ((first.weekday - 1 + first.daysInMonth) / 7).ceil();

    List<MiniArc> arcsFor(Day d) => [
      for (final b in blocks)
        if (b.overlaps(d.startMin, d.endMin))
          MiniArc(
            b.startMin - d.startMin,
            b.endMin - d.startMin,
            activities[b.activityId] != null
                ? blockColor(activities[b.activityId]!.color, brightness)
                : scheme.primary,
            draft: b.status != BlockStatus.saved,
          ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: () =>
                        ref.read(_monthProvider.notifier).shift(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMM().format(first.toLocalDateTime()),
                      textAlign: TextAlign.center,
                      style: t.titleLarge,
                    ),
                  ),
                  if (first != today.firstOfMonth)
                    TextButton(
                      onPressed: () =>
                          ref.read(_monthProvider.notifier).set(today),
                      child: const Text('Today'),
                    ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: () => ref.read(_monthProvider.notifier).shift(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (final n in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                    Expanded(
                      child: Center(
                        child: Text(
                          n,
                          style: t.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() > 300) {
                    ref.read(_monthProvider.notifier).shift(v < 0 ? 1 : -1);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (var w = 0; w < weeks; w++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var i = 0; i < 7; i++)
                                Expanded(
                                  child: _DayCell(
                                    day: gridStart.addDays(w * 7 + i),
                                    inMonth:
                                        gridStart.addDays(w * 7 + i).month ==
                                        first.month,
                                    isToday:
                                        gridStart.addDays(w * 7 + i) == today,
                                    arcs: arcsFor(gridStart.addDays(w * 7 + i)),
                                    onTap: () {
                                      ref
                                          .read(focusedDayProvider.notifier)
                                          .set(gridStart.addDays(w * 7 + i));
                                      ref
                                          .read(shellTabProvider.notifier)
                                          .set(0);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.arcs,
    required this.onTap,
  });

  final Day day;
  final bool inMonth;
  final bool isToday;
  final List<MiniArc> arcs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isToday ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: inMonth ? 1 : 0.4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: CustomPaint(
                      painter: MiniDonutPainter(
                        arcs: arcs,
                        track: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isToday
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
