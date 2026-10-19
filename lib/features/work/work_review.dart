import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/work_repo.dart';

/// "💻 Worked 3h 12m" with time per project, for the top of the day list.
class WorkedCard extends StatelessWidget {
  const WorkedCard({
    super.key,
    required this.minutes,
    required this.projects,
    required this.onTap,
  });

  final int minutes;

  /// Project → seconds, biggest first.
  final List<(String, int)> projects;
  final VoidCallback onTap;

  static const green = Color(0xFF3DDC84);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.laptop_chromebook_rounded, color: green),
                  const SizedBox(width: 10),
                  Text(
                    'Worked ${formatDuration(minutes)}',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (projects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (name, seconds) in projects.take(6))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$name · ${formatDuration((seconds / 60).round())}',
                          style: t.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Project → seconds across [sessions], biggest first.
List<(String, int)> projectTotals(Iterable<WorkSessionRow> sessions) {
  final totals = <String, int>{};
  for (final s in sessions) {
    for (final MapEntry(:key, :value) in s.projects.entries) {
      totals[key] = (totals[key] ?? 0) + value;
    }
  }
  return [for (final e in totals.entries) (e.key, e.value)]
    ..sort((a, b) => b.$2.compareTo(a.$2));
}

/// The day's worked sessions, each with "Not work" to drop it (say, time
/// on a personal project). Dropping syncs and sticks.
Future<void> showWorkReview(
  BuildContext context,
  Day day,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => Consumer(
    builder: (context, ref, _) {
      final t = Theme.of(context).textTheme;
      final use24h = ref.watch(settingsProvider).use24h;
      final sessions = [
        for (final s
            in ref.watch(dayWorkProvider(day)).value ??
                const <WorkSessionRow>[])
          if (s.startMin >= day.startMin && s.startMin < day.endMin) s,
      ];
      String clock(int abs) => formatClock(minuteOfDay(abs), use24h: use24h);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Worked ${formatDuration(workedMinutes(sessions, day.startMin, day.endMin))}',
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Measured on your desktop. Drop anything that was not '
                'work, like a personal project.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (sessions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Nothing left for this day.'),
                      ),
                    for (final s in sessions.reversed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${clock(s.startMin)} – ${clock(s.endMin)} · '
                          '${formatDuration(s.endMin - s.startMin)}',
                        ),
                        subtitle: Text(
                          [
                            ...projectTotals([s]).map((p) => p.$1),
                            if (s.manual) 'manual',
                            if (s.source == 'claude-logs')
                              'estimated from Claude Code',
                          ].join(' · '),
                        ),
                        trailing: TextButton(
                          onPressed: () =>
                              ref.read(workRepoProvider).exclude(s.id),
                          child: const Text('Not work'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
);
