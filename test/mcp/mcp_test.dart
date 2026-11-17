import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:donut/core/time/day_minutes.dart';
import 'package:donut/core/time/hlc.dart';
import 'package:donut/data/db/app_database.dart';
import 'package:donut/data/repos/block_repo.dart';
import 'package:donut/data/repos/library_repo.dart';
import 'package:donut/data/repos/pin_repo.dart';
import 'package:donut/data/repos/work_repo.dart';
import 'package:donut/features/mcp/mcp_server.dart';
import 'package:donut/features/mcp/mcp_tools.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BlockRepo blocks;
  late PinRepo pins;
  late McpHandler handler;
  var planMode = false;
  // Fixed "now": 2026-03-10 09:20.
  final now = DateTime(2026, 3, 10, 9, 20);
  final day = Day(2026, 3, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final clock = HlcClock('test');
    blocks = BlockRepo(db, clock);
    pins = PinRepo(db, clock);
    final library = LibraryRepo(db, clock);
    await library.seedIfEmpty();
    planMode = false;
    handler = McpHandler(
      DonutMcpTools(
        blocks: blocks,
        pins: pins,
        library: library,
        work: WorkRepo(db, clock),
        planModeOn: () => planMode,
        now: () => now,
      ).tools,
    );
  });
  tearDown(() => db.close());

  var nextId = 0;
  Future<Map<String, Object?>> rpc(String method, [Object? params]) async =>
      (await handler.handle({
        'jsonrpc': '2.0',
        'id': ++nextId,
        'method': method,
        'params': ?params,
      })) as Map<String, Object?>;

  /// Calls a tool; returns its structured result, or the error text.
  Future<Object?> call(String name, [Map<String, Object?>? args]) async {
    final r = await rpc('tools/call', {'name': name, 'arguments': ?args});
    final result = r['result'] as Map;
    if (result['isError'] == true) {
      return 'ERROR: ${(result['content'] as List).single['text']}';
    }
    return result['structuredContent'];
  }

  group('protocol', () {
    test('initialize echoes a known version and offers tools', () async {
      final r = await rpc('initialize', {
        'protocolVersion': '2025-03-26',
        'capabilities': {},
        'clientInfo': {'name': 'test', 'version': '0'},
      });
      final result = r['result'] as Map;
      expect(result['protocolVersion'], '2025-03-26');
      expect(result['capabilities'], {
        'tools': {'listChanged': false},
      });
      expect((result['serverInfo'] as Map)['name'], 'donut');

      final unknown = await rpc('initialize', {'protocolVersion': '1999'});
      expect(
        (unknown['result'] as Map)['protocolVersion'],
        McpHandler.supportedVersions.first,
      );
    });

    test('notifications get no reply; ping and batches work', () async {
      expect(
        await handler.handle({
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        }),
        isNull,
      );
      expect((await rpc('ping'))['result'], {});
      final batch = await handler.handle([
        {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
        {'jsonrpc': '2.0', 'id': 7, 'method': 'ping'},
      ]);
      expect(batch, [
        {'jsonrpc': '2.0', 'id': 7, 'result': {}},
      ]);
    });

    test('errors: unknown method, unknown tool, invalid request', () async {
      expect(((await rpc('nope'))['error'] as Map)['code'], -32601);
      final r = await rpc('tools/call', {'name': 'nope'});
      expect((r['error'] as Map)['code'], -32602);
      final bad = await handler.handle({'id': 1, 'method': 'ping'}) as Map;
      expect((bad['error'] as Map)['code'], -32600);
    });

    test('tools/list describes every tool with an object schema', () async {
      final tools =
          ((await rpc('tools/list'))['result'] as Map)['tools'] as List;
      final names = [for (final t in tools) (t as Map)['name']];
      expect(
        names,
        containsAll([
          'get_day',
          'list_blocks',
          'add_block',
          'update_block',
          'delete_block',
          'find_free_slots',
          'list_activities',
          'add_pin',
          'delete_pin',
        ]),
      );
      for (final t in tools.cast<Map>()) {
        expect((t['inputSchema'] as Map)['type'], 'object');
        expect(t['description'], isNotEmpty);
      }
    });
  });

  group('tools', () {
    test('add_block saves instantly outside plan mode', () async {
      final r = await call('add_block', {
        'date': '2026-03-10',
        'start': '14:00',
        'end': '15:30',
        'label': 'Dentist',
      }) as Map;
      final added = r['added'] as Map;
      expect(added['start'], '14:00');
      expect(added['end'], '15:30');
      expect(added['duration_minutes'], 90);
      expect(added['title'], 'Dentist');
      expect(added['status'], 'saved');
      expect(added['color'], matches(RegExp(r'^#[0-9A-F]{6}$')));
      expect(r.containsKey('note'), isFalse);

      final saved = await blocks.savedInRange(day.startMin, day.endMin);
      expect(saved.single.startMin, day.startMin + 14 * 60);
      expect(saved.single.note, 'Dentist');
      expect(await blocks.watchDraftCount().first, 0);
    });

    test('in plan mode it lands as a sketch, and so do later edits', () async {
      planMode = true;
      final r = await call('add_block', {
        'date': '2026-03-10',
        'start': '08:00',
        'duration_minutes': 45,
        'activity': 'work',
      }) as Map;
      final added = r['added'] as Map;
      expect(added['status'], 'draft');
      expect(added['activity'], 'Work');
      expect(r['note'], contains('✓'));
      expect(await blocks.savedInRange(day.startMin, day.endMin), isEmpty);

      // Plan mode switched off, but the sketch stays one.
      planMode = false;
      final u = await call('update_block', {
        'id': added['id'],
        'start': '08:30',
      }) as Map;
      expect((u['updated'] as Map)['start'], '08:30');
      expect((u['updated'] as Map)['end'], '09:15');
      expect((u['updated'] as Map)['status'], 'draft');
      expect(await blocks.savedInRange(day.startMin, day.endMin), isEmpty);
    });

    test('the day stream the dial watches picks up the change', () async {
      final seen = <List<String>>[];
      final sub = blocks
          .watchDay(day)
          .listen((p) => seen.add([for (final b in p.onDay) b.id]));
      await pumpEventQueue();
      final r = await call('add_block', {
        'date': '2026-03-10',
        'start': '07:00',
        'end': '07:30',
      }) as Map;
      await pumpEventQueue();
      unawaited(sub.cancel()); // the generator waits on the next DB change
      expect(seen.first, isEmpty);
      expect(seen.last, [(r['added'] as Map)['id']]);
    });

    test('sketch: true forces a sketch outside plan mode', () async {
      final r = await call('add_block', {
        'date': '2026-03-10',
        'start': '18:00',
        'end': '19:00',
        'sketch': true,
      }) as Map;
      expect((r['added'] as Map)['status'], 'draft');
    });

    test('an end before the start runs past midnight', () async {
      final r = await call('add_block', {
        'date': '2026-03-10',
        'start': '23:00',
        'end': '01:00',
      }) as Map;
      final added = r['added'] as Map;
      expect(added['duration_minutes'], 120);
      expect(added['end_date'], '2026-03-11');
      // It shows on the next day too.
      final next = await call('get_day', {'date': '2026-03-11'}) as Map;
      expect((next['entries'] as List).single['id'], added['id']);
    });

    test('update_block moves, resizes, relabels and recolours', () async {
      final id =
          ((await call('add_block', {
                'date': '2026-03-10',
                'start': '10:00',
                'end': '11:00',
                'label': 'Gym',
              }) as Map)['added']
              as Map)['id'];
      final r = await call('update_block', {
        'id': id,
        'date': '2026-03-12',
        'duration_minutes': 30,
        'label': 'Run',
        'color': '#112233',
      }) as Map;
      final u = r['updated'] as Map;
      expect(u['date'], '2026-03-12');
      expect(u['start'], '10:00');
      expect(u['end'], '10:30');
      expect(u['label'], 'Run');
      expect(u['color'], '#112233');
      expect(u['status'], 'saved');
      final saved = await blocks.find(id as String);
      expect(saved!.startMin, Day(2026, 3, 12).startMin + 600);
      expect(saved.color, 0xFF112233);

      final cleared = await call('update_block', {'id': id, 'label': ''});
      expect(((cleared as Map)['updated'] as Map).containsKey('label'), false);
    });

    test('delete_block tombstones a saved entry', () async {
      final id =
          ((await call('add_block', {
                'date': '2026-03-10',
                'start': '10:00',
                'end': '11:00',
              }) as Map)['added']
              as Map)['id'];
      await call('delete_block', {'id': id});
      expect(await blocks.find(id as String), isNull);
      final row = await (db.select(
        db.blocks,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.deleted, isTrue);
      expect(await call('delete_block', {'id': id}), startsWith('ERROR'));
    });

    test('find_free_slots: from now on today, gaps between entries', () async {
      await call('add_block', {
        'date': '2026-03-10',
        'start': '10:00',
        'end': '12:00',
      });
      await call('add_block', {
        'date': '2026-03-10',
        'start': '12:15',
        'end': '13:00',
      });
      final r = await call('find_free_slots', {
        'date': '2026-03-10',
        'min_duration_minutes': 30,
        'to': '18:00',
      }) as Map;
      expect(r['free'], [
        {'start': '09:20', 'end': '10:00', 'duration_minutes': 40},
        {'start': '13:00', 'end': '18:00', 'duration_minutes': 300},
      ]);
      final tomorrow =
          await call('find_free_slots', {'date': '2026-03-11'}) as Map;
      expect(tomorrow['free'], [
        {'start': '00:00', 'end': '24:00', 'duration_minutes': 1440},
      ]);
    });

    test('get_day lists entries and pins; pins can be removed', () async {
      await call('add_block', {
        'date': '2026-03-10',
        'start': '14:00',
        'end': '15:00',
      });
      final p = await call('add_pin', {
        'date': '2026-03-10',
        'time': '16:55',
        'kind': 'reach_by',
      }) as Map;
      expect((p['added'] as Map)['title'], 'Reach by 16:55');
      final d = await call('get_day') as Map;
      expect(d['date'], '2026-03-10');
      expect(d['weekday'], 'Tuesday');
      expect(d['now'], '09:20');
      expect(d['plan_mode'], isFalse);
      expect((d['entries'] as List), hasLength(1));
      expect((d['pins'] as List).single['kind'], 'reach_by');
      await call('delete_pin', {'id': (p['added'] as Map)['id']});
      expect(((await call('get_day') as Map)['pins'] as List), isEmpty);
    });

    test('bad input comes back as a tool error, not a crash', () async {
      expect(
        await call('add_block', {'date': '2026-02-30', 'start': '10:00'}),
        contains('date must be'),
      );
      expect(
        await call('add_block', {'date': '2026-03-10', 'start': '25:00'}),
        contains('start must be'),
      );
      expect(
        await call('add_block', {'date': '2026-03-10', 'start': '10:00'}),
        contains('end time or duration'),
      );
      expect(
        await call('add_block', {
          'date': '2026-03-10',
          'start': '10:00',
          'end': '11:00',
          'activity': 'Juggling',
        }),
        allOf(contains('No activity'), contains('Work')),
      );
      expect(
        await call('add_pin', {'date': '2026-03-10', 'time': '10:00'}),
        contains('needs a label'),
      );
      expect(await blocks.savedInRange(0, 1 << 40), isEmpty);
    });

    test('list_blocks covers a range of days', () async {
      for (final d in ['2026-03-09', '2026-03-10', '2026-03-12']) {
        await call('add_block', {'date': d, 'start': '09:00', 'end': '10:00'});
      }
      final r = await call('list_blocks', {
        'from_date': '2026-03-10',
        'to_date': '2026-03-12',
      }) as Map;
      expect(
        [for (final e in r['entries'] as List) e['date']],
        ['2026-03-10', '2026-03-12'],
      );
    });
  });

  group('http', () {
    late McpHttpServer server;
    late HttpClient client;

    setUp(() async {
      server = await McpHttpServer.start(handler);
      client = HttpClient();
    });
    tearDown(() async {
      client.close(force: true);
      await server.close();
    });

    Future<(int, String)> post(
      Object body, {
      Map<String, String> headers = const {},
      String method = 'POST',
    }) async {
      final req = await client.openUrl(method, Uri.parse(server.url));
      headers.forEach(req.headers.set);
      req.headers.contentType = ContentType.json;
      if (method == 'POST') req.write(jsonEncode(body));
      final res = await req.close();
      return (res.statusCode, await utf8.decodeStream(res));
    }

    test('binds loopback only and answers JSON-RPC', () async {
      expect(server.url, startsWith('http://127.0.0.1:'));
      final (code, body) = await post({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'ping',
      });
      expect(code, 200);
      expect(jsonDecode(body), {'jsonrpc': '2.0', 'id': 1, 'result': {}});
    });

    test('notifications get 202, GET gets 405', () async {
      final (code, _) = await post({
        'jsonrpc': '2.0',
        'method': 'notifications/initialized',
      });
      expect(code, 202);
      final (get, _) = await post({}, method: 'GET');
      expect(get, 405);
    });

    test('a foreign Origin or Host is refused', () async {
      final msg = {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'};
      final (evil, _) = await post(
        msg,
        headers: {'origin': 'https://evil.example'},
      );
      expect(evil, 403);
      final (rebound, _) = await post(
        msg,
        headers: {'host': 'evil.example:${server.port}'},
      );
      expect(rebound, 403);
      final (local, _) = await post(
        msg,
        headers: {'origin': 'http://localhost:3000'},
      );
      expect(local, 200);
    });

    test('malformed JSON is a parse error', () async {
      final req = await client.postUrl(Uri.parse(server.url));
      req.write('{nope');
      final res = await req.close();
      final body = jsonDecode(await utf8.decodeStream(res)) as Map;
      expect((body['error'] as Map)['code'], -32700);
    });
  });
}
