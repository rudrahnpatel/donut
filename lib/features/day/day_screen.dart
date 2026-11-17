import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';
import '../../data/repos/pin_repo.dart';
import '../../data/repos/plan_tools_repo.dart';
import '../../data/repos/work_repo.dart';
import '../../data/repos/settings_repo.dart';
import '../clock/clock_painter.dart';
import '../clock/clock_view.dart';
import '../clock/spiral_math.dart';
import '../radial_menu/marking_menu_controller.dart';
import '../sync/sync_controller.dart';
import '../templates/chains.dart';
import '../work/work_review.dart';
import '../templates/day_actions.dart';
import '../reminders/reminder_providers.dart';
import 'plan_mode.dart';
import 'running_late.dart';
import 'agenda_list.dart';
import 'dial_mode.dart';
import 'pickers.dart';

/// Swipeable days, each with its dial, action bar and agenda.
class DayScreen extends ConsumerStatefulWidget {
  const DayScreen({super.key});

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  late final PageController _pages = PageController(
    initialPage: ref.read(focusedDayProvider).epochDay,
  );
  late final _notificationAction = ref.read(reminderServiceProvider).action;

  @override
  void initState() {
    super.initState();
    _notificationAction.addListener(_onNotificationAction);
    // A button may have opened the app before this screen was built.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _onNotificationAction(),
    );
  }

  @override
  void dispose() {
    _notificationAction.removeListener(_onNotificationAction);
    _pages.dispose();
    super.dispose();
  }

  /// "+5 min late" / "+10 min late" on a countdown notification.
  void _onNotificationAction() {
    final a = _notificationAction.value;
    if (a == null || !mounted) return;
    _notificationAction.value = null;
    if (a.startsWith('late:')) {
      _toNow();
      runLate(context, ref, delay: int.parse(a.substring(5)));
    }
  }

  void _goTo(Day d) {
    final current = _pages.page?.round() ?? d.epochDay;
    if ((current - d.epochDay).abs() > 3) {
      _pages.jumpToPage(d.epochDay);
    } else {
      _pages.animateToPage(
        d.epochDay,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _toNow() {
    ref.read(focusedDayProvider.notifier).set(ref.read(todayProvider));
    ref.read(dialModeProvider.notifier).set(const DialMode.live());
  }

  Future<void> _savePlan() async {
    final ids = await ref.read(blockRepoProvider).saveAll();
    final pins = await ref.read(pinRepoProvider).commitDrafts();
    ref.read(planModeProvider.notifier).set(false);
    ref.invalidate(quickRankingProvider);
    HapticFeedback.mediumImpact();
    _snack(ids.isEmpty && pins == 0 ? 'Plan mode off' : 'Plan saved ✨');
  }

  Future<void> _discardPlan() async {
    final rows = await ref.read(blockRepoProvider).discardAll();
    final pins = await ref.read(pinRepoProvider).discardDrafts();
    ref.read(planModeProvider.notifier).set(false);
    if (rows.isEmpty && pins.isEmpty) return;
    _snack(
      'Plan discarded',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          ref.read(blockRepoProvider).restore(rows);
          ref.read(pinRepoProvider).restore(pins);
        },
      ),
    );
  }

  void _snack(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          persist: false,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Horizontal distance of the current swipe on the date.
  double _swipeDx = 0;

  void _shiftDay(int by) {
    HapticFeedback.selectionClick();
    final d = ref.read(focusedDayProvider);
    ref.read(focusedDayProvider.notifier).set(d.addDays(by));
  }

  @override
  Widget build(BuildContext context) {
    final focused = ref.watch(focusedDayProvider);
    final today = ref.watch(todayProvider);
    final mode = ref.watch(dialModeProvider);
    ref.listen(focusedDayProvider, (prev, next) {
      if (_pages.hasClients && _pages.page?.round() != next.epochDay) {
        _goTo(next);
      }
    });
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final date = focused.toLocalDateTime();
    final rel = switch (focused.epochDay - today.epochDay) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => DateFormat.EEEE().format(date),
    };
    final hourLevel = mode.level == DialLevel.hour;
    final showNow = focused != today || (hourLevel && !mode.isLive);
    final planning = ref.watch(planningProvider);
    final sketches = ref.watch(draftCountProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Plan mode's sketch paper: a faint dot grid behind everything.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: planning ? 1 : 0,
                duration: const Duration(milliseconds: 450),
                child: CustomPaint(painter: _SketchPaper(scheme.onSurface)),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Swipe anywhere on the header to change day; tap the date for a
                // calendar. A drag beats the buttons' taps once it moves.
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _swipeDx = 0,
                  onHorizontalDragUpdate: (d) => _swipeDx += d.delta.dx,
                  onHorizontalDragEnd: (d) {
                    // A flick or a deliberate drag both count.
                    final v = d.primaryVelocity ?? 0;
                    if (_swipeDx.abs() > 60 || v.abs() > 300) {
                      _shiftDay(
                        (_swipeDx.abs() > 60 ? _swipeDx : v) < 0 ? 1 : -1,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                ref
                                    .read(focusedDayProvider.notifier)
                                    .set(Day.fromDateTime(picked));
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rel, style: t.titleLarge),
                                  Text(
                                    DateFormat.yMMMMd().format(date),
                                    style: t.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (showNow)
                          TextButton.icon(
                            onPressed: _toNow,
                            icon: const Icon(
                              Icons.my_location_rounded,
                              size: 18,
                            ),
                            label: const Text('Now'),
                          ),
                        IconButton(
                          tooltip: hourLevel
                              ? 'Zoom out to the day'
                              : 'Zoom in to an hour',
                          onPressed: () => ref
                              .read(dialModeProvider.notifier)
                              .set(
                                hourLevel
                                    ? const DialMode.day()
                                    : const DialMode.live(),
                              ),
                          icon: Icon(
                            hourLevel
                                ? Icons.zoom_out_map_rounded
                                : Icons.timelapse_rounded,
                          ),
                        ),
                        if (!planning)
                          IconButton(
                            tooltip: 'Plan mode: sketch freely, then ✓ to save',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref.read(planModeProvider.notifier).set(true);
                            },
                            icon: const Icon(Icons.draw_rounded),
                          ),
                        DayMenuButton(day: focused),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: planning
                      ? _PlanBanner(
                          sketches: sketches,
                          onDiscard: _discardPlan,
                          onSave: _savePlan,
                        )
                      : const SizedBox(width: double.infinity),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    onPageChanged: (i) => ref
                        .read(focusedDayProvider.notifier)
                        .set(Day.fromEpochDay(i)),
                    itemBuilder: (_, i) => DayPage(day: Day.fromEpochDay(i)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DayPage extends ConsumerStatefulWidget {
  const DayPage({super.key, required this.day});

  final Day day;

  @override
  ConsumerState<DayPage> createState() => _DayPageState();
}

class _DayPageState extends ConsumerState<DayPage> {
  String? _selected;

  Day get day => widget.day;
  BlockRepo get _repo => ref.read(blockRepoProvider);
  int get _nowAbs => ref.read(nowMinuteProvider).value ?? nowAbsMinute();

  // ── edits ──────────────────────────────────────────────────────────────

  /// A colour for a new entry that differs from the entries it touches or
  /// overlaps, cycling through the palette so a day reads as many colours.
  int _colorFor(List<PlanBlock> existing, int start, int end) => pickEntryColor(
    [
      for (final b in existing)
        (
          start: b.startMin,
          end: b.endMin,
          color: b.color ?? fallbackEntryColor(b.id),
        ),
    ],
    start,
    end,
    seed: existing.length,
  );

  /// In plan mode edits are sketches until ✓; otherwise they save
  /// instantly. An entry that is already a sketch stays one either way.
  bool _sketching(String? id) {
    if (ref.read(planningProvider)) return true;
    final plan = ref.read(dayPlanProvider(day)).value;
    final b = plan?.blocks.where((b) => b.id == id).firstOrNull;
    return b != null && b.status != BlockStatus.saved;
  }

  Future<void> _update(String id, PlanBlock Function(PlanBlock) change) =>
      _sketching(id) ? _repo.update(id, change) : _repo.updateSaved(id, change);

  /// Draws a new entry. It is not selected, so the next drag starts a fresh
  /// entry.
  Future<void> _create(int s, int e) async {
    final plan = ref.read(dayPlanProvider(day)).value;
    final start = day.startMin + s, end = day.startMin + e;
    final color = _colorFor(plan?.blocks ?? const [], start, end);
    if (_sketching(null)) {
      await _repo.create(start, end, color: color);
    } else {
      await _repo.createSaved(start, end, color: color);
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _change(String id, int s, int e) =>
      _update(id, (b) => b.copyWith(startMin: day.startMin + s, durMin: e - s));

  Future<void> _setActivity(String id, String? activityId) =>
      _update(id, (b) => b.copyWith(activityId: activityId));

  Future<void> _setLabel(String id, String? label) {
    final clean = label?.trim();
    return _update(
      id,
      (b) => b.copyWith(note: clean == null || clean.isEmpty ? null : clean),
    );
  }

  Future<void> _delete(String id) async {
    final VoidCallback undo;
    if (_sketching(id)) {
      final u = await _repo.delete(id);
      if (u == null) return;
      undo = () => _repo.undo(u);
    } else {
      await _repo.deleteSaved(id);
      undo = () => _repo.restoreSaved(id);
    }
    setState(() => _selected = null);
    if (!mounted) return;
    _snack(
      'Entry removed',
      action: SnackBarAction(label: 'Undo', onPressed: undo),
    );
  }

  Future<void> _askLabel(String blockId) async {
    final current = (await _repo.loadDay(day)).blocks
        .where((b) => b.id == blockId)
        .firstOrNull;
    if (!mounted) return;
    final text = await promptText(
      context,
      title: 'Label',
      initial: current?.note ?? '',
      hint: 'e.g. home to stn',
    );
    if (text != null) await _setLabel(blockId, text);
  }

  Future<void> _onMenuPick(String blockId, MarkingItem item) async {
    final lib = ref.read(libraryRepoProvider);
    final colon = item.id.indexOf(':');
    final kind = item.id.substring(0, colon);
    final value = item.id.substring(colon + 1);
    switch (kind) {
      case 'activity':
        await _setActivity(blockId, value);
      case 'label':
        await _setLabel(blockId, value);
      case 'todo':
        final todo = (ref.read(allTodosProvider).value ?? const <TodoRow>[])
            .where((t) => t.id == value)
            .firstOrNull;
        if (todo == null) return;
        await _setActivity(blockId, todo.activityId);
        await lib.updateTodo(todo.id, blockId: Value(blockId));
      case 'pin':
        // `<minute>:<what>`, the minute worked out when the menu opened.
        final c = value.indexOf(':');
        await _pin(
          int.parse(value.substring(0, c)),
          what: value.substring(c + 1),
        );
      case 'group' || 'more':
        if (value == 'tasks') {
          final a = await pickActivity(context);
          if (a != null) await _setActivity(blockId, a);
        } else if (value == 'label') {
          await _askLabel(blockId);
        }
    }
  }

  /// Drops a pin at absolute minute [atMin]. [what] is a [PinKind] name,
  /// `custom` (ask for text, under [title]) or `text:<recent custom text>`.
  Future<void> _pin(
    int atMin, {
    required String what,
    String title = 'Pin',
  }) async {
    var kind = PinKind.custom;
    String? label;
    if (what == 'custom') {
      final text = await promptText(
        context,
        title: title,
        hint: 'e.g. train leaves',
      );
      label = text?.trim();
      if (label == null || label.isEmpty) return;
    } else if (what.startsWith('text:')) {
      label = what.substring(5);
    } else {
      kind = PinKind.parse(what);
    }
    await ref
        .read(pinRepoProvider)
        .create(atMin, kind, label: label, draft: _sketching(null));
    HapticFeedback.lightImpact();
  }

  Future<void> _onAgendaAction(PlanBlock b, AgendaAction a) async {
    switch (a) {
      case AgendaAction.editTime:
        final r = await pickTimeRange(
          context,
          start: b.startMin - day.startMin,
          end: b.endMin - day.startMin,
        );
        if (r == null) return;
        final base = Day.containing(b.startMin).startMin;
        await _update(
          b.id,
          (x) => x.copyWith(startMin: base + r.$1, durMin: r.$2 - r.$1),
        );
      case AgendaAction.activity:
        final id = await pickActivity(context);
        if (id != null) await _setActivity(b.id, id);
      case AgendaAction.label:
        await _askLabel(b.id);
      case AgendaAction.repeat:
        if (mounted) await showRepeatSheet(context, ref, b);
      case AgendaAction.saveChain:
        final plan = ref.read(dayPlanProvider(day)).value;
        if (plan != null && mounted) {
          await saveChainFrom(context, ref, b, plan.blocks);
        }
      case AgendaAction.delete:
        await _delete(b.id);
    }
  }

  bool get _use24h => ref.read(settingsProvider).use24h;

  Future<void> _onPinAction(PinRow p, PinAction a) async {
    final repo = ref.read(pinRepoProvider);
    switch (a) {
      case PinAction.fitBefore || PinAction.startHere:
        final before = a == PinAction.fitBefore;
        final chain = await pickChain(
          context,
          ref,
          title: before
              ? 'Fit a chain before ${p.describe(use24h: _use24h)}'
              : 'Start a chain at ${formatClock(minuteOfDay(p.atMin), use24h: _use24h)}',
        );
        if (chain == null || !mounted) return;
        await placeChain(
          context,
          ref,
          chain,
          before ? p.atMin - chain.length : p.atMin,
        );
      case PinAction.editTime:
        final minute = minuteOfDay(p.atMin);
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
        );
        if (t == null) return;
        await repo.move(
          p.id,
          Day.containing(p.atMin).startMin + t.hour * 60 + t.minute,
        );
      case PinAction.delete:
        final row = await repo.delete(p.id);
        if (row == null) return;
        _snack(
          'Pin removed',
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.restore([row]),
          ),
        );
    }
  }

  void _snack(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          persist: false,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ── navigation between hours and days ──────────────────────────────────

  void _setMode(DialMode m, {Day? focus}) {
    ref.read(dialModeProvider.notifier).set(m);
    if (focus != null) ref.read(focusedDayProvider.notifier).set(focus);
  }

  /// Zooms into the hour containing day-relative minute [u].
  void _zoomInto(double u) {
    final abs = day.startMin + (u / 60).floor() * 60;
    HapticFeedback.mediumImpact();
    _setMode(DialMode.forHour(abs, _nowAbs), focus: Day.containing(abs));
  }

  /// The hour to open when zooming in without a target: now on today's
  /// page, 9 AM on other days.
  void _zoomIntoDefault() {
    final isToday = day == ref.read(todayProvider);
    _zoomInto(isToday ? (_nowAbs - day.startMin).toDouble() : 9 * 60);
  }

  void _onZoom(DialMode mode, bool zoomIn, double? focusU) {
    if (mode.level == DialLevel.day && zoomIn) {
      focusU == null ? _zoomIntoDefault() : _zoomInto(focusU);
    } else if (mode.level == DialLevel.hour && !zoomIn) {
      HapticFeedback.mediumImpact();
      _setMode(const DialMode.day());
    }
  }

  void _stepHour(DialMode mode, DialSpec spec, int dir) {
    final now = _nowAbs;
    final nowHour = now - now % 60;
    final int target;
    if (mode.isLive) {
      target = nowHour + dir * 60;
    } else {
      target = day.startMin + spec.origin + dir * 60;
    }
    _setMode(DialMode.hour(target), focus: Day.containing(target));
  }

  // ── marking menu ───────────────────────────────────────────────────────

  /// Pin kinds in [kinds] order, then recent custom texts, then Custom….
  /// Ids are `<prefix>:<kind>`, `<prefix>:text:<text>` or
  /// `<prefix>:custom`. With [time], the rows say when ("Reach by 11:00").
  List<MarkingItem> _pinItems(
    String prefix,
    List<PinKind> kinds, {
    String? time,
  }) {
    final texts = ref.read(recentPinTextsProvider).value ?? const <String>[];
    final at = time == null ? '' : ' $time';
    return [
      for (final k in kinds)
        MarkingItem(
          id: '$prefix:${k.name}',
          glyph: k.glyph,
          label: '${k.verb}$at',
        ),
      for (final t in texts)
        MarkingItem(id: '$prefix:text:$t', glyph: '📌', label: '$t$at'),
      MarkingItem(id: '$prefix:custom', glyph: '✏️', label: 'Custom…'),
    ];
  }

  List<MarkingItem> _menuItems(String blockId, double u) {
    final settings = ref.read(settingsProvider);
    final ranking = ref.read(quickRankingProvider).value;
    final activities =
        ref.read(activitiesProvider).value ?? const <ActivityRow>[];
    final todos = ref.read(allTodosProvider).value ?? const <TodoRow>[];
    final labels = ref.read(recentLabelsProvider).value ?? const <String>[];

    final rank = {
      for (final (i, id) in (ranking?.activityIds ?? const <String>[]).indexed)
        id: i,
    };
    final ordered = [...activities]
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        if (settings.quickActivityMode == QuickMode.auto) {
          final ra = rank[a.id] ?? 999, rb = rank[b.id] ?? 999;
          if (ra != rb) return ra.compareTo(rb);
        }
        return a.sortOrder.compareTo(b.sortOrder);
      });

    List<MarkingItem>? todoItems(String activityId) {
      final open = todos
          .where((t) => t.activityId == activityId && !t.done)
          .take(7)
          .toList();
      if (open.isEmpty) return null;
      return [
        for (final t in open)
          MarkingItem(
            id: 'todo:${t.id}',
            glyph: '•',
            label: t.title,
            isText: true,
          ),
      ];
    }

    final taskItems = [
      for (final a in ordered.take(7))
        MarkingItem(
          id: 'activity:${a.id}',
          glyph: a.emoji,
          label: a.name,
          children: todoItems(a.id) == null ? null : () => todoItems(a.id)!,
        ),
      const MarkingItem(id: 'more:tasks', glyph: '➕', label: 'All tasks'),
    ];
    final labelItems = [
      for (final l in labels.take(6))
        MarkingItem(id: 'label:$l', glyph: '🏷️', label: l, isText: true),
      const MarkingItem(id: 'more:label', glyph: '✏️', label: 'New label…'),
    ];
    // A sideways flick pins the moment held, or the entry's start or end
    // when held near one. Left lists "leave by" first, right "reach by", so
    // a straight flick picks it.
    final block = ref
        .read(dayPlanProvider(day))
        .value
        ?.blocks
        .where((b) => b.id == blockId)
        .firstOrNull;
    final at = block == null
        ? day.startMin + u.round()
        : pinSpotInEntry(
            start: block.startMin,
            end: block.endMin,
            held: day.startMin + u,
            step: ref.read(dialModeProvider).level == DialLevel.hour
                ? settings.hourSnapStep
                : settings.snapStep,
          );
    final time = formatClock(minuteOfDay(at), use24h: settings.use24h);
    final leftPins = _pinItems('pin:$at', const [
      PinKind.leaveBy,
      PinKind.meetingAt,
      PinKind.reachBy,
    ], time: time);
    final rightPins = _pinItems('pin:$at', const [
      PinKind.reachBy,
      PinKind.meetingAt,
      PinKind.leaveBy,
    ], time: time);

    // Clockwise from the top: tasks up, pins right, labels down, pins left.
    return [
      MarkingItem(
        id: 'group:tasks',
        glyph: '✅',
        label: 'Tasks',
        children: () => taskItems,
      ),
      MarkingItem(
        id: 'pin:$at:${PinKind.reachBy.name}',
        glyph: '📍',
        label: 'Pin $time',
        asList: true,
        children: () => rightPins,
      ),
      MarkingItem(
        id: 'group:label',
        glyph: '✏️',
        label: 'Label',
        children: () => labelItems,
      ),
      MarkingItem(
        id: 'pin:$at:${PinKind.leaveBy.name}',
        glyph: '📍',
        label: 'Pin $time',
        asList: true,
        children: () => leftPins,
      ),
    ];
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(dayPlanProvider(day));
    final settings = ref.watch(settingsProvider);
    final activities = ref.watch(activityMapProvider);
    final todos = ref.watch(allTodosProvider).value ?? const <TodoRow>[];
    final today = ref.watch(todayProvider);
    final mode = ref.watch(dialModeProvider);
    // A selection belongs to the hour it was made in; moving to another
    // hour or zoom level drops it.
    ref.listen(dialModeProvider, (prev, next) {
      if (prev != next && _selected != null) setState(() => _selected = null);
    });
    final nowAbs = ref.watch(nowMinuteProvider).value ?? nowAbsMinute();
    final brightness = Theme.of(context).brightness;
    ref.watch(quickRankingProvider);
    ref.watch(recentLabelsProvider);

    final plan = planAsync.value;
    if (plan == null) return const Center(child: CircularProgressIndicator());

    // Each entry keeps its own colour, so neighbours stay distinguishable
    // even when they share a task.
    Color colorOf(PlanBlock b) {
      final argb =
          b.color ??
          activities[b.activityId]?.color ??
          fallbackEntryColor(b.id);
      return blockColor(argb, brightness);
    }

    final hourLevel = mode.level == DialLevel.hour;
    final spec = mode.specFor(day, nowAbs);
    // Busy times from your other calendars, relative to this page's day.
    final ghosts = [
      for (final (s, e) in ref.watch(ghostsProvider))
        if (e > day.startMin - minutesPerDay && s < day.endMin + minutesPerDay)
          (s - day.startMin, e - day.startMin),
    ];
    final paintBlocks = [
      for (final b in plan.blocks)
        PaintBlock(
          id: b.id,
          start: b.startMin - day.startMin,
          end: b.endMin - day.startMin,
          color: colorOf(b),
          emoji: activities[b.activityId]?.emoji,
          status: b.status,
        ),
    ];
    final pins = ref.watch(dayPinsProvider(day)).value ?? const <PinRow>[];
    final work =
        ref.watch(dayWorkProvider(day)).value ?? const <WorkSessionRow>[];
    final workedToday = workedMinutes(work, day.startMin, day.endMin);
    final paintPins = [
      for (final p in pins)
        PaintPin(
          u: p.atMin - day.startMin,
          glyph: p.pinKind.glyph,
          draft: p.draft,
        ),
    ];
    // The live hub counts down to the next pin in the coming 3 hours.
    final nextPin = pins
        .where((p) => p.atMin > nowAbs && p.atMin - nowAbs <= 180)
        .firstOrNull;
    final onDay = plan.onDay.toList();
    final selectedBlock = plan.blocks
        .where((b) => b.id == _selected)
        .firstOrNull;
    final selectedVisible =
        selectedBlock != null &&
        selectedBlock.endMin - day.startMin > spec.origin &&
        selectedBlock.startMin - day.startMin < spec.end;
    final todosByBlock = <String, List<TodoRow>>{};
    for (final t in todos) {
      if (t.blockId != null) (todosByBlock[t.blockId!] ??= []).add(t);
    }

    final clock = ClockView(
      spec: spec,
      // Hour dial: only a small tag naming the outer ring's hour.
      captions: (shown) => hourLevel
          ? ('', lapCaption(shown.origin + 60, use24h: settings.use24h))
          : ('AM', 'PM'),
      blocks: paintBlocks,
      ghosts: ghosts,
      pins: paintPins,
      worked: [
        for (final w in work)
          (w.startMin - day.startMin, w.endMin - day.startMin),
      ],
      selectedId: _selected,
      isToday: day == today,
      isPast: day < today,
      snapStep: hourLevel ? settings.hourSnapStep : settings.snapStep,
      use24h: settings.use24h,
      // The hub only describes the selected entry while it is on the rings
      // being shown (they can slide during a drag).
      // The hub's analog clock, unless it is describing the selected entry.
      analogClock: !selectedVisible,
      center: (shown) =>
          selectedBlock != null &&
              selectedBlock.endMin - day.startMin > shown.origin &&
              selectedBlock.startMin - day.startMin < shown.end
          ? _BlockHub(
              block: selectedBlock,
              day: day,
              activity: activities[selectedBlock.activityId],
              use24h: settings.use24h,
            )
          : hourLevel
          ? _HourHub(
              shown: shown,
              live:
                  mode.isLive &&
                  day == today &&
                  shown.origin == (nowAbs - day.startMin) ~/ 60 * 60,
              nowMinute: nowAbs - day.startMin,
              use24h: settings.use24h,
              next: nextPin == null
                  ? null
                  : '${nextPin.pinKind.glyph} ${nextPin.title} · '
                        '${formatDuration(nextPin.atMin - nowAbs)}',
            )
          : _DayHub(day: day, plan: plan),
      onCreate: _create,
      onChange: _change,
      onSelect: (id) => setState(() => _selected = id),
      onTapEmpty: (u) {
        if (_selected != null) {
          setState(() => _selected = null);
        } else if (!hourLevel) {
          _zoomInto(u);
        }
      },
      // The hub: tap to zoom in or out, hold for the hour picker, flick for
      // the next/previous hour (hour dial) or day (day dial).
      onHubTap: () =>
          hourLevel ? _setMode(const DialMode.day()) : _zoomIntoDefault(),
      onHubSwipe: (dir) {
        if (hourLevel) {
          _stepHour(mode, spec, dir);
        } else {
          ref.read(focusedDayProvider.notifier).set(day.addDays(dir));
        }
      },
      hourPicker: HourPickerHooks(
        // The picker covers this page's day: inner ring AM, outer ring PM.
        base: day.startMin,
        labelFor: (abs) => hourLabel(abs, nowAbs, use24h: settings.use24h),
        onPick: (abs) =>
            _setMode(DialMode.forHour(abs, nowAbs), focus: Day.containing(abs)),
      ),
      onZoom: (zoomIn, u) => _onZoom(mode, zoomIn, u),
      menuItems: _menuItems,
      onMenuPick: _onMenuPick,
      // Holding an empty spot pins that moment.
      pinMenuItems: () => _pinItems('pinat', const [
        PinKind.reachBy,
        PinKind.meetingAt,
        PinKind.leaveBy,
      ]),
      onPinPick: (u, item) => _pin(
        day.startMin + u,
        what: item.id.substring(item.id.indexOf(':') + 1),
      ),
      menuItemColor: (item) {
        if (!item.id.startsWith('activity:')) return null;
        final a = activities[item.id.substring(9)];
        return a == null ? null : blockColor(a.color, brightness);
      },
    );

    final agenda = AgendaList(
      day: day,
      blocks: onDay,
      pins: [
        for (final p in pins)
          if (p.atMin >= day.startMin && p.atMin < day.endMin) p,
      ],
      onPinAction: _onPinAction,
      header: workedToday == 0
          ? null
          : WorkedCard(
              minutes: workedToday,
              projects: projectTotals([
                for (final w in work)
                  if (w.startMin >= day.startMin && w.startMin < day.endMin) w,
              ]),
              onTap: () => showWorkReview(context, day),
            ),
      activities: activities,
      todosByBlock: todosByBlock,
      colorOf: colorOf,
      selectedId: _selected,
      use24h: settings.use24h,
      onSelect: (id) => setState(() => _selected = _selected == id ? null : id),
      onAction: _onAgendaAction,
      hint: hourLevel
          ? 'Drag along a ring to add an entry.\n'
                'Inner ring is this hour, outer ring the next.\n'
                'Tap an entry to move or resize it; hold it for tasks and '
                'labels, or flick sideways to pin that moment.\n'
                'Hold an empty spot to pin that moment.\n'
                'Hold the centre to jump to another hour.'
          : 'Drag along a ring to add an entry.\n'
                'Inner ring is AM, outer ring is PM.\n'
                'Tap an hour to zoom in; hold the centre to pick one.\n'
                'Hold an empty spot to pin that moment.',
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 840) {
          return Row(
            children: [
              Expanded(
                child: Padding(padding: const EdgeInsets.all(24), child: clock),
              ),
              SizedBox(width: 400, child: agenda),
            ],
          );
        }
        final clockSide = (c.maxHeight * 0.58).clamp(240.0, c.maxWidth - 32);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SizedBox(height: clockSide, child: clock),
            ),
            Expanded(child: agenda),
          ],
        );
      },
    );
  }
}

