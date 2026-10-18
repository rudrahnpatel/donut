import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';

/// One notification to show at absolute floating minute [atMin].
class Reminder {
  const Reminder({
    required this.id,
    required this.atMin,
    required this.title,
    required this.body,
  });

  final int id;
  final int atMin;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.id == id &&
      other.atMin == atMin &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, atMin, title, body);
}

/// Reminders for saved entries starting after [nowMin] and within
/// [horizonMin] minutes, [leadMin] minutes early. Drafts never remind.
List<Reminder> planReminders(
  Iterable<PlanBlock> saved,
  Map<String, ActivityRow> activities, {
  required int nowMin,
  required int leadMin,
  bool use24h = false,
  int horizonMin = 48 * 60,
}) {
  final out = <Reminder>[];
  for (final b in saved) {
    if (b.status != BlockStatus.saved) continue;
    final at = b.startMin - leadMin;
    if (at <= nowMin || at > nowMin + horizonMin) continue;
    final activity = activities[b.activityId];
    final name = b.titleWith(activity?.name);
    final emoji = activity == null ? '' : '${activity.emoji} ';
    final times =
        '${formatClock(minuteOfDay(b.startMin), use24h: use24h)} – '
        '${formatClock(minuteOfDay(b.endMin), use24h: use24h)}';
    out.add(
      Reminder(
        id: _stableId(b.id),
        atMin: at,
        title: name == null ? '${emoji}Up next' : '$emoji$name',
        body: leadMin == 0 ? times : '$times · in $leadMin min',
      ),
    );
  }
  out.sort((a, b) => a.atMin.compareTo(b.atMin));
  return out;
}

/// A 31-bit notification id that stays the same for an entry.
int _stableId(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7FFFFFFF;
  }
  return h;
}

/// Shows reminders on Android (scheduled with exact alarms, so they fire
/// with the app closed) and on Linux/Windows (an in-app check every 30 s,
/// so they fire while the app or its window is running).
class ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  List<Reminder> _pending = const [];
  Timer? _ticker;
  int _lastCheck = nowAbsMinute();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'entries',
      'Entry reminders',
      channelDescription: 'A nudge when a saved entry starts',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_donut',
    ),
    linux: LinuxNotificationDetails(),
  );

  bool get _android => !kIsWeb && Platform.isAndroid;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      debugPrint('Reminders: timezone lookup failed ($e); using UTC');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_donut'),
        linux: LinuxInitializationSettings(defaultActionName: 'Open Donut'),
      ),
    );
    _ready = true;
    if (!_android) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _fireDue());
    }
  }

  /// Asks for notification permission (Android 13+); harmless elsewhere.
  Future<void> requestPermission() async {
    if (!_android) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Replaces every scheduled reminder with [reminders].
  Future<void> apply(List<Reminder> reminders) async {
    if (!_ready) return;
    final now = nowAbsMinute();
    _pending = [
      for (final r in reminders)
        if (r.atMin > now) r,
    ];
    if (!_android) return;
    await _plugin.cancelAll();
    for (final r in _pending) {
      try {
        await _plugin.zonedSchedule(
          id: r.id,
          scheduledDate: tz.TZDateTime.from(localDateTimeOf(r.atMin), tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          title: r.title,
          body: r.body,
        );
      } catch (e) {
        debugPrint('Reminders: could not schedule ${r.title}: $e');
      }
    }
  }

  /// Desktop: shows reminders whose time passed since the last check.
  /// Comparing against the wall clock (not timer counts) keeps this right
  /// across suspend/resume.
  void _fireDue() {
    final now = nowAbsMinute();
    for (final r in _pending) {
      if (r.atMin > _lastCheck && r.atMin <= now) {
        _plugin.show(
          id: r.id,
          title: r.title,
          body: r.body,
          notificationDetails: _details,
        );
      }
    }
    _lastCheck = now;
  }

  void dispose() => _ticker?.cancel();
}
