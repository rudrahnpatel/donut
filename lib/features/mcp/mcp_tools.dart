import '../../core/entry_colors.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';
import '../../data/repos/library_repo.dart';
import '../../data/repos/pin_repo.dart';
import '../../data/repos/work_repo.dart';

/// A tool's input was wrong, or what it names doesn't exist. Reported to
/// the model as a tool result with `isError`, so it can correct itself.
class McpToolError implements Exception {
  const McpToolError(this.message);
  final String message;

  @override
  String toString() => message;
}

typedef Json = Map<String, Object?>;

class McpTool {
  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.run,
    this.readOnly = false,
  });

  final String name;
  final String description;
  final Json inputSchema;
  final Future<Object?> Function(Json args) run;
  final bool readOnly;

  Json describe() => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
    'annotations': {'readOnlyHint': readOnly},
  };
}

/// Donut's day as MCP tools. Every write goes through the same repo calls
/// the dial uses (`DayPage` in day_screen.dart), so HLC stamps, sync,
/// reminders and the live UI all behave as if the user made the change:
/// outside plan mode an edit saves instantly; in plan mode (or for an entry
/// that is already a sketch) it lands in the draft overlay for ✓ / ✕.
class DonutMcpTools {
  DonutMcpTools({
    required this.blocks,
    required this.pins,
    required this.library,
    required this.work,
    bool Function()? planModeOn,
    DateTime Function()? now,
  }) : _planModeOn = planModeOn ?? (() => false),
       _now = now ?? DateTime.now;

  final BlockRepo blocks;
  final PinRepo pins;
  final LibraryRepo library;
  final WorkRepo work;
  final bool Function() _planModeOn;
  final DateTime Function() _now;

  static const _sketchNote =
      'Saved as a plan-mode sketch: Donut is in plan mode, so the user keeps '
      'it with ✓ or drops it with ✕ in the app.';

