import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/time/day_minutes.dart';
import '../../data/repos/pin_repo.dart';
import '../clock/clock_painter.dart';
import '../clock/clock_view.dart';
import '../clock/spiral_math.dart';
import '../day/dial_mode.dart';
import '../radial_menu/marking_menu_controller.dart';
import '../reminders/reminder_providers.dart';
import 'playful.dart';

/// Whether this device has had the welcome tour. `main` reads it from
/// LocalKv and overrides [onboardedAtStartProvider]; each new device gets
/// the tour once.
final onboardedAtStartProvider = Provider<bool>((ref) => true);

/// The step the tour opens on (the dev harness jumps ahead for shots).
final onboardingFirstStepProvider = Provider<int>((ref) => 0);

final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(
  OnboardedNotifier.new,
);

class OnboardedNotifier extends Notifier<bool> {
  static const key = 'onboarded';

  @override
  bool build() => ref.watch(onboardedAtStartProvider);

  Future<void> finish() async {
    state = true;
    await ref.read(databaseProvider).setLocal(key, '1');
  }
}

enum _Step { hello, donut, draw, hold, zoom, plan, nudge, done }

/// The first-run tour. The dial is the star: it draws itself to say hello,
/// then a ghost finger shows each gesture on a practice dial until you do
/// it yourself, and sprinkles burst out of it when you do. Nothing here
/// touches your plan.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late var _step = _Step.values[ref.read(onboardingFirstStepProvider)];
  var _sprinkles = 0;

  /// Entries drawing themselves around the hello and done dials.
  late final _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  /// A little bounce of the dial when you get something right.
  late final _boing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // The practice dial.
  var _spec = const DialSpec.day();
  final _blocks = <PaintBlock>[];
  final _labels = <String, String>{};
  final _pins = <PaintPin>[];
  String? _selected;
  bool _drew = false, _held = false, _zoomed = false;

  /// The sample day on the hello, donut and done dials.
  static const _sample = [
    (0, 7 * 60, '😴'),
    (7 * 60 + 30, 8 * 60 + 30, '💪'),
    (9 * 60, 11 * 60 + 30, '📚'),
    (13 * 60, 14 * 60, '🍽️'),
    (15 * 60, 17 * 60 + 30, '💼'),
    (19 * 60, 20 * 60, '🚆'),
    (21 * 60, 22 * 60 + 30, '🎮'),
  ];

  @override
  void initState() {
    super.initState();
    // Opening straight on "hold" (replays from the harness) needs an entry.
    if (_step == _Step.hold) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _blocks.isEmpty) setState(() => _add(9 * 60, 10 * 60));
      });
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    _boing.dispose();
    super.dispose();
  }

  bool get _ready => switch (_step) {
    _Step.draw => _drew,
    _Step.hold => _held,
    _Step.zoom => _zoomed,
    _ => true,
  };

  void _celebrate() {
    HapticFeedback.mediumImpact();
    _boing.forward(from: 0);
    setState(() => _sprinkles++);
  }

  void _next() {
    if (_step == _Step.done) {
      widget.onDone();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _step = _Step.values[_step.index + 1];
      if (_step == _Step.hold && _blocks.isEmpty) {
        // Something to hold, for anyone who skipped drawing.
        _add(9 * 60, 10 * 60);
      }
      if (_step == _Step.zoom) _selected = null;
      if (_step == _Step.done) {
        _fill.forward(from: 0);
        _sprinkles++;
      }
    });
  }

  Color _color(int i) => blockColor(
    entryPalette[(i * 3 + 1) % entryPalette.length],
    Theme.of(context).brightness,
  );

  void _add(int start, int end) {
    final i = _blocks.length;
    _blocks.add(
      PaintBlock(id: 'practice-$i', start: start, end: end, color: _color(i)),
    );
  }

  Future<void> _remindMe() async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsRepoProvider)
        .save(settings.copyWith(remindersEnabled: true));
    final service = ref.read(reminderServiceProvider);
    await service.init();
    await service.requestPermission();
    _celebrate();
    _next();
  }

  // ── practice dial callbacks ────────────────────────────────────────────

  void _onCreate(int s, int e) {
    setState(() => _add(s, e));
    if (_step == _Step.draw && !_drew) {
      _drew = true;
      _celebrate();
    }
  }

  void _onChange(String id, int s, int e) => setState(() {
    final i = _blocks.indexWhere((b) => b.id == id);
    if (i < 0) return;
    final b = _blocks[i];
    _blocks[i] = PaintBlock(
      id: id,
      start: s,
      end: e,
      color: b.color,
      emoji: b.emoji,
    );
  });

  void _onTapEmpty(double u) => setState(() {
    if (_selected != null) {
      _selected = null;
    } else if (!_spec.isHour) {
      _spec = DialSpec.hour((u / 60).floor() * 60);
      if (_step == _Step.zoom && !_zoomed) {
        _zoomed = true;
        _celebrate();
      }
    }
  });

  /// In the zoom step a tap on an entry zooms into its hour too, so
  /// following the hint can't dead-end on a selection.
  void _onSelect(String? id) {
    final b = _blocks.where((b) => b.id == id).firstOrNull;
    if (_step == _Step.zoom && !_spec.isHour && b != null) {
      _onTapEmpty(b.start.toDouble());
      return;
    }
    setState(() => _selected = id);
  }

  void _markHeld() {
    if (_step == _Step.hold && !_held) {
      _held = true;
      _celebrate();
    }
  }

  List<MarkingItem> _menu(String id, double u) {
    final b = _blocks.where((b) => b.id == id).firstOrNull;
    final at = b == null
        ? u.round()
        : pinSpotInEntry(
            start: b.start,
            end: b.end,
            held: u,
            step: _spec.isHour ? 5 : 15,
          );
    final time = formatClock(
      ((at % minutesPerDay) + minutesPerDay) % minutesPerDay,
      use24h: ref.read(settingsProvider).use24h,
    );
    MarkingItem pin(String glyph, String verb) =>
        MarkingItem(id: 'pin:$at:$glyph', glyph: glyph, label: '$verb $time');
    return [
      MarkingItem(
        id: 'group:tasks',
        glyph: '✅',
        label: 'Tasks',
        children: () => const [
          MarkingItem(id: 'task:📚', glyph: '📚', label: 'Study'),
          MarkingItem(id: 'task:💪', glyph: '💪', label: 'Gym'),
          MarkingItem(id: 'task:🍽️', glyph: '🍽️', label: 'Meal'),
          MarkingItem(id: 'task:🚆', glyph: '🚆', label: 'Travel'),
        ],
      ),
      MarkingItem(
        id: 'pin:$at:🏁',
        glyph: '📍',
        label: 'Pin $time',
        asList: true,
        children: () => [pin('🏁', 'Reach by'), pin('🤝', 'Meeting at')],
      ),
      MarkingItem(
        id: 'group:label',
        glyph: '✏️',
        label: 'Label',
        children: () => const [
          MarkingItem(
            id: 'label:home to stn',
            glyph: '🏷️',
            label: 'home to stn',
            isText: true,
          ),
          MarkingItem(
            id: 'label:coffee ☕',
            glyph: '🏷️',
            label: 'coffee ☕',
            isText: true,
          ),
          MarkingItem(
            id: 'label:call mom',
            glyph: '🏷️',
            label: 'call mom',
            isText: true,
          ),
        ],
      ),
      MarkingItem(
        id: 'pin:$at:🚶',
        glyph: '📍',
        label: 'Pin $time',
        asList: true,
        children: () => [pin('🚶', 'Leave by'), pin('🤝', 'Meeting at')],
      ),
    ];
  }

  void _onMenuPick(String id, MarkingItem item) {
    final i = _blocks.indexWhere((b) => b.id == id);
    if (i < 0) return;
    final b = _blocks[i];
    final colon = item.id.indexOf(':');
    final kind = item.id.substring(0, colon);
    final value = item.id.substring(colon + 1);
    setState(() {
      switch (kind) {
        case 'task':
          _blocks[i] = PaintBlock(
            id: id,
            start: b.start,
            end: b.end,
            color: b.color,
            emoji: value,
          );
        case 'label':
          _labels[id] = value;
        case 'pin':
          final c = value.indexOf(':');
          _pins.add(
            PaintPin(
              u: int.parse(value.substring(0, c)),
              glyph: value.substring(c + 1),
            ),
          );
      }
    });
    if (kind != 'group') _markHeld();
  }

  // ── screen ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final (title, body) = _words();
    final practice = !_ready;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: DriftingSprinkles()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          StepRing(
                            step: _step.index + 1,
                            count: _Step.values.length,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_step.index + 1} of ${_Step.values.length}',
                            style: t.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (_step != _Step.done)
                            TextButton(
                              onPressed: widget.onDone,
                              child: const Text('Skip tour'),
                            ),
                        ],
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0.06, 0),
                                end: Offset.zero,
                              ).animate(a),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_stageKey),
                            child: _stage(),
                          ),
                        ),
                      ),
                      // The words swap with a little pop when they change.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: ScaleTransition(
                            scale: Tween(begin: 0.94, end: 1.0).animate(
                              CurvedAnimation(
                                parent: a,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(title),
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: t.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              body,
                              textAlign: TextAlign.center,
                              style: t.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._buttons(practice),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: SprinkleBurst(fire: _sprinkles)),
        ],
      ),
    );
  }

  /// The practice dial stays put across the steps that use it.
  Object get _stageKey => switch (_step) {
    _Step.draw || _Step.hold || _Step.zoom => 'practice',
    _ => _step,
  };

  (String, String) _words() => switch (_step) {
    _Step.hello => (
      'Hey there! 👋',
      'Donut turns your day into a ring you can draw on. '
          "Let's take it for a spin, it takes about a minute.",
    ),
    _Step.donut => (
      'Your day, as a donut 🍩',
      'Mornings live on the inner ring, afternoons and evenings on the outer '
          'one. The hands in the middle tell the time.',
    ),
    _Step.draw =>
      _drew
          ? (
              'Yum, your first plan! 😋',
              'Drag again any time to add more. Overlaps are fine, '
                  "they'll share the ring.",
            )
          : (
              'Draw your first plan',
              'Put your finger on a ring and drag along it. Lift where it '
                  'should end.',
            ),
    _Step.hold =>
      _held
          ? (
              'Smooth! ✨',
              'Holding an empty spot works too: it pins that exact moment.',
            )
          : (
              'Hold for more',
              'Press and hold an entry, then flick ⬆️ for a task, ⬇️ for a '
                  'label, ⬅️ ➡️ to pin a time like "Reach by".',
            ),
    _Step.zoom =>
      _zoomed
          ? (
              'Every minute counts ⏱️',
              'Now the rings are this hour and the next. Tap the clock in '
                  'the middle to zoom back out.',
            )
          : (
              'Zoom into an hour',
              'Tap an empty spot on any hour to plan it minute by minute: '
                  'get ready at 4:05, leave at 4:10, train at 4:15.',
            ),
    _Step.plan => (
      'A sketchpad for what-ifs',
      'Tap ✏️ to enter plan mode. Play around freely, then ✓ keeps it '
          'or ✕ throws it all away.',
    ),
    _Step.nudge => (
      'Want a heads-up?',
      "Donut can ping you when something's about to start, and 10 minutes "
          'before a "Reach by".',
    ),
    _Step.done => (
      "You're all set 🍩",
      'Your day is waiting. You can replay this tour any time from Settings.',
    ),
  };

  Widget _stage() {
    switch (_step) {
      case _Step.hello || _Step.done:
        return _showcase();
      case _Step.donut:
        return _dial(interactive: false, blocks: _sampleBlocks(1));
      case _Step.draw || _Step.hold || _Step.zoom:
        return _dial(interactive: true, blocks: _blocks);
      case _Step.plan:
        return const Center(child: _PlanModePreview());
      case _Step.nudge:
        return const Center(child: _NotificationPreview());
    }
  }

  /// The sample day, each entry drawn [progress] of the way round.
  List<PaintBlock> _sampleBlocks(double progress) => [
    for (final (i, (s, e, emoji)) in _sample.indexed)
      if (progress * _sample.length > i)
        PaintBlock(
          id: 'sample-$i',
          start: s,
          end:
              s +
              ((e - s) * (progress * _sample.length - i).clamp(0.0, 1.0))
                  .round()
                  .clamp(1, e - s),
          color: _color(i),
          emoji: emoji,
        ),
  ];

  /// The hello and done dials: the sample day drawing itself in.
  Widget _showcase() => AnimatedBuilder(
    animation: _fill,
    builder: (_, _) => _dial(
      interactive: false,
      blocks: _sampleBlocks(Curves.easeInOut.transform(_fill.value)),
    ),
  );

  Widget _dial({required bool interactive, required List<PaintBlock> blocks}) {
    final use24h = ref.watch(settingsProvider).use24h;
    final spec = interactive ? _spec : const DialSpec.day();
    final selected = _selected == null
        ? null
        : blocks.where((b) => b.id == _selected).firstOrNull;
    final clock = ClockView(
      spec: spec,
      captions: (shown) => shown.isHour
          ? ('', lapCaption(shown.origin + 60, use24h: use24h))
          : ('AM', 'PM'),
      blocks: blocks,
      pins: interactive ? _pins : const [],
      selectedId: interactive ? _selected : null,
      isToday: true,
      isPast: false,
      snapStep: spec.isHour ? 5 : 15,
      use24h: use24h,
      analogClock: selected == null,
      center: (shown) => _PracticeHub(
        title: selected == null
            ? (shown.isHour
                  ? lapCaption(shown.origin, use24h: use24h)
                  : 'TODAY')
            : (_labels[selected.id] ?? selected.emoji ?? 'Your plan'),
      ),
      onCreate: _onCreate,
      onChange: _onChange,
      onSelect: _onSelect,
      onTapEmpty: _onTapEmpty,
      onHubTap: () => setState(() {
        _selected = null;
        if (_spec.isHour) _spec = const DialSpec.day();
      }),
      onHubSwipe: (dir) {
        if (_spec.isHour) {
          setState(() => _spec = DialSpec.hour(_spec.origin + dir * 60));
        }
      },
      menuItems: _menu,
      onMenuPick: _onMenuPick,
      pinMenuItems: () => const [
        MarkingItem(id: 'pin:🏁', glyph: '🏁', label: 'Reach by'),
        MarkingItem(id: 'pin:🤝', glyph: '🤝', label: 'Meeting at'),
        MarkingItem(id: 'pin:🚶', glyph: '🚶', label: 'Leave by'),
      ],
      onPinPick: (u, item) {
        setState(() => _pins.add(PaintPin(u: u, glyph: item.glyph)));
        _markHeld();
      },
    );
    final ghost = interactive ? _ghost() : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: AnimatedBuilder(
          animation: _boing,
          builder: (_, child) => Transform.scale(
            scale: 1 + 0.05 * math.sin(_boing.value * math.pi),
            child: child,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: interactive ? clock : IgnorePointer(child: clock),
                ),
                if (ghost != null) Positioned.fill(child: ghost),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The gesture to show until it has been done.
  Widget? _ghost() {
    final first = _blocks.firstOrNull;
    return switch (_step) {
      _Step.draw when !_drew => GhostFinger(
        move: GhostMove.drag,
        spec: _spec,
        from: 14 * 60,
        to: 16 * 60 + 30,
      ),
      _Step.hold when !_held && first != null && !_spec.isHour => GhostFinger(
        move: GhostMove.holdFlick,
        spec: _spec,
        from: (first.start + first.end) ~/ 2,
      ),
      _Step.zoom when !_zoomed && !_spec.isHour => GhostFinger(
        move: GhostMove.tap,
        spec: _spec,
        from: emptyHourSpot([for (final b in _blocks) (b.start, b.end)]),
      ),
      _ => null,
    };
  }

  List<Widget> _buttons(bool practice) {
    final big = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    );
    if (_step == _Step.nudge) {
      return [
        FilledButton.icon(
          style: big,
          onPressed: _remindMe,
          icon: const Icon(Icons.notifications_active_rounded),
          label: const Text('Turn on reminders'),
        ),
        SizedBox(
          height: 44,
          child: TextButton(onPressed: _next, child: const Text('Not now')),
        ),
      ];
    }
    final label = switch (_step) {
      _Step.hello => "Let's go",
      _Step.done => 'Start planning',
      _ => 'Next',
    };
    return [
      FilledButton(
        style: big,
        onPressed: practice ? null : _next,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(practice ? 'Give it a try first' : label),
            if (!practice) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ],
        ),
      ),
      SizedBox(
        height: 44,
        child: practice
            ? TextButton(onPressed: _next, child: const Text('Skip this step'))
            : null,
      ),
    ];
  }
}

