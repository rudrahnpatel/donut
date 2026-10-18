import 'dart:ui';

import 'package:donut/features/clock/clock_geometry.dart';
import 'package:donut/features/clock/clock_gesture_machine.dart';
import 'package:donut/features/clock/spiral_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replays pointer traces through the machine on a 400×400 dial.
class Harness {
  Harness({
    this.spec = const DialSpec.day(),
    List<ClockSpan> spans = const [],
    String? selected,
    int snap = 15,
    bool hub = false,
  }) {
    geo = ClockGeometry(const Size(400, 400), spec);
    machine = ClockGestureMachine(emit: events.add)
      ..geometry = geo
      ..spans = spans
      ..selectedId = selected
      ..snapStep = snap
      ..claimHub = hub;
  }

  final DialSpec spec;
  late final ClockGeometry geo;
  final events = <ClockEvent>[];
  late final ClockGestureMachine machine;

  /// Screen point for day-relative minute [u] on its own ring.
  Offset at(double u) => geo.pointForMinute(u);

  /// Point at the angle of [u] but on a chosen ring radius.
  Offset onRing(double u, Lane lane) =>
      geo.pointAt(spec.angleOf(u), geo.laneMid(lane));

  /// Drags along the dial in small angular steps from [fromU] to [toU],
  /// keeping the finger on [lane]'s radius the whole time.
  void drag(
    double fromU,
    double toU, {
    Lane lane = Lane.inner,
    int steps = 80,
  }) {
    machine.down(onRing(fromU, lane));
    for (var i = 1; i <= steps; i++) {
      machine.move(onRing(fromU + (toU - fromU) * i / steps, lane));
    }
    machine.up();
  }

  T last<T extends ClockEvent>() => events.whereType<T>().last;
}

