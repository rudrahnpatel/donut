import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:http/http.dart' as http;

import '../../core/time/day_minutes.dart';
import '../../core/time/hlc.dart';
import '../../data/db/app_database.dart';

/// Entries that started as events made in Google Calendar: their id is
/// this prefix plus the event's own id.
const _fromGoogle = 'gcal-';

/// The Google event id for an entry: lowercase base32hex (0-9, a-v),
/// 5–1024 characters. UUIDs minus dashes already qualify; anything else is
/// hex-encoded. Deterministic, so retries can never create duplicates. An
/// entry that came from a Google event maps back to that event.
String eventIdFor(String blockId) {
  if (blockId.startsWith(_fromGoogle)) {
    return blockId.substring(_fromGoogle.length);
  }
  final plain = blockId.toLowerCase().replaceAll('-', '');
  if (RegExp(r'^[0-9a-v]{5,1024}$').hasMatch(plain)) return plain;
  return utf8
      .encode(blockId)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

/// A saved entry as a Google Calendar event in the Donut calendar.
cal.Event eventForBlock(
  BlockRow b, {
  String? title,
  required String timeZone,
}) => cal.Event(
  id: eventIdFor(b.id),
  summary: title ?? 'Donut',
  start: cal.EventDateTime(
    dateTime: localDateTimeOf(b.startMin),
    timeZone: timeZone,
  ),
  end: cal.EventDateTime(
    dateTime: localDateTimeOf(b.startMin + b.durMin),
    timeZone: timeZone,
  ),
  status: 'confirmed',
  // The app reminds you itself; don't double up with Google's.
  reminders: cal.EventReminders(useDefault: false),
  extendedProperties: cal.EventExtendedProperties(
    private: {
      'donutId': b.id,
      if (b.color != null) 'color': '${b.color}',
      if (b.activityId != null) 'activityId': b.activityId!,
      if (b.note != null) 'note': b.note!,
    },
  ),
);

/// What an event says an entry should be; null for all-day events, which
/// don't belong on the dial.
({
  String id,
  int startMin,
  int durMin,
  String? note,
  String? activityId,
  int? color,
  bool deleted,
})?
blockFromEvent(cal.Event e) {
  final private = e.extendedProperties?.private ?? const <String, String>{};
  final deleted = e.status == 'cancelled';
  final start = e.start?.dateTime, end = e.end?.dateTime;
  final donutId = private['donutId'];
  if (!deleted && (start == null || end == null)) return null;
  final s = start == null ? 0 : absMinuteOf(start.toLocal());
  final en = end == null ? s : absMinuteOf(end.toLocal());
  return (
    id: donutId ?? '$_fromGoogle${e.id}',
    startMin: s,
    durMin: (en - s).clamp(1, minutesPerDay),
    // An event made in Google Calendar has no label of ours: use its title.
    note: private['note'] ?? (donutId == null ? e.summary : null),
    activityId: private['activityId'],
    color: int.tryParse(private['color'] ?? ''),
    deleted: deleted,
  );
}

/// Results of one calendar run, for the status line.
class CalendarSyncResult {
  const CalendarSyncResult(this.pushed, this.pulled, this.busy);
  final int pushed;
  final int pulled;

  /// Busy times on your other calendars, today and tomorrow, as absolute
  /// floating minutes: the ghost arcs.
  final List<(int, int)> busy;
}

/// Two-way mirror between saved entries and a dedicated "Donut" Google
/// calendar, plus busy times from your other calendars.
class CalendarSync {
  CalendarSync(
    this._db,
    this._clock, {
    required this.titleFor,
    required this.timeZone,
  });

  final AppDatabase _db;
  final HlcClock _clock;
  final String? Function(BlockRow) titleFor;
  final String timeZone;

  static const _calKey = 'gcal_calendar_id';
  static const _pushedKey = 'gcal_pushed_hlc';
  static const _tokenKey = 'gcal_sync_token';

  Future<CalendarSyncResult> run(http.Client client) async {
    final api = cal.CalendarApi(client);
    final calId = await _ensureCalendar(api);
    final pushed = await _push(api, calId);
    final pulled = await _pull(api, calId);
    final busy = await _busy(api, calId);
    return CalendarSyncResult(pushed, pulled, busy);
  }

  /// Finds the Donut calendar (stored id, else by name) or creates it, so a
  /// reinstall never makes a second one.
  Future<String> _ensureCalendar(cal.CalendarApi api) async {
    final stored = await _db.getLocal(_calKey);
    if (stored != null) return stored;
    String? pageToken;
    do {
      final page = await api.calendarList.list(
        pageToken: pageToken,
        minAccessRole: 'owner',
      );
      for (final c in page.items ?? const <cal.CalendarListEntry>[]) {
        if (c.summary == 'Donut' && c.id != null) {
          await _db.setLocal(_calKey, c.id!);
          return c.id!;
        }
      }
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    final created = await api.calendars.insert(
      cal.Calendar(
        summary: 'Donut',
        description: 'Entries from the Donut planner',
        timeZone: timeZone,
      ),
    );
    await _db.setLocal(_calKey, created.id!);
    return created.id!;
  }

  /// Sends every entry changed since the last push. Deletions remove the
  /// event; everything else is an idempotent upsert by deterministic id.
  Future<int> _push(cal.CalendarApi api, String calId) async {
    final since = await _db.getLocal(_pushedKey) ?? '';
    final upTo = _clock.now();
    final changed = await (_db.select(
      _db.blocks,
    )..where((t) => t.hlc.isBiggerThanValue(since))).get();
    var n = 0;
    for (final b in changed) {
      // First push: deleted entries were never sent, so there's nothing to
      // remove.
      if (b.deleted && since.isEmpty) continue;
      final id = eventIdFor(b.id);
      if (b.deleted) {
        try {
          await api.events.delete(calId, id);
        } on cal.DetailedApiRequestError catch (e) {
          if (e.status != 404 && e.status != 410) rethrow;
        }
      } else {
        final event = eventForBlock(b, title: titleFor(b), timeZone: timeZone);
        try {
          await api.events.update(event, calId, id);
        } on cal.DetailedApiRequestError catch (e) {
          if (e.status != 404) rethrow;
          await api.events.insert(event, calId);
        }
      }
      n++;
    }
    await _db.setLocal(_pushedKey, upTo);
    return n;
  }

  /// Applies changes made in Google Calendar since the last pull. An event
  /// wins only if Google changed it after our copy and it actually differs,
  /// so our own pushes don't echo back as edits.
  Future<int> _pull(cal.CalendarApi api, String calId) async {
    var token = await _db.getLocal(_tokenKey);
    var n = 0;
    String? pageToken;
    while (true) {
      final cal.Events page;
      try {
        page = await api.events.list(
          calId,
          syncToken: token,
          pageToken: pageToken,
          showDeleted: true,
          singleEvents: true,
          maxResults: 250,
        );
      } on cal.DetailedApiRequestError catch (e) {
        if (e.status != 410 || token == null) rethrow;
        // Token expired: re-read everything and match by id. Never wipe.
        token = null;
        pageToken = null;
        continue;
      }
      for (final e in page.items ?? const <cal.Event>[]) {
        if (await _applyEvent(e)) n++;
      }
      pageToken = page.nextPageToken;
      if (pageToken == null) {
        if (page.nextSyncToken != null) {
          await _db.setLocal(_tokenKey, page.nextSyncToken!);
        }
        return n;
      }
    }
  }

  Future<bool> _applyEvent(cal.Event e) async {
    final incoming = blockFromEvent(e);
    if (incoming == null) return false;
    final local = await (_db.select(
      _db.blocks,
    )..where((t) => t.id.equals(incoming.id))).getSingleOrNull();
    if (local == null && incoming.deleted) return false;
    if (local != null) {
      final updated = e.updated?.millisecondsSinceEpoch ?? 0;
      if (updated <= Hlc.parse(local.hlc).millis) return false;
      final same =
          local.deleted == incoming.deleted &&
          (incoming.deleted ||
              (local.startMin == incoming.startMin &&
                  local.durMin == incoming.durMin &&
                  local.note == incoming.note &&
                  local.activityId == incoming.activityId));
      if (same) return false;
    }
    await _db
        .into(_db.blocks)
        .insertOnConflictUpdate(
          BlocksCompanion.insert(
            id: incoming.id,
            startMin: incoming.startMin,
            durMin: incoming.durMin,
            note: Value(incoming.note),
            activityId: Value(incoming.activityId),
            color: Value(incoming.color ?? local?.color),
            emoji: Value(local?.emoji),
            seriesId: Value(local?.seriesId),
            detached: Value(local?.seriesId != null),
            deleted: Value(incoming.deleted),
            hlc: _clock.now(),
          ),
        );
    return true;
  }

  /// Busy times on your other calendars for today and tomorrow. Only
  /// free/busy is read, never what the events are.
  Future<List<(int, int)>> _busy(cal.CalendarApi api, String calId) async {
    final today = Day.today();
    final ids = <String>{'primary'};
    try {
      final list = await api.calendarList.list();
      for (final c in list.items ?? const <cal.CalendarListEntry>[]) {
        if (c.id != null && c.id != calId && (c.selected ?? false)) {
          ids.add(c.id!);
        }
      }
    } on cal.DetailedApiRequestError {
      // Fall back to the primary calendar only.
    }
    final response = await api.freebusy.query(
      cal.FreeBusyRequest(
        timeMin: today.toLocalDateTime().toUtc(),
        timeMax: today.addDays(2).toLocalDateTime().toUtc(),
        items: [for (final id in ids) cal.FreeBusyRequestItem(id: id)],
      ),
    );
    final out = <(int, int)>[];
    for (final c
        in (response.calendars ?? const <String, cal.FreeBusyCalendar>{})
            .values) {
      for (final p in c.busy ?? const <cal.TimePeriod>[]) {
        if (p.start == null || p.end == null) continue;
        out.add((
          absMinuteOf(p.start!.toLocal()),
          absMinuteOf(p.end!.toLocal()),
        ));
      }
    }
    return out;
  }
}