/// A day-relative minute in the middle of an hour no span covers (within
/// 10 minutes either side), for the zoom hint to tap: a tap on an entry
/// would select it instead. Prefers the afternoon, then the morning.
@visibleForTesting
int emptyHourSpot(List<(int, int)> spans) {
  const hours = [16, 10, 15, 11, 20, 9, 14, 21, 8, 13, 19, 7, 12, 18, 6];
  for (final h in hours) {
    final m = h * 60 + 30;
    if (!spans.any((s) => s.$1 < m + 10 && s.$2 > m - 10)) return m;
  }
  return 16 * 60 + 30;
}

/// The practice dial's hub text, above the clock's pivot.
class _PracticeHub extends StatelessWidget {
  const _PracticeHub({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 120,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A reminder sliding in over a small dial: what "Turn on reminders" gets
/// you.
class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    Widget card(
      String emoji,
      String title,
      String body,
      double delay,
    ) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 700 + (delay * 1000).round()),
      curve: Interval(delay / (0.7 + delay), 1, curve: Curves.easeOutBack),
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * -40),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: emojiStyle.copyWith(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    body,
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text('now', style: t.labelSmall?.copyWith(color: scheme.outline)),
          ],
        ),
      ),
    );
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          card('📚', 'Study', '9:00 – 11:30 AM · in 5 min', 0),
          card('🏁', 'Reach by 4:55 PM', 'In 10 min', 0.35),
        ],
      ),
    );
  }
}

