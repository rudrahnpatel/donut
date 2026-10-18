import 'dart:math' as math;

import 'package:donut/core/time/day_minutes.dart';
import 'package:donut/features/day/dial_mode.dart';
import 'package:donut/features/radial_menu/hour_picker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = Day(2026, 10, 18);
  final noon = today.startMin + 12 * 60;
  const center = Offset(200, 200);

  HourPickerController make() => HourPickerController(
    center: center,
    base: noon,
    innerRadius: 70,
    outerRadius: 118,
  );

  Offset atHour(int clockPos, double r) {
    final a = clockPos / 12 * 2 * math.pi;
    return center + Offset(math.sin(a), -math.cos(a)) * r;
  }

  test('at 12:45, the inner "4" is 4 PM today', () {
    final p = make()..pointer(atHour(4, 70));
    expect(p.picked, today.startMin + 16 * 60);
  });

  test('the outer "7" is 7 AM tomorrow', () {
    final p = make()..pointer(atHour(7, 118));
    expect(p.picked, today.addDays(1).startMin + 7 * 60);
  });

  test('the inner "12" is the current hour', () {
    final p = make()..pointer(atHour(0, 70));
    expect(p.picked, noon);
  });

  test('releasing near the hub picks nothing', () {
    final p = make()..pointer(center + const Offset(5, 5));
    expect(p.picked, isNull);
  });

  test('labels say which day', () {
    final now = today.startMin + 12 * 60 + 45;
    expect(hourLabel(today.startMin + 16 * 60, now), '4 PM · today');
    expect(
      hourLabel(today.addDays(1).startMin + 7 * 60, now),
      '7 AM · tomorrow',
    );
  });

  test('a mode for the hour containing now is the live hour', () {
    final now = today.startMin + 12 * 60 + 45;
    expect(DialMode.forHour(noon, now).isLive, isTrue);
    expect(DialMode.forHour(noon + 60, now).isLive, isFalse);
  });

  test('swiping days in hour mode keeps the hour of day', () {
    final mode = DialMode.hour(today.startMin + 16 * 60);
    expect(mode.specFor(today, today.startMin).origin, 16 * 60);
    expect(mode.specFor(today.addDays(1), today.startMin).origin, 16 * 60);
  });

  test('the live hour is the clock hour containing now', () {
    final now = today.startMin + 16 * 60 + 25;
    expect(const DialMode.live().specFor(today, now).origin, 16 * 60);
  });
}
