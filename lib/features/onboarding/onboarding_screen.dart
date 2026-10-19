import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../clock/clock_painter.dart';
import '../clock/clock_view.dart';
import '../clock/spiral_math.dart';
import '../day/dial_mode.dart';
import '../radial_menu/marking_menu_controller.dart';
import '../reminders/reminder_providers.dart';
import 'playful.dart';
import 'sprinkles.dart';

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

/// The first-run tour: Sprinkles the donut walks you through the dial on a
/// practice clock you really drag, hold and zoom. Nothing here touches
/// your plan.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late var _step = _Step.values[ref.read(onboardingFirstStepProvider)];
  var _cheer = 1;
  var _confetti = 0;

  // The practice dial.
  var _spec = const DialSpec.day();
  final _blocks = <PaintBlock>[];
  final _labels = <String, String>{};
  final _pins = <PaintPin>[];
  String? _selected;
  bool _drew = false, _held = false, _zoomed = false;

  static const _green = Color(0xFF58CC02);

  bool get _ready => switch (_step) {
    _Step.draw => _drew,
    _Step.hold => _held,
    _Step.zoom => _zoomed,
    _ => true,
  };

  void _celebrate() {
    HapticFeedback.mediumImpact();
    setState(() {
      _cheer++;
      _confetti++;
    });
  }

  void _next() {
    if (_step == _Step.done) {
      widget.onDone();
      return;
    }
    setState(() {
      _step = _Step.values[_step.index + 1];
      if (_step == _Step.hold && _blocks.isEmpty) {
        // Something to hold, for anyone who skipped drawing.
        _add(9 * 60, 10 * 60);
      }
      if (_step == _Step.zoom) _selected = null;
      if (_step == _Step.done) {
        _cheer++;
        _confetti++;
      }
    });
  }

  void _add(int start, int end) {
    final i = _blocks.length;
    _blocks.add(
      PaintBlock(
        id: 'practice-$i',
        start: start,
        end: end,
        color: blockColor(
          entryPalette[(i * 3 + 1) % entryPalette.length],
          Theme.of(context).brightness,
        ),
      ),
    );
  }

  Future<void> _nudgeMe() async {
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

  void _markHeld() {
    if (_step == _Step.hold && !_held) {
      _held = true;
      _celebrate();
    }
  }

  List<MarkingItem> _menu(String id) {
    MarkingItem pin(String side, String glyph, String label) =>
        MarkingItem(id: '$side:$glyph', glyph: glyph, label: label);
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
        id: 'pinend:🏁',
        glyph: '📍',
        label: 'Pin the end',
        asList: true,
        children: () => [
          pin('pinend', '🏁', 'Reach by'),
          pin('pinend', '🤝', 'Meeting at'),
        ],
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
        id: 'pinstart:🚶',
        glyph: '📍',
        label: 'Pin the start',
        asList: true,
        children: () => [
          pin('pinstart', '🚶', 'Leave by'),
          pin('pinstart', '🤝', 'Meeting at'),
        ],
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
        case 'pinend' || 'pinstart':
          _pins.add(
            PaintPin(u: kind == 'pinend' ? b.end : b.start, glyph: value),
          );
      }
    });
    if (kind != 'group') _markHeld();
  }

  // ── screen ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final (say, mood) = _speech();
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Skip the tour',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: widget.onDone,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ProgressPill(
                              value: _step.index / (_Step.values.length - 1),
                              color: _green,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_step != _Step.hello && _step != _Step.done)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Sprinkles(size: 76, mood: mood, cheer: _cheer),
                            const SizedBox(width: 14),
                            Expanded(child: SpeechBubble(text: say)),
                          ],
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutBack,
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: ScaleTransition(
                              scale: Tween(begin: 0.92, end: 1.0).animate(a),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_stageKey),
                            child: _stage(context, say, mood),
                          ),
                        ),
                      ),
                      ..._buttons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: ConfettiBurst(fire: _confetti)),
        ],
      ),
    );
  }

  /// The practice dial stays put across the steps that use it.
  Object get _stageKey => switch (_step) {
    _Step.draw || _Step.hold || _Step.zoom => 'dial',
    _ => _step,
  };

  (String, SprinklesMood) _speech() => switch (_step) {
    _Step.hello => ("Hi! I'm Sprinkles 🍩", SprinklesMood.happy),
    _Step.donut => (
      'This is your day, as a donut! The inner ring is the morning (AM), '
          'the outer ring is the afternoon and evening (PM).',
      SprinklesMood.happy,
    ),
    _Step.draw =>
      _drew
          ? ('Yum! 😋 You just planned your first thing!', SprinklesMood.cheer)
          : (
              'Your turn! Put your finger on a ring and drag along it to plan '
                  'something.',
              SprinklesMood.wow,
            ),
    _Step.hold =>
      _held
          ? (
              'Look at you go! ✨ Holding is your superpower.',
              SprinklesMood.cheer,
            )
          : (
              'Now press and hold an entry, then flick ⬆️ for a task, ⬇️ for '
                  'a label, or ⬅️ ➡️ to pin a time like "Reach by".',
              SprinklesMood.happy,
            ),
    _Step.zoom =>
      _zoomed
          ? (
              'Every minute counts! ⏱️ Tap the clock in the middle to zoom '
                  'back out.',
              SprinklesMood.cheer,
            )
          : (
              'Tap any hour to zoom in and plan minute by minute. The middle '
                  'is a real clock ⏰',
              SprinklesMood.happy,
            ),
    _Step.plan => (
      'Just daydreaming? Tap ✏️ for Plan mode: a secret sketchpad. '
          '✓ keeps it, ✕ throws it away.',
      SprinklesMood.wow,
    ),
    _Step.nudge => (
      "Want a little nudge when something's about to start? I promise I "
          "won't be annoying 🙈",
      SprinklesMood.happy,
    ),
    _Step.done => (
      "You're all set! Let's make today delicious 🍩✨",
      SprinklesMood.cheer,
    ),
  };

  Widget _stage(BuildContext context, String say, SprinklesMood mood) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    switch (_step) {
      case _Step.hello || _Step.done:
        final hello = _step == _Step.hello;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Sprinkles(size: 170, mood: mood, cheer: _cheer),
            const SizedBox(height: 20),
            Text(
              say,
              textAlign: TextAlign.center,
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              hello
                  ? "I'll show you how to plan your day on a clock.\n"
                        'It takes about a minute. Promise!'
                  : 'Tip: replay this tour any time from Settings.',
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        );
      case _Step.donut:
        return _dial(
          interactive: false,
          blocks: [
            for (final (i, (s, e, emoji)) in const [
              (0, 7 * 60, '😴'),
              (9 * 60, 11 * 60 + 30, '📚'),
              (13 * 60, 14 * 60, '🍽️'),
              (18 * 60, 19 * 60, '💪'),
            ].indexed)
              PaintBlock(
                id: 'sample-$i',
                start: s,
                end: e,
                color: blockColor(
                  entryPalette[i * 2 % entryPalette.length],
                  Theme.of(context).brightness,
                ),
                emoji: emoji,
              ),
          ],
        );
      case _Step.draw || _Step.hold || _Step.zoom:
        return _dial(interactive: true, blocks: _blocks);
      case _Step.plan:
        return const Center(child: _PlanModePreview());
      case _Step.nudge:
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.rotate(
              angle: (1 - v) * 0.8,
              child: Transform.scale(scale: 0.6 + 0.4 * v, child: child),
            ),
            child: Text('🔔', style: emojiStyle.copyWith(fontSize: 120)),
          ),
        );
    }
  }

  Widget _dial({required bool interactive, required List<PaintBlock> blocks}) {
    final use24h = ref.watch(settingsProvider).use24h;
    final selected = _selected == null
        ? null
        : blocks.where((b) => b.id == _selected).firstOrNull;
    final clock = ClockView(
      spec: interactive ? _spec : const DialSpec.day(),
      captions: (shown) => shown.isHour
          ? ('', lapCaption(shown.origin + 60, use24h: use24h))
          : ('AM', 'PM'),
      blocks: blocks,
      pins: interactive ? _pins : const [],
      selectedId: interactive ? _selected : null,
      isToday: true,
      isPast: false,
      snapStep: _spec.isHour ? 5 : 15,
      use24h: use24h,
      analogClock: selected == null,
      center: (shown) => _PracticeHub(
        title: selected == null
            ? (shown.isHour
                  ? lapCaption(shown.origin, use24h: use24h)
                  : 'TODAY')
            : (_labels[selected.id] ?? selected.emoji ?? 'Your entry'),
      ),
      onCreate: _onCreate,
      onChange: _onChange,
      onSelect: (id) => setState(() => _selected = id),
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
      pinMenuItems: () => [
        const MarkingItem(id: 'pin:🏁', glyph: '🏁', label: 'Reach by'),
        const MarkingItem(id: 'pin:🤝', glyph: '🤝', label: 'Meeting at'),
        const MarkingItem(id: 'pin:🚶', glyph: '🚶', label: 'Leave by'),
      ],
      onPinPick: (u, item) {
        setState(() => _pins.add(PaintPin(u: u, glyph: item.glyph)));
        _markHeld();
      },
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: interactive ? clock : IgnorePointer(child: clock),
        ),
      ),
    );
  }

  List<Widget> _buttons() {
    if (_step == _Step.nudge) {
      return [
        ChunkyButton(
          label: 'Yes, nudge me!',
          color: _green,
          onPressed: _nudgeMe,
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: _next, child: const Text('Maybe later')),
      ];
    }
    final label = switch (_step) {
      _Step.hello => "Let's go!",
      _Step.donut => 'Got it!',
      _Step.plan => 'So cool',
      _Step.done => 'Start planning',
      _ => 'Continue',
    };
    final practice = !_ready;
    return [
      ChunkyButton(
        label: label,
        color: _green,
        onPressed: practice ? null : _next,
      ),
      SizedBox(
        height: 44,
        child: practice
            ? TextButton(onPressed: _next, child: const Text("I'll try later"))
            : null,
      ),
    ];
  }
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