void main() {
  group('day dial', () {
    test('drag on an empty ring creates a snapped block', () {
      final h = Harness();
      h.drag(9 * 60 + 2, 10 * 60 + 33);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (540, 630));
      expect(h.events.whereType<HapticEvent>(), isNotEmpty);
    });

    test('dragging across noon makes one block spanning both rings', () {
      final h = Harness();
      h.drag(11 * 60, 13 * 60);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (660, 780));
    });

    test('dragging past midnight spills into tomorrow', () {
      final h = Harness();
      h.drag(23 * 60, 25 * 60 + 30, lane: Lane.outer);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (1380, 1530));
    });

    test('dragging backwards creates the block before the anchor', () {
      final h = Harness();
      h.drag(8 * 60, 6 * 60 + 30);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (390, 480));
    });

    test('a drag can run across an existing block (overlap allowed)', () {
      final h = Harness(spans: [const ClockSpan('a', 600, 660)]);
      h.drag(8 * 60, 12 * 60);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (480, 720));
    });

    test('dragging from inside an unselected block draws a new entry', () {
      final h = Harness(spans: [const ClockSpan('a', 600, 660)]);
      h.drag(615, 690);
      expect(h.events.whereType<ChangeEvent>(), isEmpty);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (615, 690));
    });

    test('a short tap on an empty ring reports the minute', () {
      final h = Harness();
      h.machine.down(h.at(300));
      h.machine.up();
      expect(h.last<TapEmptyEvent>().u, closeTo(300, 1));
      expect(h.events.whereType<CreateEvent>(), isEmpty);
    });

    test('hold on an empty spot opens the pin menu at the snapped minute', () {
      final h = Harness();
      final p = h.at(16 * 60 + 52);
      h.machine.down(p);
      expect(h.machine.wantsHoldTimer, isTrue);
      h.machine.holdElapsed();
      final e = h.last<EmptyHoldEvent>();
      expect(e.u, 16 * 60 + 45, reason: '15-minute snap on the day dial');
      expect(e.mouseMode, isFalse);
      expect(h.machine.isInMenu, isTrue);
      h.machine.move(p + const Offset(0, -80));
      h.machine.up();
      expect(h.last<MenuReleaseEvent>().position, p + const Offset(0, -80));
      expect(h.events.whereType<CreateEvent>(), isEmpty);
      expect(h.events.whereType<TapEmptyEvent>(), isEmpty);
    });

    test('moving before the hold still draws an entry', () {
      final h = Harness();
      h.drag(9 * 60, 10 * 60);
      h.machine.holdElapsed(); // A late timer after the drag does nothing.
      expect(h.events.whereType<EmptyHoldEvent>(), isEmpty);
      expect(h.last<CreateEvent>().end, 600);
    });

    test('right-click on an empty spot opens the pin menu in mouse mode', () {
      final h = Harness();
      h.machine.down(h.at(300), mouse: true, secondary: true);
      final e = h.last<EmptyHoldEvent>();
      expect((e.u, e.mouseMode), (300, true));
      expect(h.machine.isIdle, isTrue);
    });

    test('tap on a block selects it', () {
      final h = Harness(spans: [const ClockSpan('a', 600, 660)]);
      h.machine.down(h.at(630));
      h.machine.up();
      expect(h.last<SelectEvent>().id, 'a');
    });

    test('hold on a block opens the menu; release reports position', () {
      final h = Harness(spans: [const ClockSpan('a', 600, 660)]);
      final p = h.at(630);
      h.machine.down(p);
      expect(h.machine.wantsHoldTimer, isTrue);
      h.machine.holdElapsed();
      expect(h.last<MenuOpenEvent>().id, 'a');
      h.machine.move(p + const Offset(0, -90));
      h.machine.up();
      expect(h.last<MenuReleaseEvent>().position, p + const Offset(0, -90));
    });

    test('dragging the selected block body moves it', () {
      final h = Harness(spans: [const ClockSpan('a', 600, 660)], selected: 'a');
      h.drag(630, 690);
      expect(h.events.whereType<MenuOpenEvent>(), isEmpty);
      final c = h.last<ChangeEvent>();
      expect((c.id, c.start, c.end), ('a', 660, 720));
    });

    test('dragging the end handle of the selected block resizes it', () {
      final h = Harness(spans: [const ClockSpan('a', 600, 660)], selected: 'a');
      h.drag(660, 720);
      final c = h.last<ChangeEvent>();
      expect((c.start, c.end), (600, 720));
    });

    test('resize cannot shrink below one snap step', () {
      final h = Harness(spans: [const ClockSpan('a', 600, 660)], selected: 'a');
      h.drag(660, 560);
      final c = h.last<ChangeEvent>();
      expect((c.start, c.end), (600, 615));
    });

    test('right-click on a block opens the menu in mouse mode', () {
      final h = Harness(spans: [const ClockSpan('a', 600, 660)]);
      h.machine.down(h.at(630), mouse: true, secondary: true);
      expect(h.last<MenuOpenEvent>().mouseMode, isTrue);
      expect(h.machine.isIdle, isTrue);
    });

    test('the hub is left to the parent unless claimed', () {
      final h = Harness();
      expect(h.machine.hitTest(h.geo.center), isFalse);
      expect(h.machine.hitTest(h.at(100)), isTrue);
    });
  });

  group('hour dial', () {
    const fourPm = DialSpec.hour(16 * 60);

    test('the travel plan: 4:05–4:10, 4:10–4:15, 4:15–4:55', () {
      final h = Harness(spec: fourPm, snap: 5);
      h.drag(16 * 60 + 5, 16 * 60 + 10);
      final a = h.last<CreateEvent>();
      expect((a.start, a.end), (965, 970));

      h.machine.spans = [ClockSpan('a', a.start, a.end)];
      h.drag(16 * 60 + 10, 16 * 60 + 15);
      final b = h.last<CreateEvent>();
      expect((b.start, b.end), (970, 975));

      h.machine.spans = [
        ClockSpan('a', a.start, a.end),
        ClockSpan('b', b.start, b.end),
      ];
      h.drag(16 * 60 + 15, 16 * 60 + 55);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (975, 1015));
    });

    test('dragging past the top carries into the next hour', () {
      final h = Harness(spec: fourPm, snap: 5);
      h.drag(16 * 60 + 40, 17 * 60 + 20);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (16 * 60 + 40, 17 * 60 + 20));
    });

    test('a sliding dial lets a drag run beyond both rings', () {
      final h = Harness(spec: fourPm, snap: 5);
      h.drag(16 * 60 + 30, 18 * 60 + 30, steps: 200);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (16 * 60 + 30, 18 * 60 + 30));
    });

    test('pressing the outer ring starts in the next hour', () {
      final h = Harness(spec: fourPm, snap: 5);
      h.drag(17 * 60 + 10, 17 * 60 + 25, lane: Lane.outer);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (17 * 60 + 10, 17 * 60 + 25));
    });

    test('live hour at 12:45: behind the hand is next hour', () {
      final h = Harness(spec: const DialSpec.hour(12 * 60 + 45), snap: 5);
      h.drag(13 * 60 + 10, 13 * 60 + 25);
      final c = h.last<CreateEvent>();
      expect((c.start, c.end), (13 * 60 + 10, 13 * 60 + 25));
    });

    test('hub: tap, hold for the picker, swipe for next hour', () {
      final h = Harness(spec: fourPm, hub: true);
      final hub = h.geo.center;
      expect(h.machine.hitTest(hub), isTrue);

      h.machine.down(hub);
      h.machine.up();
      expect(h.events.last, isA<HubTapEvent>());

      h.machine.down(hub);
      expect(h.machine.wantsHoldTimer, isTrue);
      h.machine.holdElapsed();
      expect(h.last<HubHoldEvent>().position, hub);
      h.machine.move(hub + const Offset(80, 0));
      h.machine.up();
      expect(h.last<MenuReleaseEvent>().position, hub + const Offset(80, 0));

      h.machine.down(hub);
      h.machine.move(hub + const Offset(-30, 0));
      h.machine.move(hub + const Offset(-70, 5));
      h.machine.up();
      expect(h.last<HubSwipeEvent>().direction, 1);
    });
  });
}