  late final List<McpTool> tools = [
    McpTool(
      name: 'get_day',
      readOnly: true,
      description:
          "Everything on one day of the user's Donut planner: entries (time "
          'blocks), pins (moments like "Reach by 17:00") and minutes worked '
          '(from the desktop work tracker). Times are local wall-clock 24h '
          '"HH:MM". Entries with status "draft" are unsaved plan-mode '
          'sketches.',
      inputSchema: _object({
        'date': _date('The day, YYYY-MM-DD. Defaults to today.'),
      }),
      run: _getDay,
    ),
    McpTool(
      name: 'list_blocks',
      readOnly: true,
      description:
          'Entries (time blocks) overlapping a range of days, oldest first. '
          'Use get_day for a single day with its pins.',
      inputSchema: _object(
        {
          'from_date': _date('First day, YYYY-MM-DD.'),
          'to_date': _date(
            'Last day (inclusive), YYYY-MM-DD; at most 62 days '
            'after from_date.',
          ),
        },
        required: ['from_date', 'to_date'],
      ),
      run: _listBlocks,
    ),
    McpTool(
      name: 'add_block',
      description:
          'Adds an entry (a time block) to the day. Give an end time or a '
          'duration. An end at or before the start means the next day (e.g. '
          '23:00–01:00). Overlapping other entries is allowed; check with '
          'get_day or find_free_slots first if that matters. Outside plan '
          "mode it saves instantly (it syncs and reminds like one drawn on "
          'the dial); in plan mode it becomes a sketch the user approves.',
      inputSchema: _object(
        {
          'date': _date('Day the entry starts, YYYY-MM-DD.'),
          'start': _time('Start time, "HH:MM" 24h local time.'),
          'end': _time('End time, "HH:MM" 24h ("24:00" for midnight).'),
          'duration_minutes': _int(
            'Length in minutes (1–1440), instead of '
            'end.',
          ),
          'label': _str('What the entry is, e.g. "Dentist" or "Deep work".'),
          'activity': _str(
            'An activity from list_activities, by name or id. '
            "Its colour and emoji then show on the dial.",
          ),
          'emoji': _str('One emoji for the entry.'),
          'color': _str(
            '"#RRGGBB". Omit to let Donut pick one that differs '
            'from neighbouring entries.',
          ),
          'sketch': {
            'type': 'boolean',
            'description':
                'Add it as a plan-mode sketch the user must '
                'approve with ✓, even outside plan mode. Use for '
                'suggestions.',
          },
        },
        required: ['date', 'start'],
      ),
      run: _addBlock,
    ),
    McpTool(
      name: 'update_block',
      description:
          'Changes an entry: move it (date and/or start keep its length), '
          'resize it (end or duration_minutes), or change its label, '
          'activity, emoji or colour. Only the fields given change; an empty '
          'string clears label, activity or emoji.',
      inputSchema: _object(
        {
          'id': _str('The entry id from get_day / list_blocks.'),
          'date': _date(
            'New day, YYYY-MM-DD (keeps the time unless start is '
            'given).',
          ),
          'start': _time('New start, "HH:MM".'),
          'end': _time('New end, "HH:MM" (at or before start = next day).'),
          'duration_minutes': _int('New length in minutes (1–1440).'),
          'label': _str('New label; "" clears it.'),
          'activity': _str('Activity name or id; "" clears it.'),
          'emoji': _str('New emoji; "" clears it.'),
          'color': _str('"#RRGGBB".'),
        },
        required: ['id'],
      ),
      run: _updateBlock,
    ),
    McpTool(
      name: 'delete_block',
      description:
          'Removes an entry. A saved entry is tombstoned (and the deletion '
          'syncs); in plan mode it is struck as a sketch until ✓.',
      inputSchema: _object({'id': _str('The entry id.')}, required: ['id']),
      run: _deleteBlock,
    ),
    McpTool(
      name: 'find_free_slots',
      readOnly: true,
      description:
          'Gaps between entries on a day that are at least min_duration '
          'long, within an optional window. For today the window starts now '
          'unless "from" is given.',
      inputSchema: _object({
        'date': _date('The day, YYYY-MM-DD. Defaults to today.'),
        'min_duration_minutes': _int('Shortest useful gap (default 30).'),
        'from': _time('Window start, "HH:MM" (default 00:00 or now).'),
        'to': _time('Window end, "HH:MM" (default 24:00).'),
      }),
      run: _freeSlots,
    ),
    McpTool(
      name: 'list_activities',
      readOnly: true,
      description:
          "The user's activities (Library tasks like Work, Gym, Study) with "
          'their emoji and colour, for the activity field of add_block.',
      inputSchema: _object({}),
      run: (_) async => {
        'activities': [
          for (final a in await library.watchActivities().first)
            {
              'id': a.id,
              'name': a.name,
              'emoji': a.emoji,
              'color': _hex(a.color),
            },
        ],
      },
    ),
    McpTool(
      name: 'add_pin',
      description:
          'Pins a moment to plan around, e.g. "Reach by 09:00" at the '
          'office or a "Meeting at 14:00". Donut reminds 10 minutes before '
          'a saved pin.',
      inputSchema: _object(
        {
          'date': _date('YYYY-MM-DD.'),
          'time': _time('"HH:MM" 24h local time.'),
          'kind': {
            'type': 'string',
            'enum': ['reach_by', 'meeting_at', 'leave_by', 'custom'],
            'description':
                'reach_by / meeting_at / leave_by, or custom '
                'with a label (default custom).',
          },
          'label': _str('Text for a custom pin, e.g. "train leaves".'),
        },
        required: ['date', 'time'],
      ),
      run: _addPin,
    ),
    McpTool(
      name: 'delete_pin',
      description: 'Removes a pin by id (from get_day).',
      inputSchema: _object({'id': _str('The pin id.')}, required: ['id']),
      run: _deletePin,
    ),
  ];

  // ── tools ──────────────────────────────────────────────────────────────

  Future<Object?> _getDay(Json a) async {
    final day = _optDay(a, 'date') ?? Day.fromDateTime(_now());
    final plan = await blocks.loadDay(day);
    final acts = await _activities();
    final dayPins = await pins.watchRange(day.startMin, day.endMin).first;
    final sessions = await work.watchRange(day.startMin, day.endMin).first;
    final isToday = day == Day.fromDateTime(_now());
    return {
      'date': day.iso,
      'weekday': _weekdays[day.weekday - 1],
      if (isToday) 'now': _clock(absMinuteOf(_now())),
      'plan_mode': await _planning(),
      'entries': [for (final b in plan.onDay) _block(b, acts)],
      'pins': [for (final p in dayPins) _pin(p)],
      'worked_minutes': workedMinutes(sessions, day.startMin, day.endMin),
    };
  }

