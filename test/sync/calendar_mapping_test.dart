import 'package:donut/core/time/day_minutes.dart';
import 'package:donut/data/db/app_database.dart';
import 'package:donut/features/sync/calendar_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as cal;

void main() {
  final day = Day(2026, 10, 18).startMin;

  BlockRow row(String id, {String? note, int? color}) => BlockRow(
    id: id,
    startMin: day + 16 * 60 + 5,
    durMin: 10,
    note: note,
    color: color,
    detached: false,
    hlc: '000000000000001-00000-a',
    deleted: false,
  );

  group('eventIdFor', () {
    test('UUIDs lose their dashes and are valid base32hex', () {
      expect(
        eventIdFor('3F2504E0-4F89-11D3-9A0C-0305E82C3301'),
        '3f2504e04f8911d39a0c0305e82c3301',
      );
    });

    test('other ids are hex-encoded, never colliding with each other', () {
      final a = eventIdFor('sleep-1'), b = eventIdFor('sleep-2');
      expect(RegExp(r'^[0-9a-v]{5,}$').hasMatch(a), isTrue);
      expect(a, isNot(b));
    });
  });

  test('an entry round-trips through an event', () {
    final event = eventForBlock(
      row('abcdef12', note: 'home to stn', color: 0xFF26A69A),
      title: 'home to stn',
      timeZone: 'Asia/Kolkata',
    );
    expect(event.reminders?.useDefault, isFalse);
    // Google returns the times as instants; simulate that.
    event.start!.dateTime = event.start!.dateTime!.toUtc();
    event.end!.dateTime = event.end!.dateTime!.toUtc();
    final back = blockFromEvent(event)!;
    expect(back.id, 'abcdef12');
    expect(back.startMin, day + 16 * 60 + 5);
    expect(back.durMin, 10);
    expect(back.note, 'home to stn');
    expect(back.color, 0xFF26A69A);
    expect(back.deleted, isFalse);
  });

  test('events made in Google Calendar become labelled entries', () {
    final e = cal.Event(
      id: 'xyz123',
      summary: 'Dentist',
      start: cal.EventDateTime(dateTime: localDateTimeOf(day + 10 * 60)),
      end: cal.EventDateTime(dateTime: localDateTimeOf(day + 11 * 60)),
    );
    final b = blockFromEvent(e)!;
    expect(b.id, 'gcal-xyz123');
    expect(b.note, 'Dentist');
    expect(b.durMin, 60);
  });

  test('all-day events are skipped; cancelled ones become deletions', () {
    expect(
      blockFromEvent(
        cal.Event(
          id: 'a',
          start: cal.EventDateTime(date: DateTime(2026, 10, 18)),
        ),
      ),
      isNull,
    );
    final gone = blockFromEvent(
      cal.Event(
        id: 'b',
        status: 'cancelled',
        extendedProperties: cal.EventExtendedProperties(
          private: {'donutId': 'abcdef12'},
        ),
      ),
    )!;
    expect(gone.deleted, isTrue);
    expect(gone.id, 'abcdef12');
  });
}
