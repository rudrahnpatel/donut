import 'package:donut/features/sync/merge.dart';
import 'package:flutter_test/flutter_test.dart';

Snapshot snap(String device, Map<String, List<Map<String, dynamic>>> tables) =>
    Snapshot.fromJson({'device': device, ...tables});

Map<String, dynamic> block(
  String id,
  String hlc, {
  int start = 0,
  bool deleted = false,
}) => {'id': id, 'hlc': hlc, 'startMin': start, 'deleted': deleted};

/// Applies [remotes] to [local] the way the sync engine does.
Snapshot applyAll(Snapshot local, List<Snapshot> remotes) {
  final next = {
    for (final t in syncedTables.keys) t: {...?local.tables[t]},
  };
  for (final MapEntry(key: table, value: rows) in rowsToApply(
    local,
    remotes,
  ).entries) {
    for (final r in rows) {
      next[table]!['${r[syncedTables[table]]}'] = r;
    }
  }
  return Snapshot(local.device, next);
}

void main() {
  test('newer remote rows win, older ones are ignored', () {
    final local = snap('a', {
      'blocks': [block('x', '2'), block('y', '5')],
    });
    final remote = snap('b', {
      'blocks': [block('x', '3', start: 99), block('y', '4', start: 1)],
    });
    final apply = rowsToApply(local, [remote]);
    expect(apply['blocks'], [block('x', '3', start: 99)]);
  });

  test('a deletion is just a newer row', () {
    final local = snap('a', {
      'blocks': [block('x', '2')],
    });
    final remote = snap('b', {
      'blocks': [block('x', '3', deleted: true)],
    });
    expect(rowsToApply(local, [remote])['blocks']!.single['deleted'], isTrue);
  });

  test('rows missing locally are added; settings merge by key', () {
    final local = snap('a', const {});
    final remote = snap('b', {
      'blocks': [block('new', '1')],
      'settings': [
        {'key': 'use24h', 'value': 'true', 'hlc': '7'},
      ],
    });
    final apply = rowsToApply(local, [remote]);
    expect(apply['blocks']!.single['id'], 'new');
    expect(apply['settings']!.single['key'], 'use24h');
  });

  test('three devices converge whatever order they merge in', () {
    final a = snap('a', {
      'blocks': [block('x', '1'), block('y', '6')],
    });
    final b = snap('b', {
      'blocks': [block('x', '4', start: 4)],
    });
    final c = snap('c', {
      'blocks': [
        block('x', '3'),
        block('z', '2'),
        block('y', '5', deleted: true),
      ],
    });
    final viaB = applyAll(applyAll(a, [b]), [c]);
    final viaC = applyAll(applyAll(a, [c]), [b]);
    final all = applyAll(a, [c, b]);
    expect(viaB.toJson(), viaC.toJson());
    expect(viaB.toJson(), all.toJson());
    expect(
      viaB.tables['blocks']!['x']!['start'] ??
          viaB.tables['blocks']!['x']!['startMin'],
      4,
    );
    expect(viaB.tables['blocks']!['y']!['deleted'], isFalse);
  });

  test('newestHlc finds the latest stamp', () {
    final s = snap('a', {
      'blocks': [block('x', '000000000000010-00000-a')],
      'todos': [
        {'id': 't', 'hlc': '000000000000020-00000-a'},
      ],
    });
    expect(s.newestHlc, '000000000000020-00000-a');
  });

  test('per-device settings never come in from another device', () {
    final local = snap('phone', {
      'settings': [
        {'key': 'syncMode', 'value': '"device"', 'hlc': '1'},
      ],
    });
    final laptop = snap('laptop', {
      'settings': [
        {'key': 'syncMode', 'value': '"calendar"', 'hlc': '9'},
        {'key': 'amoled', 'value': 'true', 'hlc': '9'},
        {'key': 'snapStep', 'value': '10', 'hlc': '9'},
      ],
    });
    expect(rowsToApply(local, [laptop])['settings'], [
      {'key': 'snapStep', 'value': '10', 'hlc': '9'},
    ]);
  });
}
