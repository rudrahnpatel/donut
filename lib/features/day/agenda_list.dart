import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';

enum AgendaAction { editTime, activity, label, repeat, delete }

/// The day's entries as a list: precise edits, plus the keyboard and screen
/// reader path to everything the dial gestures do. Swipe an entry left to
/// reveal Delete.
class AgendaList extends StatelessWidget {
  const AgendaList({
    super.key,
    required this.day,
    required this.blocks,
    required this.activities,
    required this.todosByBlock,
    required this.colorOf,
    required this.selectedId,
    required this.use24h,
    required this.onSelect,
    required this.onAction,
    this.hint = 'Drag along a ring to plan a block.',
  });

  final Day day;
  final List<PlanBlock> blocks;
  final Map<String, ActivityRow> activities;
  final Map<String, List<TodoRow>> todosByBlock;
  final Color Function(PlanBlock) colorOf;
  final String? selectedId;
  final bool use24h;
  final void Function(String id) onSelect;
  final void Function(PlanBlock block, AgendaAction action) onAction;

  /// Shown when the day is empty.
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (blocks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Icon(Icons.gesture_rounded, size: 40, color: scheme.outline),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }
    return SlidableAutoCloseBehavior(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        children: [
          for (final b in blocks)
            _AgendaTile(
              key: ValueKey(b.id),
              block: b,
              day: day,
              color: colorOf(b),
              activity: activities[b.activityId],
              todos: todosByBlock[b.id] ?? const [],
              selected: b.id == selectedId,
              use24h: use24h,
              onTap: () => onSelect(b.id),
              onAction: (a) => onAction(b, a),
            ),
        ],
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({
    super.key,
    required this.block,
    required this.day,
    required this.color,
    required this.activity,
    required this.todos,
    required this.selected,
    required this.use24h,
    required this.onTap,
    required this.onAction,
  });

  final PlanBlock block;
  final Day day;
  final Color color;
  final ActivityRow? activity;
  final List<TodoRow> todos;
  final bool selected;
  final bool use24h;
  final VoidCallback onTap;
  final void Function(AgendaAction) onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final s = block.startMin - day.startMin;
    final e = block.endMin - day.startMin;
    final times =
        '${formatClock(s, use24h: use24h)} – ${formatClock(e, use24h: use24h)}';
    // Unnamed entries are fine: their times become the title.
    final title = block.titleWith(activity?.name);
    final details = [
      if (title != null) times,
      if (block.note != null && activity != null) activity!.name,
      formatDuration(block.durMin),
    ].join(' · ');
    final spill = spillLabel(block, day);
    final status = switch (block.status) {
      BlockStatus.saved => null,
      BlockStatus.pending || BlockStatus.draft => ('Draft', scheme.outline),
      BlockStatus.conflict => ('Changed elsewhere', scheme.error),
    };

    final card = Card(
      color: selected ? scheme.secondaryContainer : null,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: activity != null
                    ? Text(
                        activity!.emoji,
                        style: emojiStyle.copyWith(fontSize: 22),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? times,
                      style: t.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      details,
                      style: t.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (status != null ||
                        spill != null ||
                        block.seriesId != null ||
                        todos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (status != null) _Tag(status.$1, status.$2),
                            if (spill != null) _Tag(spill, scheme.secondary),
                            if (block.seriesId != null)
                              _Tag('🔁 repeats', scheme.secondary),
                            for (final td in todos)
                              _Tag(
                                '${td.done ? '☑' : '☐'} ${td.title}',
                                scheme.primary,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<AgendaAction>(
                tooltip: 'Entry actions',
                onSelected: onAction,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: AgendaAction.editTime,
                    child: Text('Edit time'),
                  ),
                  PopupMenuItem(
                    value: AgendaAction.label,
                    child: Text('Label…'),
                  ),
                  PopupMenuItem(
                    value: AgendaAction.activity,
                    child: Text('Task…'),
                  ),
                  PopupMenuItem(
                    value: AgendaAction.repeat,
                    child: Text('Repeat…'),
                  ),
                  PopupMenuItem(
                    value: AgendaAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Slidable(
        key: ValueKey('slide-${block.id}'),
        groupTag: 'agenda',
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: (_) => onAction(AgendaAction.delete),
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              borderRadius: BorderRadius.circular(24),
            ),
          ],
        ),
        child: card,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

/// Short label for a block's day relation, e.g. "→ Tue" or "from Mon".
String? spillLabel(PlanBlock b, Day day) {
  final fmt = DateFormat.E();
  if (b.startMin < day.startMin) {
    return 'from ${fmt.format(Day.containing(b.startMin).toLocalDateTime())}';
  }
  if (b.endMin > day.endMin) {
    return '→ ${fmt.format(Day.containing(b.endMin - 1).toLocalDateTime())}';
  }
  return null;
}