  Future<Object?> _listBlocks(Json a) async {
    final from = _day(a, 'from_date');
    final to = _day(a, 'to_date');
    if (to < from) throw const McpToolError('to_date is before from_date.');
    if (to.epochDay - from.epochDay > 62) {
      throw const McpToolError('At most 62 days at a time.');
    }
    final acts = await _activities();
    final list = await blocks
        .watchEffectiveInRange(from.startMin, to.endMin)
        .first;
    return {
      'from_date': from.iso,
      'to_date': to.iso,
      'entries': [for (final b in list) _block(b, acts)],
    };
  }

  Future<Object?> _addBlock(Json a) async {
    final day = _day(a, 'date');
    final start = day.startMin + _minute(a, 'start');
    final end =
        _endFor(a, start) ??
        (throw const McpToolError('Give an end time or duration_minutes.'));
    final acts = await _activities();
    final activity = _activityArg(a, acts);
    final label = _text(a, 'label');
    final emoji = _text(a, 'emoji');
    var color = _colorArg(a);
    if (color == null) {
      // As `DayPage._colorFor`: differ from the entries it touches.
      final existing = (await blocks.loadDay(day)).blocks;
      color = pickEntryColor(
        [
          for (final b in existing)
            (
              start: b.startMin,
              end: b.endMin,
              color: b.color ?? fallbackEntryColor(b.id),
            ),
        ],
        start,
        end,
        seed: existing.length,
      );
    }
    final sketch = a['sketch'] == true || await _planning();
    final String id;
    if (sketch) {
      id = (await blocks.create(
        start,
        end,
        emoji: emoji,
        activityId: activity?.id,
        note: label,
        color: color,
      )).$1;
    } else {
      id = await blocks.createSaved(
        start,
        end,
        emoji: emoji,
        activityId: activity?.id,
        note: label,
        color: color,
      );
    }
    final b = (await blocks.find(id))!;
    return {'added': _block(b, acts), if (sketch) 'note': _sketchNote};
  }

  Future<Object?> _updateBlock(Json a) async {
    final id = _reqStr(a, 'id');
    final current = await blocks.find(id);
    if (current == null) throw McpToolError('No entry with id $id.');
    final acts = await _activities();

    var start = current.startMin;
    var dur = current.durMin;
    if (a['date'] != null || a['start'] != null) {
      final day = _optDay(a, 'date') ?? Day.containing(current.startMin);
      final minute = a['start'] != null
          ? _minute(a, 'start')
          : minuteOfDay(current.startMin);
      start = day.startMin + minute;
    }
    final end = _endFor(a, start);
    if (end != null) dur = end - start;

    final next = PlanBlock(
      id: current.id,
      startMin: start,
      durMin: dur,
      emoji: a.containsKey('emoji') ? _text(a, 'emoji') : current.emoji,
      activityId: a.containsKey('activity')
          ? _activityArg(a, acts)?.id
          : current.activityId,
      note: a.containsKey('label') ? _text(a, 'label') : current.note,
      color: _colorArg(a) ?? current.color,
      seriesId: current.seriesId,
    );
    // As `DayPage._update`: a sketch stays a sketch.
    final sketch = current.status != BlockStatus.saved || await _planning();
    if (sketch) {
      await blocks.update(id, (_) => next);
    } else {
      await blocks.updateSaved(id, (_) => next);
    }
    return {
      'updated': _block((await blocks.find(id))!, acts),
      if (sketch) 'note': _sketchNote,
    };
  }

  Future<Object?> _deleteBlock(Json a) async {
    final id = _reqStr(a, 'id');
    final current = await blocks.find(id);
    if (current == null) throw McpToolError('No entry with id $id.');
    final acts = await _activities();
    final sketch = current.status != BlockStatus.saved || await _planning();
    if (sketch) {
      await blocks.delete(id);
    } else {
      await blocks.deleteSaved(id);
    }
    return {
      'deleted': _block(current, acts),
      if (sketch && current.status == BlockStatus.saved)
        'note': 'Struck in plan mode: it goes when the user ticks ✓.',
    };
  }