/// Hub text of the day dial around the clock: the date above, how much is
/// planned below.
class _DayHub extends StatelessWidget {
  const _DayHub({required this.day, required this.plan});

  final Day day;
  final DayPlan plan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final date = day.toLocalDateTime();
    final planned = plan.onDay.fold<int>(0, (sum, b) {
      final s = b.startMin < day.startMin ? day.startMin : b.startMin;
      final e = b.endMin > day.endMin ? day.endMin : b.endMin;
      return sum + (e - s);
    });
    return _ClockHubText(
      top: Text(
        '${DateFormat.E().format(date).toUpperCase()} ${day.day}',
        style: t.labelLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      bottom: Text(
        planned == 0 ? DateFormat.MMM().format(date) : formatDuration(planned),
        style: t.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// Hub text around the analog clock: a line above the hands' pivot and one
/// below it, leaving the middle to the hands.
class _ClockHubText extends StatelessWidget {
  const _ClockHubText({required this.top, this.bottom});

  final Widget top;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 120,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [top, bottom ?? const SizedBox.shrink()],
      ),
    ),
  );
}

/// Hub text of the hour dial around the clock: NOW (or the hour shown)
/// above, and below the digital time or the next pin's countdown.
class _HourHub extends StatelessWidget {
  const _HourHub({
    required this.shown,
    required this.live,
    required this.nowMinute,
    required this.use24h,
    this.next,
  });

