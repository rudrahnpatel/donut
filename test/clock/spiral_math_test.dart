import 'dart:math' as math;

import 'package:donut/features/clock/spiral_math.dart';
import 'package:flutter_test/flutter_test.dart';

double dayAngle(double minutes) => minutes / 720 * twoPi;
double hourAngle(double minutes) => minutes / 60 * twoPi;

void main() {
  group('clockAngle', () {
    const c = Offset(100, 100);
    test('12 o\'clock is 0, 3 o\'clock is π/2, 9 o\'clock is 3π/2', () {
      expect(clockAngle(const Offset(100, 0), c), closeTo(0, 1e-9));
      expect(clockAngle(const Offset(200, 100), c), closeTo(math.pi / 2, 1e-9));
      expect(clockAngle(const Offset(100, 200), c), closeTo(math.pi, 1e-9));
      expect(
        clockAngle(const Offset(0, 100), c),
        closeTo(3 * math.pi / 2, 1e-9),
      );
    });
  });

  group('day dial', () {
    const day = DialSpec.day();

    test('AM on inner, PM on outer, outside the day on overflow', () {
      expect(day.laneOf(0), Lane.inner);
      expect(day.laneOf(719), Lane.inner);
      expect(day.laneOf(720), Lane.outer);
      expect(day.laneOf(1439), Lane.outer);
      expect(day.laneOf(1440), Lane.after);
      expect(day.laneOf(-30), Lane.before);
    });

    test('3 PM and 3 AM share an angle; yesterday 11 PM sits at 11', () {
      expect(day.angleOf(900), closeTo(day.angleOf(180), 1e-9));
      expect(day.angleOf(180), closeTo(math.pi / 2, 1e-9));
      expect(day.angleOf(-60), closeTo(dayAngle(660), 1e-9));
    });

    test('11:30 → 13:00 splits at noon', () {
      final p = day.pieces(690, 780);
      expect(p.map((e) => e.lane), [Lane.inner, Lane.outer]);
      expect(p[0].endMin, 720);
      expect(p[1].startAngle, closeTo(0, 1e-9));
    });

    test('23:00 → 07:00 next day spills onto the overflow lane', () {
      final p = day.pieces(1380, 1860);
      expect(p.map((e) => e.lane), [Lane.outer, Lane.after]);
      expect(p[1].sweep, closeTo(dayAngle(420), 1e-9));
    });

    test('a block from yesterday shows its past part on the lane', () {
      expect(day.pieces(-60, 420).map((e) => e.lane), [
        Lane.before,
        Lane.inner,
      ]);
    });

    test('overflow longer than a turn is capped', () {
      expect(day.pieces(1440, 1440 + 900).single.sweep, closeTo(twoPi, 1e-9));
    });

    test('minuteAt inverts the placement', () {
      expect(day.minuteAt(dayAngle(180), 0), closeTo(180, 1e-9));
      expect(day.minuteAt(dayAngle(180), 1), closeTo(900, 1e-9));
    });
  });

  group('hour dial, fixed 4 PM', () {
    const hour = DialSpec.hour(16 * 60);

    test('the "1" is :05 on both rings; inner is 4 PM, outer 5 PM', () {
      expect(hour.minuteAt(hourAngle(5), 0), closeTo(16 * 60 + 5, 1e-9));
      expect(hour.minuteAt(hourAngle(5), 1), closeTo(17 * 60 + 5, 1e-9));
      expect(hour.laneOf(16 * 60 + 59), Lane.inner);
      expect(hour.laneOf(17 * 60), Lane.outer);
      expect(hour.laneOf(18 * 60), Lane.after);
      expect(hour.laneOf(15 * 60 + 55), Lane.before);
    });

    test('4:40 → 5:20 is one block split at the top', () {
      final p = hour.pieces(16 * 60 + 40, 17 * 60 + 20);
      expect(p.map((e) => e.lane), [Lane.inner, Lane.outer]);
      expect(p[0].startAngle, closeTo(hourAngle(40), 1e-9));
      expect(p[1].sweep, closeTo(hourAngle(20), 1e-9));
    });

    test('shifting slides both rings by an hour', () {
      final next = hour.shifted(1);
      expect(next.origin, 17 * 60);
      expect(next.laneOf(17 * 60 + 30), Lane.inner);
    });
  });

  group('hour dial, live at 12:45', () {
    const live = DialSpec.hour(12 * 60 + 45);

    test('the seam is at the minute hand', () {
      expect(live.seamAngle, closeTo(hourAngle(45), 1e-9));
    });

    test('ahead of the hand is this hour, behind it is next hour', () {
      expect(live.minuteAt(hourAngle(50), 0), closeTo(12 * 60 + 50, 1e-9));
      expect(live.minuteAt(hourAngle(10), 0), closeTo(13 * 60 + 10, 1e-9));
      expect(live.minuteAt(hourAngle(10), 1), closeTo(14 * 60 + 10, 1e-9));
    });

    test('pieces split at the seam, not at 12 o\'clock', () {
      final p = live.pieces(13 * 60 + 30, 14 * 60);
      expect(p.map((e) => e.lane), [Lane.inner, Lane.outer]);
      expect(p[0].endMin, 13 * 60 + 45);
    });
  });

  group('SpiralTracker', () {
    void sweep(SpiralTracker t, double from, double to, {int steps = 60}) {
      for (var i = 1; i <= steps; i++) {
        t.update((from + (to - from) * i / steps) % twoPi);
      }
    }

    test('day: crossing noon continues onto the outer ring', () {
      final t = SpiralTracker(startU: 660, theta: dayAngle(660), turn: 720);
      sweep(t, dayAngle(660), dayAngle(780));
      expect(t.u, closeTo(780, 1e-6));
    });

    test('day: dragging backwards past midnight goes into yesterday', () {
      final t = SpiralTracker(startU: 60, theta: dayAngle(60), turn: 720);
      sweep(t, dayAngle(60), dayAngle(-60));
      expect(t.u, closeTo(-60, 1e-6));
    });

    test('hour: one full turn is sixty minutes', () {
      final t = SpiralTracker(
        startU: 16 * 60 + 40,
        theta: hourAngle(40),
        turn: 60,
      );
      sweep(t, hourAngle(40), hourAngle(40) + twoPi, steps: 120);
      expect(t.u, closeTo(17 * 60 + 40, 1e-6));
    });
  });

  group('freeRange', () {
    test('bounded by the nearest neighbours', () {
      expect(freeRange(600, [(480, 540), (700, 760), (100, 200)]), (
        lo: 540,
        hi: 700,
      ));
    });

    test('touching edges are allowed', () {
      expect(freeRange(540, [(480, 540), (600, 660)]), (lo: 540, hi: 600));
    });

    test('inside a block there is no room', () {
      expect(freeRange(500, [(480, 540)]), (lo: 500, hi: 500));
    });
  });

  test('snapMinutes', () {
    expect(snapMinutes(7, 15), 0);
    expect(snapMinutes(8, 15), 15);
    expect(snapMinutes(-8, 15), -15);
    expect(snapMinutes(722.4, 5), 720);
  });
}
