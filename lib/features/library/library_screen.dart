import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/plan_tools_repo.dart';
import '../day/pickers.dart';

const activityPalette = entryPalette;

/// Activities, to-dos, repeating blocks and templates.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Activities'),
            Tab(text: 'To-dos'),
            Tab(text: 'Repeating'),
            Tab(text: 'Templates'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _ActivitiesTab(),
          _TodosTab(),
          _SeriesTab(),
          _TemplatesTab(),
        ],
      ),
    ),
  );
}

// ── activities ─────────────────────────────────────────────────────────────

class _ActivitiesTab extends ConsumerWidget {
  const _ActivitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(activitiesProvider).value ?? const <ActivityRow>[];
    final lib = ref.read(libraryRepoProvider);
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editActivity(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Activity'),
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        onReorderItem: (from, to) {
          final ids = [for (final a in list) a.id];
          ids.insert(to, ids.removeAt(from));
          lib.reorderActivities(ids);
        },
        children: [
          for (final a in list)
            Card(
              key: ValueKey(a.id),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: blockColor(a.color, brightness),
                  child: Text(
                    a.emoji,
                    style: emojiStyle.copyWith(fontSize: 20),
                  ),
                ),
                title: Text(a.name),
                subtitle: a.pinned
                    ? const Text('Pinned to the quick menu')
                    : null,
                onTap: () => editActivity(context, ref, a),
                trailing: IconButton(
                  tooltip: a.pinned ? 'Unpin' : 'Pin to quick menu',
                  icon: Icon(
                    a.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  ),
                  onPressed: () => lib.updateActivity(a.id, pinned: !a.pinned),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> editActivity(
  BuildContext context,
  WidgetRef ref,
  ActivityRow? a,
) async {
  final lib = ref.read(libraryRepoProvider);
  final result = await showModalBottomSheet<_ActivityDraft>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ActivityEditor(initial: a),
  );
  if (result == null) return;
  if (result.delete && a != null) {
    await lib.deleteActivity(a.id);
  } else if (a == null) {
    await lib.addActivity(result.name, result.emoji, result.color);
  } else {
    await lib.updateActivity(
      a.id,
      name: result.name,
      emoji: result.emoji,
      color: result.color,
    );
  }
}

class _ActivityDraft {
  const _ActivityDraft(
    this.name,
    this.emoji,
    this.color, {
    this.delete = false,
  });
  final String name;
  final String emoji;
  final int color;
  final bool delete;
}

class _ActivityEditor extends StatefulWidget {
  const _ActivityEditor({this.initial});

  final ActivityRow? initial;

  @override
  State<_ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<_ActivityEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late String _emoji = widget.initial?.emoji ?? '⭐';
  late int _color = widget.initial?.color ?? activityPalette.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  final e = await pickEmoji(context);
                  if (e != null) setState(() => _emoji = e);
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: blockColor(_color, brightness),
                  child: Text(_emoji, style: emojiStyle.copyWith(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: widget.initial == null,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in activityPalette)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: blockColor(c, brightness),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: _color == c ? 3 : 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.initial != null)
                TextButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    _ActivityDraft('', '', 0, delete: true),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final name = _name.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(context, _ActivityDraft(name, _emoji, _color));
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── to-dos ─────────────────────────────────────────────────────────────────

class _TodosTab extends ConsumerWidget {
  const _TodosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(allTodosProvider).value ?? const <TodoRow>[];
    final activities =
        ref.watch(activitiesProvider).value ?? const <ActivityRow>[];
    final lib = ref.read(libraryRepoProvider);
    final scheme = Theme.of(context).colorScheme;

    final groups = <String?, List<TodoRow>>{};
    for (final t in todos) {
      (groups[t.activityId] ??= []).add(t);
    }
    final names = {for (final a in activities) a.id: '${a.emoji}  ${a.name}'};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final title = await promptText(
            context,
            title: 'New to-do',
            hint: 'e.g. Chapter 4 notes',
          );
          if (title == null || title.trim().isEmpty || !context.mounted) return;
          final activity = await pickActivity(context);
          await lib.addTodo(title.trim(), activityId: activity);
        },
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('To-do'),
      ),
      body: todos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'To-dos live under an activity. Hold a block, go to Tasks → '
                  'an activity, and its open to-dos fan out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      names[entry.key] ?? 'No activity',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final t in entry.value)
                    Dismissible(
                      key: ValueKey(t.id),
                      onDismissed: (_) => lib.deleteTodo(t.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: scheme.errorContainer,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: t.done,
                        onChanged: (v) =>
                            lib.updateTodo(t.id, done: v ?? false),
                        title: Text(
                          t.title,
                          style: t.done
                              ? const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                )
                              : null,
                        ),
                        subtitle: t.blockId != null
                            ? const Text('Scheduled')
                            : null,
                        secondary: t.blockId != null
                            ? IconButton(
                                tooltip: 'Unschedule',
                                icon: const Icon(Icons.event_busy_rounded),
                                onPressed: () => lib.updateTodo(
                                  t.id,
                                  blockId: const Value(null),
                                ),
                              )
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

// ── repeating ──────────────────────────────────────────────────────────────

class _SeriesTab extends ConsumerWidget {
  const _SeriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(seriesProvider).value ?? const <SeriesRow>[];
    final activities = ref.watch(activityMapProvider);
    final use24h = ref.watch(settingsProvider).use24h;
    final scheme = Theme.of(context).colorScheme;
    if (series.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Nothing repeats yet. In the agenda, open a block\'s menu → Repeat…',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final s in series)
          Card(
            child: ListTile(
              leading: Text(
                s.emoji ?? activities[s.activityId]?.emoji ?? '🔁',
                style: emojiStyle.copyWith(fontSize: 26),
              ),
              title: Text(
                activities[s.activityId]?.name ?? s.note ?? 'Repeating block',
              ),
              subtitle: Text(
                '${RepeatRule.parse(s.rule).describe()} · '
                '${formatClock(s.startMinOfDay, use24h: use24h)} – '
                '${formatClock(s.startMinOfDay + s.durMin, use24h: use24h)}',
              ),
              trailing: IconButton(
                tooltip: 'Stop repeating',
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: () => ref
                    .read(planToolsRepoProvider)
                    .endSeries(s.id, after: Day.today().addDays(1)),
              ),
            ),
          ),
      ],
    );
  }
}

// ── templates ──────────────────────────────────────────────────────────────

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates =
        ref.watch(templatesProvider).value ?? const <TemplateRow>[];
    final scheme = Theme.of(context).colorScheme;
    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Plan a typical day, then use ✨ → Save day as template.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final t in templates)
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard_customize_rounded),
              title: Text(t.name),
              trailing: IconButton(
                tooltip: 'Delete template',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () =>
                    ref.read(planToolsRepoProvider).deleteTemplate(t.id),
              ),
            ),
          ),
      ],
    );
  }
}