  final DialSpec shown;
  final bool live;

  /// Countdown to the next pin, shown below instead of the digital time.
  final String? next;

  /// Day-relative minute of now; the live hub shows the current time.
  final int nowMinute;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final time = formatClock(nowMinute, use24h: use24h);
    return _ClockHubText(
      top: Text(
        live ? 'NOW' : lapCaption(shown.origin, use24h: use24h),
        style: t.labelLarge?.copyWith(
          color: live ? scheme.primary : scheme.onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: live ? 1.5 : 0.4,
        ),
      ),
      bottom: !live
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 116),
              child: Text(
                next ?? time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelMedium?.copyWith(
                  color: next != null
                      ? scheme.tertiary
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

/// Hub while an entry is selected: its name (if it has one) and times.
class _BlockHub extends StatelessWidget {
  const _BlockHub({
    required this.block,
    required this.day,
    required this.activity,
    required this.use24h,
  });

  final PlanBlock block;
  final Day day;
  final ActivityRow? activity;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final title = block.titleWith(activity?.name);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activity != null)
            Text(activity!.emoji, style: emojiStyle.copyWith(fontSize: 26)),
          if (title != null)
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          Text(
            '${formatClock(block.startMin - day.startMin, use24h: use24h)} – '
            '${formatClock(block.endMin - day.startMin, use24h: use24h)}',
            style: (title == null ? t.titleMedium : t.labelMedium)?.copyWith(
              color: title == null ? null : scheme.onSurfaceVariant,
            ),
          ),
          Text(
            formatDuration(block.durMin),
            style: t.labelSmall?.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

/// Shown while planning: everything drawn is a sketch until ✓ saves it or
/// ✕ throws it away.
class _PlanBanner extends StatelessWidget {
  const _PlanBanner({
    required this.sketches,
    required this.onDiscard,
    required this.onSave,
  });

  final int sketches;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: scheme.tertiaryContainer,
        shape: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Discard plan',
                onPressed: onDiscard,
                color: scheme.onTertiaryContainer,
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Plan mode',
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      sketches == 0
                          ? 'Sketch freely; nothing saves until ✓'
                          : '$sketches ${sketches == 1 ? 'change' : 'changes'} · ✓ keeps, ✕ discards',
                      style: t.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Save plan',
                onPressed: onSave,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A faint dot grid, so plan mode reads as a sketch rather than the real
/// plan.
class _SketchPaper extends CustomPainter {
  _SketchPaper(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 22.0;
    final dot = Paint()..color = ink.withValues(alpha: 0.09);
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_SketchPaper old) => old.ink != ink;
}
