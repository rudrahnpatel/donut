import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';
import '../../data/repos/plan_tools_repo.dart';

/// The entries running back to back from [first] in [blocks]: the chain
/// "Save as chain" offers.
List<PlanBlock> backToBackFrom(PlanBlock first, Iterable<PlanBlock> blocks) {
  final sorted = [...blocks]..sort((a, b) => a.startMin.compareTo(b.startMin));
  final run = [first];
  for (final b in sorted) {
    if (b.id == first.id || b.startMin < first.startMin) continue;
    if ((b.startMin - run.last.endMin).abs() <= 1) run.add(b);
    if (b.startMin > run.last.endMin + 1) break;
  }
  return run;
}

/// "Save as chain": the entry and the ones back to back after it become a
/// reusable chain.
Future<void> saveChainFrom(
  BuildContext context,
  WidgetRef ref,
  PlanBlock first,
  Iterable<PlanBlock> dayBlocks,
) async {
  final activities = ref.read(activityMapProvider);
  final run = backToBackFrom(first, dayBlocks);
  String titleOf(PlanBlock b) =>
      b.titleWith(activities[b.activityId]?.name) ?? formatDuration(b.durMin);
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SaveChainSheet(run: run, titleOf: titleOf),
  );
  if ((saved ?? false) && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Chain saved. Use it from a pin or the ✨ menu'),
        ),
      );
  }
}

class _SaveChainSheet extends ConsumerStatefulWidget {
  const _SaveChainSheet({required this.run, required this.titleOf});

  final List<PlanBlock> run;
  final String Function(PlanBlock) titleOf;

  @override
  ConsumerState<_SaveChainSheet> createState() => _SaveChainSheetState();
}

class _SaveChainSheetState extends ConsumerState<_SaveChainSheet> {
  late final _name = TextEditingController(
    text: widget.run.length == 1
        ? widget.titleOf(widget.run.first)
        : '${widget.titleOf(widget.run.first)} → '
              '${widget.titleOf(widget.run.last)}',
  );
  late final _on = List.filled(widget.run.length, true);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final steps = [
      for (var i = 0; i < widget.run.length; i++)
        if (_on[i]) widget.run[i],
    ];
    final total = steps.fold(0, (sum, b) => sum + b.durMin);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save as chain',
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Steps back to back, ${formatDuration(total)} in all. Place it '
              'later from a pin or the ✨ menu.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Commute',
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < widget.run.length; i++)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _on[i],
                onChanged: i == 0
                    ? null
                    : (v) => setState(() => _on[i] = v ?? false),
                title: Text(widget.titleOf(widget.run[i])),
                subtitle: Text(formatDuration(widget.run[i].durMin)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty) return;
                await ref.read(planToolsRepoProvider).saveChain(name, [
                  for (final b in steps)
                    ChainStep(
                      b.durMin,
                      note: b.note,
                      activityId: b.activityId,
                      emoji: b.emoji,
                      color: b.color,
                    ),
                ]);
                HapticFeedback.lightImpact();
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text(
                'Save ${steps.length} ${steps.length == 1 ? 'step' : 'steps'}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks a saved chain (and lets you delete ones you no longer use).
Future<ChainRow?> pickChain(
  BuildContext context,
  WidgetRef ref, {
  required String title,
}) => showModalBottomSheet<ChainRow>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => Consumer(
    builder: (context, ref, _) {
      final chains = ref.watch(chainsProvider).value ?? const <ChainRow>[];
      final activities = ref.watch(activityMapProvider);
      final t = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (chains.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No chains yet. In the day list, open ⋮ on the first of '
                    'some back-to-back entries → Save as chain.',
                    style: t.bodyMedium,
                  ),
                ),
              for (final c in chains)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link_rounded),
                  title: Text(c.name),
                  subtitle: Text(
                    '${c.steps.map((s) => s.note ?? activities[s.activityId]?.name ?? formatDuration(s.dur)).join(' → ')}'
                    ' · ${formatDuration(c.length)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete chain',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () =>
                        ref.read(planToolsRepoProvider).deleteChain(c.id),
                  ),
                  onTap: () => Navigator.pop(context, c),
                ),
            ],
          ),
        ),
      );
    },
  ),
);

/// Lays [chain] out from [startMin] as sketches and says so.
Future<void> placeChain(
  BuildContext context,
  WidgetRef ref,
  ChainRow chain,
  int startMin,
) async {
  final n = await ref.read(planToolsRepoProvider).applyChain(chain, startMin);
  HapticFeedback.mediumImpact();
  if (!context.mounted) return;
  final use24h = ref.read(settingsProvider).use24h;
  String clock(int abs) => formatClock(minuteOfDay(abs), use24h: use24h);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '${chain.name}: $n ${n == 1 ? 'step' : 'steps'}, '
          '${clock(startMin)} – ${clock(startMin + chain.length)}. '
          '✓ keeps them',
        ),
      ),
    );
}
