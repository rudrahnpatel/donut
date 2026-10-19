import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';
import '../../data/repos/pin_repo.dart';

enum AgendaAction { editTime, activity, label, repeat, saveChain, delete }

enum PinAction { fitBefore, startHere, editTime, delete }

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
    this.pins = const [],
    this.onPinAction,
    this.header,
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

  /// Shown above the entries (the day's worked time).
  final Widget? header;

  /// The day's pins, listed among the entries by time.
  final List<PinRow> pins;
  final void Function(PinRow pin, PinAction action)? onPinAction;

  /// Shown when the day is empty.
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (blocks.isEmpty && pins.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ?header,
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
        children: [?header, ..._byTime()],
      ),
    );
  }

  /// Entries and pins in time order (both arrive sorted); a pin goes
  /// before an entry starting at the same minute ("Leave by 4:10", then
  /// the 4:10 entry).
  List<Widget> _byTime() {
    Widget pinTile(PinRow p) => _PinTile(
      key: ValueKey('pin-${p.id}'),
      pin: p,
      use24h: use24h,
      onAction: (a) => onPinAction?.call(p, a),
    );
    final out = <Widget>[];
    var i = 0;
    for (final b in blocks) {
      while (i < pins.length && pins[i].atMin <= b.startMin) {
        out.add(pinTile(pins[i++]));
      }
      out.add(
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
      );
    }
    while (i < pins.length) {
      out.add(pinTile(pins[i++]));
    }
    return out;
  }
}

/// A pin's row: smaller than an entry's, since a pin is a moment.
class _PinTile extends StatelessWidget {
  const _PinTile({
    super.key,
    required this.pin,
    required this.use24h,
    required this.onAction,
  });

  final PinRow pin;
  final bool use24h;
  final void Function(PinAction) onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final left = pin.atMin - nowAbsMinute();
    final card = Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.onSurface, width: 2),
              ),
              child: Text(
                pin.pinKind.glyph,
                style: emojiStyle.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                pin.describe(use24h: use24h),
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (pin.draft)
              _Tag('Draft', scheme.outline)
            else if (left > 0 && left <= 12 * 60)
              Text(
                'in ${formatDuration(left)}',
                style: t.labelMedium?.copyWith(color: scheme.tertiary),
              ),
            PopupMenuButton<PinAction>(
              tooltip: 'Pin actions',
              onSelected: onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: PinAction.fitBefore,
                  child: Text('Fit a chain before…'),
                ),
                PopupMenuItem(
                  value: PinAction.startHere,
                  child: Text('Start a chain here…'),
                ),
                PopupMenuItem(
                  value: PinAction.editTime,
                  child: Text('Edit time'),
                ),
                PopupMenuItem(value: PinAction.delete, child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Slidable(
        key: ValueKey('slide-pin-${pin.id}'),
        groupTag: 'agenda',
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: (_) => onAction(PinAction.delete),
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
                    value: AgendaAction.saveChain,
                    child: Text('Save as chain…'),
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