  Future<Object?> _freeSlots(Json a) async {
    final today = Day.fromDateTime(_now());
    final day = _optDay(a, 'date') ?? today;
    final minLen = _optInt(a, 'min_duration_minutes') ?? 30;
    if (minLen < 1) throw const McpToolError('min_duration_minutes < 1.');
    var from = day.startMin + (a['from'] != null ? _minute(a, 'from') : 0);
    if (a['from'] == null && day == today) {
      from = absMinuteOf(_now());
    }
    final to =
        day.startMin +
        (a['to'] != null ? _minute(a, 'to', allow24: true) : minutesPerDay);
    final busy = [
      for (final b in (await blocks.loadDay(day)).blocks)
        if (b.overlaps(from, to)) (b.startMin, b.endMin),
    ]..sort((x, y) => x.$1.compareTo(y.$1));
    final slots = <Json>[];
    var cursor = from;
    void gap(int until) {
      if (until - cursor >= minLen) {
        slots.add({
          'start': _clock(cursor),
          'end': until == day.endMin ? '24:00' : _clock(until),
          'duration_minutes': until - cursor,
        });
      }
    }

    for (final (s, e) in busy) {
      if (s > cursor) gap(s);
      if (e > cursor) cursor = e;
    }
    if (to > cursor) gap(to);
    return {'date': day.iso, 'free': slots};
  }

  Future<Object?> _addPin(Json a) async {
    final day = _day(a, 'date');
    final at = day.startMin + _minute(a, 'time');
    final kindName = (a['kind'] as String?) ?? 'custom';
    final kind = switch (kindName) {
      'reach_by' || 'reachBy' => PinKind.reachBy,
      'meeting_at' || 'meetingAt' => PinKind.meetingAt,
      'leave_by' || 'leaveBy' => PinKind.leaveBy,
      'custom' => PinKind.custom,
      _ => throw McpToolError('Unknown pin kind "$kindName".'),
    };
    final label = _text(a, 'label');
    if (kind == PinKind.custom && label == null) {
      throw const McpToolError('A custom pin needs a label.');
    }
    final sketch = await _planning();
    final id = await pins.create(at, kind, label: label, draft: sketch);
    return {
      'added': _pin((await pins.find(id))!),
      if (sketch) 'note': _sketchNote,
    };
  }

  Future<Object?> _deletePin(Json a) async {
    final id = _reqStr(a, 'id');
    final pin = await pins.find(id);
    if (pin == null) throw McpToolError('No pin with id $id.');
    await pins.delete(id);
    return {'deleted': _pin(pin)};
  }

  // ── helpers ────────────────────────────────────────────────────────────

  /// Plan mode, as `planningProvider`: switched on, or sketches waiting.
  Future<bool> _planning() async =>
      _planModeOn() ||
      await blocks.watchDraftCount().first > 0 ||
      await pins.watchDraftCount().first > 0;

  Future<Map<String, ActivityRow>> _activities() async => {
    for (final a in await library.watchActivities(includeArchived: true).first)
      a.id: a,
  };

  ActivityRow? _activityArg(Json a, Map<String, ActivityRow> acts) {
    final v = _text(a, 'activity');
    if (v == null) return null;
    final live = acts.values.where((x) => !x.archived);
    final hit =
        acts[v] ??
        live.where((x) => x.name.toLowerCase() == v.toLowerCase()).firstOrNull;
    if (hit == null) {
      throw McpToolError(
        'No activity "$v". Known: ${live.map((x) => x.name).join(', ')}.',
      );
    }
    return hit;
  }

  Json _block(PlanBlock b, Map<String, ActivityRow> acts) {
    final act = b.activityId == null ? null : acts[b.activityId];
    final startDay = Day.containing(b.startMin);
    final endDay = Day.containing(b.endMin - 1);
    return {
      'id': b.id,
      'date': startDay.iso,
      'start': _clock(b.startMin),
      'end': minuteOfDay(b.endMin) == 0 && endDay == startDay
          ? '24:00'
          : _clock(b.endMin),
      if (endDay != startDay) 'end_date': Day.containing(b.endMin).iso,
      'duration_minutes': b.durMin,
      'title': ?b.titleWith(act?.name),
      'label': ?b.note,
      'activity': ?act?.name,
      'emoji': ?(b.emoji ?? act?.emoji),
      'color': _hex(act?.color ?? b.color ?? fallbackEntryColor(b.id)),
      'status': b.status.name,
      if (b.seriesId != null) 'recurring': true,
    };
  }

