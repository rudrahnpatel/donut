import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/time/day_minutes.dart';
import '../clock/spiral_math.dart';

enum DialLevel { day, hour }

/// What the planner dial is zoomed to.
class DialMode {
  const DialMode.day() : level = DialLevel.day, hourStart = null;

  /// The live hour: the clock hour containing now, following the clock.
  const DialMode.live() : level = DialLevel.hour, hourStart = null;

  /// A fixed clock hour starting at absolute minute [hourStart].
  const DialMode.hour(int this.hourStart) : level = DialLevel.hour;

  final DialLevel level;
  final int? hourStart;

  bool get isLive => level == DialLevel.hour && hourStart == null;

  /// The hour starting at absolute minute [abs], or the live hour if "now"
  /// falls inside it.
  factory DialMode.forHour(int abs, int nowAbs) =>
      nowAbs >= abs && nowAbs < abs + 60
      ? const DialMode.live()
      : DialMode.hour(abs);

  /// The dial to draw on [day]'s page at absolute minute [nowAbs].
  ///
  /// Pages other than the mode's own day show the same hour of their day,
  /// so swiping between days keeps you at "4 PM".
  DialSpec specFor(Day day, int nowAbs) {
    if (level == DialLevel.day) return const DialSpec.day();
    final start = hourStart;
    if (start == null) {
      // The live hour is the clock hour containing now (4:00–5:00 at 4:25),
      // so it looks exactly like browsing to that hour; the part already
      // gone is dimmed. (A rolling "next 60 minutes from the hand" version
      // split entries at the hand and confused the user.)
      return DialSpec.hour(minuteOfDay(nowAbs) ~/ 60 * 60);
    }
    final rel = start - day.startMin;
    if (rel >= 0 && rel < minutesPerDay) return DialSpec.hour(rel);
    return DialSpec.hour(minuteOfDay(start));
  }

  @override
  bool operator ==(Object other) =>
      other is DialMode && other.level == level && other.hourStart == hourStart;

  @override
  int get hashCode => Object.hash(level, hourStart);
}

final dialModeProvider = NotifierProvider<DialModeNotifier, DialMode>(
  DialModeNotifier.new,
);

class DialModeNotifier extends Notifier<DialMode> {
  DialModeNotifier([this._initial = const DialMode.live()]);

  final DialMode _initial;

  @override
  DialMode build() => _initial;

  void set(DialMode m) => state = m;
}

/// Absolute minute of "now", ticking on each minute boundary.
final nowMinuteProvider = StreamProvider<int>((ref) {
  final controller = StreamController<int>();
  Timer? timer;
  void schedule() {
    final now = DateTime.now();
    controller.add(absMinuteOf(now));
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    timer = Timer(next.difference(now), schedule);
  }

  schedule();
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});

/// "4 PM · today", "7 AM · tomorrow", "9 AM · Mon 20".
String hourLabel(int abs, int nowAbs, {bool use24h = false}) {
  final t = formatClock(minuteOfDay(abs), use24h: use24h).replaceAll(':00', '');
  final days = Day.containing(abs).epochDay - Day.containing(nowAbs).epochDay;
  final when = switch (days) {
    0 => 'today',
    1 => 'tomorrow',
    -1 => 'yesterday',
    _ => DateFormat('E d').format(Day.containing(abs).toLocalDateTime()),
  };
  return '$t · $when';
}

/// Short ring caption for an hour dial lap starting at day-relative [u]:
/// "4 PM" on the hour, "12:45" mid-hour (the live hour).
String lapCaption(int u, {bool use24h = false}) {
  final t = formatClock(u, use24h: use24h);
  return u % 60 == 0
      ? t.replaceAll(':00', '')
      : t.replaceAll(RegExp(r' (AM|PM)'), '');
}
