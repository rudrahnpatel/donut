import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';
import '../../data/repos/pin_repo.dart';

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

/// How early a pin ("Reach by 4:55") notifies, whatever the entries' lead.
const pinLeadMin = 10;

/// Reminders for saved entries starting after [nowMin] and within
/// [horizonMin] minutes, [leadMin] minutes early, and for [pins],
/// [pinLeadMin] minutes early. Drafts never remind.
List<Reminder> planReminders(
  Iterable<PlanBlock> saved,
  Map<String, ActivityRow> activities, {
  Iterable<PinRow> pins = const [],
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
  for (final p in pins) {
    if (p.draft || p.deleted) continue;
    final at = p.atMin - pinLeadMin;
    if (at <= nowMin || at > nowMin + horizonMin) continue;
    out.add(
      Reminder(
        id: _stableId('pin:${p.id}'),
        atMin: at,
        title: '${p.pinKind.glyph} ${p.describe(use24h: use24h)}',
        body: 'In $pinLeadMin min',
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
    // The full database, links included: phones may report old names such
    // as "Asia/Calcutta" for Asia/Kolkata.
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      // Any zone at the phone's current offset beats UTC.
      final offset = DateTime.now().timeZoneOffset;
      final match = tz.timeZoneDatabase.locations.values
          .where((l) => l.currentTimeZone.offset == offset)
          .firstOrNull;
      if (match != null) tz.setLocalLocation(match);
      debugPrint(
        'Reminders: timezone lookup failed ($e); using ${match?.name}',
      );
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

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Asks for notification permission (Android 13+); true elsewhere.
  /// False when refused, including when Android no longer shows the prompt.
  Future<bool> requestPermission() async {
    if (!_android) return true;
    return await _androidPlugin?.requestNotificationsPermission() ?? false;
  }

  /// Whether notifications can show; null when unknown (not Android).
  Future<bool?> notificationsAllowed() async {
    if (!_android) return null;
    return _androidPlugin?.areNotificationsEnabled();
  }

  /// Donut's notification settings, for when the prompt no longer shows.
  Future<void> openNotificationSettings() async {
    if (!_android) return;
    await const MethodChannel('donut/system')
        .invokeMethod<void>('openNotificationSettings');
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