  Json _pin(PinRow p) => {
    'id': p.id,
    'date': Day.containing(p.atMin).iso,
    'time': _clock(p.atMin),
    'kind': switch (p.pinKind) {
      PinKind.reachBy => 'reach_by',
      PinKind.meetingAt => 'meeting_at',
      PinKind.leaveBy => 'leave_by',
      PinKind.custom => 'custom',
    },
    'title': p.describe(use24h: true),
    if (p.draft) 'status': 'draft',
  };

  /// End from `end` or `duration_minutes`, relative to [start]; null if
  /// neither is given.
  int? _endFor(Json a, int start) {
    if (a['duration_minutes'] != null) {
      final d = _optInt(a, 'duration_minutes')!;
      if (d < 1 || d > minutesPerDay) {
        throw const McpToolError('duration_minutes must be 1–1440.');
      }
      return start + d;
    }
    if (a['end'] == null) return null;
    final m = _minute(a, 'end', allow24: true);
    var end = Day.containing(start).startMin + m;
    if (end <= start) end += minutesPerDay;
    return end;
  }

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String _clock(int absMin) =>
      formatClock(minuteOfDay(absMin), use24h: true);

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static final _timeRe = RegExp(r'^(\d{1,2}):(\d{2})$');
  static final _dateRe = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static int _minute(Json a, String key, {bool allow24 = false}) {
    final v = a[key];
    final m = v is String ? _timeRe.firstMatch(v.trim()) : null;
    if (m != null) {
      final h = int.parse(m[1]!), mm = int.parse(m[2]!);
      if (h == 24 && mm == 0 && allow24) return minutesPerDay;
      if (h < 24 && mm < 60) return h * 60 + mm;
    }
    throw McpToolError('$key must be "HH:MM" (24h), got ${_show(v)}.');
  }

  static Day _day(Json a, String key) =>
      _optDay(a, key) ?? (throw McpToolError('$key is required.'));

  static Day? _optDay(Json a, String key) {
    final v = a[key];
    if (v == null) return null;
    final m = v is String ? _dateRe.firstMatch(v.trim()) : null;
    if (m != null) {
      final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
      final day = Day(y, mo, d);
      if (day.month == mo && day.day == d) return day;
    }
    throw McpToolError('$key must be a date "YYYY-MM-DD", got ${_show(v)}.');
  }

  static int? _optInt(Json a, String key) {
    final v = a[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is double && v == v.roundToDouble()) return v.toInt();
    if (v is String && int.tryParse(v) != null) return int.parse(v);
    throw McpToolError('$key must be a whole number, got ${_show(v)}.');
  }

  static String _reqStr(Json a, String key) =>
      _text(a, key) ?? (throw McpToolError('$key is required.'));

  /// A trimmed string, null when missing or empty.
  static String? _text(Json a, String key) {
    final v = a[key];
    if (v == null) return null;
    if (v is! String) throw McpToolError('$key must be a string.');
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static int? _colorArg(Json a) {
    final v = _text(a, 'color');
    if (v == null) return null;
    final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(v);
    if (m == null) throw McpToolError('color must be "#RRGGBB", got "$v".');
    return 0xFF000000 | int.parse(m[1]!, radix: 16);
  }

  static String _show(Object? v) => v is String ? '"$v"' : '$v';

  static Json _object(Json props, {List<String> required = const []}) => {
    'type': 'object',
    'properties': props,
    if (required.isNotEmpty) 'required': required,
    'additionalProperties': false,
  };

  static Json _str(String d) => {'type': 'string', 'description': d};

  static Json _int(String d) => {'type': 'integer', 'description': d};

  static Json _date(String d) => {
    'type': 'string',
    'pattern': r'^\d{4}-\d{2}-\d{2}$',
    'description': d,
  };

  static Json _time(String d) => {
    'type': 'string',
    'pattern': r'^\d{1,2}:\d{2}$',
    'description': d,
  };
}
