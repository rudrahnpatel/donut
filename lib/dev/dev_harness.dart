import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../core/time/day_minutes.dart';
import '../core/time/hlc.dart';
import '../data/db/app_database.dart';
import '../data/repos/settings_repo.dart';
import '../features/clock/clock_geometry.dart';
import '../features/clock/clock_painter.dart';
import '../features/day/dial_mode.dart';

/// Debug-only demo + self-screenshot harness, driven by environment vars so
/// the app can be checked visually without touching real data or the
/// desktop session:
///
/// - `DONUT_DEMO=1`                 in-memory database with sample blocks
/// - `DONUT_THEME=light|dark|amoled`
/// - `DONUT_LEVEL=day|hour`         starting zoom (default: live hour)
/// - `DONUT_HOUR=16`                with `hour`, a fixed hour of today
/// - `DONUT_SCENE=menu|tasks|label|drag|select|picker`  gesture before the shot
/// - `DONUT_SCREENSHOT=/abs/path.png` capture the app, then exit
class DevHarness {
  DevHarness._(this.env);

  static DevHarness? fromEnvironment() {
    if (!kDebugMode) return null;
    final env = Platform.environment;
    if (env['DONUT_DEMO'] == null && env['DONUT_SCREENSHOT'] == null) {
      return null;
    }
    return DevHarness._(env);
  }

  final Map<String, String> env;
  final _boundary = GlobalKey();

  AppDatabase openDatabase() => AppDatabase(NativeDatabase.memory());

  Widget wrap(Widget app) => RepaintBoundary(key: _boundary, child: app);

  List<Override> get overrides {
    final level = env['DONUT_LEVEL'];
    final hour = int.tryParse(env['DONUT_HOUR'] ?? '');
    final DialMode mode;
    if (level == 'day') {
      mode = const DialMode.day();
    } else if (hour != null) {
      mode = DialMode.hour(Day.today().startMin + hour * 60);
    } else {
      mode = const DialMode.live();
    }
    return [dialModeProvider.overrideWith(() => DialModeNotifier(mode))];
  }

  Future<void> seed(AppDatabase db, HlcClock clock) async {
    final theme = env['DONUT_THEME'];
    if (theme != null) {
      await SettingsRepo(db, clock).save(
        AppSettings(
          theme: theme == 'light' ? ThemePref.light : ThemePref.dark,
          amoled: theme == 'amoled',
          useDynamicColor: false,
        ),
      );
    }
    final acts = {
      for (final a in await db.select(db.activities).get()) a.name: a.id,
    };
    await db
        .into(db.activities)
        .insert(
          ActivitiesCompanion.insert(
            id: 'travel',
            name: 'Travel',
            emoji: '🚆',
            color: 0xFF26A69A,
            hlc: clock.now(),
          ),
        );
    acts['Travel'] = 'travel';
    final today = Day.today().startMin;
    Future<void> saved(
      String id,
      int s,
      int e,
      String act, {
      String? emoji,
      String? note,
    }) => db
        .into(db.blocks)
        .insert(
          BlocksCompanion.insert(
            id: id,
            startMin: today + s,
            durMin: e - s,
            activityId: Value(acts[act]),
            emoji: Value(emoji),
            note: Value(note),
            hlc: clock.now(),
          ),
        );
    await saved('sleep-1', -60, 7 * 60, 'Sleep');
    await saved('gym', 7 * 60 + 30, 8 * 60 + 30, 'Gym');
    await saved('study', 9 * 60, 11 * 60 + 30, 'Study');
    await saved('meal', 12 * 60 + 30, 13 * 60 + 15, 'Meal');
    // The 4 PM trip from the design questions.
    const travel = 'Travel';
    await saved('t1', 965, 970, travel, emoji: '🧥', note: 'getting ready');
    await saved('t2', 970, 975, travel, emoji: '🚶', note: 'home to stn');
    await saved('t3', 975, 1015, travel, note: 'train');
    await saved('sleep-2', 23 * 60, 31 * 60, 'Sleep');
    // An unsaved edit and a parked draft, to show both styles.
    await db
        .into(db.blockEdits)
        .insert(
          BlockEditsCompanion.insert(
            blockId: 'work',
            startMin: today + 14 * 60,
            durMin: 120,
            activityId: Value(acts['Work']),
            state: EditState.draft,
            editedAt: 0,
          ),
        );
    await db
        .into(db.blockEdits)
        .insert(
          BlockEditsCompanion.insert(
            blockId: 'fun',
            startMin: today + 20 * 60,
            durMin: 90,
            emoji: const Value('🎸'),
            state: EditState.pending,
            editedAt: 0,
          ),
        );
    for (final (id, title) in [
      ('td1', 'Chapter 4 notes'),
      ('td2', 'Past paper 2023'),
    ]) {
      await db
          .into(db.todos)
          .insert(
            TodosCompanion.insert(
              id: id,
              title: title,
              activityId: Value(acts['Study']),
              createdAt: 1,
              hlc: clock.now(),
            ),
          );
    }
  }

