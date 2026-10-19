import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/time/day_minutes.dart';
import '../../data/repos/block_repo.dart';
import '../../data/repos/plan_tools_repo.dart';
import '../day/pickers.dart';
import '../day/running_late.dart';

enum _DayAction { runningLate, copyYesterday, applyTemplate, saveTemplate }

/// Overflow menu on the day header: templates and "copy yesterday".
class DayMenuButton extends ConsumerWidget {
  const DayMenuButton({super.key, required this.day});

  final Day day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.read(planToolsRepoProvider);

    void snack(String text) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    String added(int n) => n == 0
        ? 'Nothing added: those slots are already taken'
        : 'Added $n ${n == 1 ? 'entry' : 'entries'} to a plan. ✓ keeps them';

    return PopupMenuButton<_DayAction>(
      tooltip: 'Day actions',
      icon: const Icon(Icons.auto_awesome_rounded),
      onSelected: (a) async {
        switch (a) {
          case _DayAction.runningLate:
            await runLate(context, ref);
          case _DayAction.copyYesterday:
            snack(added(await tools.copyFrom(day.addDays(-1), day)));
          case _DayAction.applyTemplate:
            final templates = ref.read(templatesProvider).value ?? const [];
            if (templates.isEmpty) {
              snack('No templates yet — save a day as one first');
              return;
            }
            final chosen = await showModalBottomSheet<String>(
              context: context,
              builder: (ctx) => SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in templates)
                      ListTile(
                        leading: const Icon(Icons.dashboard_customize_rounded),
                        title: Text(t.name),
                        onTap: () => Navigator.pop(ctx, t.id),
                      ),
                  ],
                ),
              ),
            );
            final t = templates.where((t) => t.id == chosen).firstOrNull;
            if (t != null) snack(added(await tools.applyTemplate(t, day)));
          case _DayAction.saveTemplate:
            final name = await promptText(
              context,
              title: 'Template name',
              hint: 'e.g. Workday',
            );
            if (name == null || name.trim().isEmpty) return;
            await tools.saveDayAsTemplate(name.trim(), day);
            snack('Saved template “${name.trim()}”');
        }
      },
      itemBuilder: (_) => [
        if (day == ref.read(todayProvider))
          const PopupMenuItem(
            value: _DayAction.runningLate,
            child: ListTile(
              leading: Icon(Icons.running_with_errors_rounded),
              title: Text('Running late…'),
            ),
          ),
        const PopupMenuItem(
          value: _DayAction.copyYesterday,
          child: ListTile(
            leading: Icon(Icons.content_copy_rounded),
            title: Text('Copy yesterday'),
          ),
        ),
        const PopupMenuItem(
          value: _DayAction.applyTemplate,
          child: ListTile(
            leading: Icon(Icons.dashboard_customize_rounded),
            title: Text('Apply template…'),
          ),
        ),
        const PopupMenuItem(
          value: _DayAction.saveTemplate,
          child: ListTile(
            leading: Icon(Icons.bookmark_add_rounded),
            title: Text('Save day as template…'),
          ),
        ),
      ],
    );
  }
}

/// Turns a block's time slot into a recurring series.
Future<void> showRepeatSheet(
  BuildContext context,
  WidgetRef ref,
  PlanBlock block,
) async {
  final day = Day.containing(block.startMin);
  final picked = await showModalBottomSheet<RepeatRule>(
    context: context,
    builder: (ctx) => _RepeatPicker(initialWeekday: day.weekday),
  );
  if (picked == null) return;
  await ref
      .read(planToolsRepoProvider)
      .createSeries(
        rule: picked,
        from: day,
        startMinOfDay: block.startMin - day.startMin,
        durMin: block.durMin,
        emoji: block.emoji,
        activityId: block.activityId,
        note: block.note,
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Repeats ${picked.describe().toLowerCase()} 🔁')),
    );
  }
}

class _RepeatPicker extends StatefulWidget {
  const _RepeatPicker({required this.initialWeekday});

  final int initialWeekday;

  @override
  State<_RepeatPicker> createState() => _RepeatPickerState();
}

class _RepeatPickerState extends State<_RepeatPicker> {
  late Set<int> _days = {widget.initialWeekday};

  @override
  Widget build(BuildContext context) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Repeat this block',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Every day'),
                  onPressed: () =>
                      setState(() => _days = {1, 2, 3, 4, 5, 6, 7}),
                ),
                ActionChip(
                  label: const Text('Weekdays'),
                  onPressed: () => setState(() => _days = {1, 2, 3, 4, 5}),
                ),
                ActionChip(
                  label: const Text('Weekends'),
                  onPressed: () => setState(() => _days = {6, 7}),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(names[d - 1]),
                    showCheckmark: false,
                    selected: _days.contains(d),
                    onSelected: (on) => setState(() {
                      _days = {..._days};
                      on ? _days.add(d) : _days.remove(d);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _days.isEmpty
                  ? null
                  : () => Navigator.pop(
                      context,
                      _days.length == 7
                          ? const RepeatRule.daily()
                          : RepeatRule.weekly(_days),
                    ),
              child: const Text('Repeat'),
            ),
          ],
        ),
      ),
    );
  }
}