/// A peek at plan mode: the night-violet sketchpad, its banner and a
/// dashed sketch.
class _PlanModePreview extends StatelessWidget {
  const _PlanModePreview();

  @override
  Widget build(BuildContext context) {
    final plan = ColorScheme.fromSeed(
      seedColor: planSeed,
      brightness: Brightness.dark,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (_, v, child) =>
          Transform.scale(scale: 0.85 + 0.15 * v, child: child),
      child: Container(
        width: 300,
        height: 260,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: plan.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: plan.primary.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _DotsPainter(plan.onSurface)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: plan.tertiaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.close_rounded,
                          color: plan.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Plan mode · 3 sketches',
                            style: TextStyle(
                              color: plan.onTertiaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: plan.primary,
                          child: Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: plan.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: CustomPaint(
                        size: const Size.square(140),
                        painter: _SketchRingPainter(plan),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = ink.withValues(alpha: 0.12);
    for (var x = 10.0; x < size.width; x += 18) {
      for (var y = 10.0; y < size.height; y += 18) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.ink != ink;
}

/// A ring with a few dashed sketch arcs and the pen.
class _SketchRingPainter extends CustomPainter {
  _SketchRingPainter(this.scheme);

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 10;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = scheme.surfaceContainerHighest,
    );
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    for (final (start, sweep, color) in [
      (-1.4, 0.9, scheme.primary),
      (0.0, 0.6, scheme.tertiary),
      (1.2, 1.1, scheme.secondary),
    ]) {
      dash.color = color.withValues(alpha: 0.75);
      for (var a = start; a < start + sweep; a += 0.22) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          a,
          0.12,
          false,
          dash,
        );
      }
    }
    final tp = TextPainter(
      text: TextSpan(text: '✏️', style: emojiStyle.copyWith(fontSize: 40)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_SketchRingPainter old) => old.scheme != scheme;
}