  /// Runs the scene (if any) and the screenshot (if asked) after startup.
  void start() {
    final path = env['DONUT_SCREENSHOT'];
    if (path == null) return;
    Timer(const Duration(seconds: 2), () async {
      await _scene(env['DONUT_SCENE']);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(path).writeAsBytes(bytes!.buffer.asUint8List());
      debugPrint('DONUT_SCREENSHOT written to $path');
      exit(0);
    });
  }

  // ── synthetic gestures ─────────────────────────────────────────────────

  Future<void> _scene(String? scene) async {
    // The day's blocks load asynchronously; wait for the dial to appear.
    (RenderBox, ClockGeometry)? clock;
    for (var i = 0; i < 40 && clock == null; i++) {
      clock = _findClock();
      if (clock == null) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    if (scene == null) return;
    if (clock == null) {
      debugPrint('DONUT_SCENE: no clock found');
      return;
    }
    final (box, geo) = clock;
    final today = Day.today().startMin;
    // [abs] is an absolute minute; find it on the dial as drawn.
    Offset at(int abs) =>
        box.localToGlobal(geo.pointForMinute((abs - today).toDouble()));
    final hub = box.localToGlobal(geo.center);
    const id = 77;
    final binding = GestureBinding.instance;
    var last = Offset.zero;
    void down(Offset p) {
      last = p;
      binding.handlePointerEvent(PointerDownEvent(pointer: id, position: p));
    }

    Future<void> moveTo(Offset p, {int steps = 12}) async {
      for (var i = 1; i <= steps; i++) {
        final q = Offset.lerp(last, p, i / steps)!;
        binding.handlePointerEvent(
          PointerMoveEvent(pointer: id, position: q, delta: q - last),
        );
        last = q;
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }

    Future<void> hold() =>
        Future<void>.delayed(const Duration(milliseconds: 450));

    // A block visible on the current dial to press on.
    final s = geo.spec;
    final target = s.isHour ? today + s.origin + 30 : today + 15 * 60;
    switch (scene) {
      case 'menu':
        down(at(target));
        await hold();
        await moveTo(last + const Offset(-50, -70));
      case 'tasks':
        down(at(target));
        await hold();
        await moveTo(last + const Offset(0, -84));
        await moveTo(last + const Offset(-70, -60));
      case 'label':
        down(at(target));
        await hold();
        await moveTo(last + const Offset(55, -66));
      case 'drag':
        // Draw a new block on the outer ring, following the arc so the
        // finger turns clockwise like a real drag.
        final from = s.isHour ? today + s.origin + 70 : today + 17 * 60;
        final to = from + (s.isHour ? 35 : 150);
        down(at(from));
        for (var i = 1; i <= 24; i++) {
          final q = at(from + ((to - from) * i / 24).round());
          binding.handlePointerEvent(
            PointerMoveEvent(pointer: id, position: q, delta: q - last),
          );
          last = q;
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      case 'select':
        down(at(target));
        binding.handlePointerEvent(PointerUpEvent(pointer: id, position: last));
      case 'picker':
        down(hub);
        await hold();
        await moveTo(hub + const Offset(120, 40));
    }
  }

  /// The on-screen dial, found through the render tree.
  (RenderBox, ClockGeometry)? _findClock() {
    final view = RendererBinding.instance.renderViews.first;
    final screen = Offset.zero & view.size;
    RenderCustomPaint? found;
    void visit(RenderObject o) {
      if (found != null) return;
      if (o is RenderCustomPaint && o.painter is ClockPainter && o.hasSize) {
        final center = o.localToGlobal(o.size.center(Offset.zero));
        if (screen.contains(center)) {
          found = o;
          return;
        }
      }
      o.visitChildren(visit);
    }

    visit(view);
    final box = found;
    if (box == null) return null;
    return (box, ClockGeometry(box.size, (box.painter! as ClockPainter).spec));
  }
}
