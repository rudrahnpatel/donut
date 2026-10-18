/// Floating local wall-clock time, in whole minutes.
///
/// Blocks are stored as an absolute minute index (`epochDay * 1440 + minuteOfDay`)
/// in local wall-clock terms, not as UTC instants: "gym at 7:00" stays at 7:00
/// across DST changes and time-zone travel, which is what a day plan means.
/// A block that spills past midnight is simply `start + duration > day end`.
/// Real instants are derived only at the edges (reminders, Google sync).
library;

const int minutesPerDay = 1440;
const int minutesPerHalfDay = 720;

/// A calendar date with no time or zone.
class Day implements Comparable<Day> {
  const Day.fromEpochDay(this.epochDay);

  factory Day(int year, int month, int day) => Day.fromEpochDay(
    DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay,
  );

  factory Day.fromDateTime(DateTime t) => Day(t.year, t.month, t.day);

  factory Day.today() => Day.fromDateTime(DateTime.now());

  /// The day containing absolute minute [absMin].
  factory Day.containing(int absMin) =>
      Day.fromEpochDay(_floorDiv(absMin, minutesPerDay));

  final int epochDay;

  DateTime get _utc => DateTime.fromMillisecondsSinceEpoch(
    epochDay * Duration.millisecondsPerDay,
    isUtc: true,
  );

  int get year => _utc.year;
  int get month => _utc.month;
  int get day => _utc.day;

  /// 1 = Monday … 7 = Sunday.
  int get weekday => _utc.weekday;

  /// Absolute minute of this day's local midnight.
  int get startMin => epochDay * minutesPerDay;

  /// Absolute minute of the next day's midnight (exclusive end).
  int get endMin => startMin + minutesPerDay;

  Day addDays(int n) => Day.fromEpochDay(epochDay + n);

  Day get firstOfMonth => Day(year, month, 1);

  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;

  /// Local midnight of this day as a [DateTime].
  DateTime toLocalDateTime() => DateTime(year, month, day);

  /// `yyyy-mm-dd`, used as a stable key.
  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  static Day parseIso(String s) {
    final p = s.split('-');
    return Day(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  @override
  int compareTo(Day other) => epochDay.compareTo(other.epochDay);

  bool operator <(Day other) => epochDay < other.epochDay;
  bool operator <=(Day other) => epochDay <= other.epochDay;
  bool operator >(Day other) => epochDay > other.epochDay;
  bool operator >=(Day other) => epochDay >= other.epochDay;

  @override
  bool operator ==(Object other) => other is Day && other.epochDay == epochDay;

  @override
  int get hashCode => epochDay.hashCode;

  @override
  String toString() => 'Day($iso)';
}

int _floorDiv(int a, int b) => (a / b).floor();

/// Absolute minute index of a local [DateTime].
int absMinuteOf(DateTime local) =>
    Day.fromDateTime(local).startMin + local.hour * 60 + local.minute;

/// Absolute minute index of now.
int nowAbsMinute() => absMinuteOf(DateTime.now());

/// Local [DateTime] for absolute minute [absMin].
///
/// [DateTime] normalises the minute overflow, and resolves DST gaps itself.
DateTime localDateTimeOf(int absMin) {
  final day = Day.containing(absMin);
  return DateTime(day.year, day.month, day.day, 0, absMin - day.startMin);
}

/// Minute-of-day in `[0, 1440)` for absolute minute [absMin].
int minuteOfDay(int absMin) => absMin - Day.containing(absMin).startMin;

/// Formats a minute-of-day (may be outside `[0, 1440)`) as a clock time.
String formatClock(int minute, {bool use24h = false}) {
  final m = ((minute % minutesPerDay) + minutesPerDay) % minutesPerDay;
  final h = m ~/ 60;
  final mm = (m % 60).toString().padLeft(2, '0');
  if (use24h) return '${h.toString().padLeft(2, '0')}:$mm';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$mm ${h < 12 ? 'AM' : 'PM'}';
}

/// Formats a duration in minutes as `1h 30m`.
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}
