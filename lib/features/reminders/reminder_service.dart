import 'dart:async';
import 'dart:math' as math;
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
    this.untilMin,
    this.alert = true,
  });

  final int id;
  final int atMin;
  final String title;
  final String body;

  /// For an entry under way: the minute it ends. On Android the
  /// notification then stays up counting down to it (the system ticks the
  /// timer) and goes away at the end.
  final int? untilMin;

  /// Sound and heads-up; off for a countdown that follows a heads-up.
  final bool alert;

  bool get isLive => untilMin != null;

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.id == id &&
      other.atMin == atMin &&
      other.title == title &&
      other.body == body &&
      other.untilMin == untilMin &&
      other.alert == alert;

  @override
  int get hashCode => Object.hash(id, atMin, title, body, untilMin, alert);
}

/// How early a pin ("Reach by 4:55") notifies, whatever the entries' lead.
const pinLeadMin = 10;

/// Reminders for saved entries and [pins] within [horizonMin] minutes of
/// [nowMin]. Drafts never remind.
///
/// - [leadMin] > 0: a heads-up that many minutes before an entry starts.
/// - At the start, a live countdown to the entry's end (the reminder
///   itself when there is no lead; silent after a heads-up). It shares the
///   heads-up's id, so it takes its place. An entry already under way gets
///   its countdown right away, silently.
/// - Pins: a heads-up [pinLeadMin] minutes early.
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
  final livePins = [
    for (final p in pins)
      if (!p.draft && !p.deleted) p,
  ]..sort((a, b) => a.atMin.compareTo(b.atMin));
  String clock(int abs) => formatClock(minuteOfDay(abs), use24h: use24h);
  for (final b in saved) {
    if (b.status != BlockStatus.saved) continue;
    if (b.endMin <= nowMin || b.startMin > nowMin + horizonMin) continue;
    final activity = activities[b.activityId];
    final name = b.titleWith(activity?.name);
    final emoji = activity == null ? '' : '${activity.emoji} ';
    final title = name == null ? '${emoji}Up next' : '$emoji$name';
    final id = _stableId(b.id);
    final started = b.startMin <= nowMin;
    final headsUp = b.startMin - leadMin;
    if (leadMin > 0 && headsUp > nowMin) {
      out.add(
        Reminder(
          id: id,
          atMin: headsUp,
          title: title,
          body: '${clock(b.startMin)} – ${clock(b.endMin)} · in $leadMin min',
        ),
      );
    }
    // The next pin while it runs or soon after ("Reach by 4:55 PM").
    final pin = livePins
        .where(
          (p) =>
              p.atMin > math.max(b.startMin, nowMin) &&
              p.atMin <= b.endMin + 60,
        )
        .firstOrNull;
    out.add(
      Reminder(
        id: id,
        atMin: started ? nowMin : b.startMin,
        title: title,
        body: [
          'Ends ${clock(b.endMin)}',
          if (pin != null)
            '${pin.pinKind.glyph} ${pin.describe(use24h: use24h)}',
        ].join(' · '),
        untilMin: b.endMin,
        alert: leadMin == 0 && !started,
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

  /// Ids of countdowns this run has put up, so ones whose entry went away
  /// can be taken down.
  final _shownLive = <int>{};

  /// The last notification button tapped (e.g. `late:10`), for the day
  /// screen to act on; it resets it to null once handled. Buttons open
  /// the app, so it is on screen to show what changed.
  final action = ValueNotifier<String?>(null);

  void _onResponse(NotificationResponse r) {
    if (r.actionId != null) action.value = r.actionId;
  }

  /// A countdown: stays up, the system ticks the time left, and it goes
  /// away when the entry ends. [from] is when it appears.
  NotificationDetails _liveDetails(Reminder r, int from) {
    final ends = localDateTimeOf(r.untilMin!);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        r.alert ? 'entries' : 'now',
        r.alert ? 'Entry reminders' : 'Happening now',
        channelDescription: r.alert
            ? 'A nudge when a saved entry starts'
            : 'The entry under way, counting down to its end',
        importance: r.alert ? Importance.high : Importance.low,
        priority: r.alert ? Priority.high : Priority.low,
        icon: 'ic_stat_donut',
        ongoing: true,
        onlyAlertOnce: true,
        usesChronometer: true,
        chronometerCountDown: true,
        when: ends.millisecondsSinceEpoch,
        timeoutAfter: math.max(1, r.untilMin! - from) * 60000,
        category: AndroidNotificationCategory.progress,
        actions: const [
          AndroidNotificationAction(
            'late:5',
            '+5 min late',
            showsUserInterface: true,
            cancelNotification: false,
          ),
          AndroidNotificationAction(
            'late:10',
            '+10 min late',
            showsUserInterface: true,
            cancelNotification: false,
          ),
        ],
      ),
      linux: const LinuxNotificationDetails(),
    );
  }

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
      onDidReceiveNotificationResponse: _onResponse,
    );
    // A button that launched the app from closed.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
      _onResponse(response);
    }
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

  /// Replaces every scheduled reminder with [reminders]. Notifications
  /// already showing stay; a countdown under way is refreshed in place, and
  /// one whose entry is gone is taken down.
  Future<void> apply(List<Reminder> reminders) async {
    if (!_ready) return;
    final now = nowAbsMinute();
    _pending = [
      for (final r in reminders)
        if (r.atMin > now) r,
    ];
    if (!_android) return;
    await _plugin.cancelAllPendingNotifications();
    final running = [
      for (final r in reminders)
        if (r.isLive && r.atMin <= now && r.untilMin! > now) r,
    ];
    for (final id in _shownLive.difference({for (final r in running) r.id})) {
      await _plugin.cancel(id: id);
    }
    _shownLive
      ..clear()
      ..addAll(running.map((r) => r.id));
    for (final r in running) {
      await _plugin.show(
        id: r.id,
        title: r.title,
        body: r.body,
        notificationDetails: _liveDetails(r, now),
      );
    }
    for (final r in _pending) {
      try {
        await _plugin.zonedSchedule(
          id: r.id,
          scheduledDate: tz.TZDateTime.from(localDateTimeOf(r.atMin), tz.local),
          notificationDetails: r.isLive ? _liveDetails(r, r.atMin) : _details,
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

  void dispose() {
    _ticker?.cancel();
    action.dispose();
  }
}
