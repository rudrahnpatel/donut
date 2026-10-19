import 'package:donut/core/time/hlc.dart';
import 'package:donut/data/db/app_database.dart';
import 'package:donut/data/repos/block_repo.dart';
import 'package:donut/data/repos/plan_tools_repo.dart';
import 'package:donut/features/templates/chains.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

int at(int h, int m) => h * 60 + m;

void main() {
  PlanBlock b(String id, int s, int e) =>
      PlanBlock(id: id, startMin: s, durMin: e - s);

  test(
    '"save as chain" takes the entries back to back from the one picked',
    () {
      final day = [
        b('ready', at(16, 5), at(16, 10)),
        b('home', at(16, 10), at(16, 15)),
        b('train', at(16, 15), at(16, 55)),
        b('dinner', at(19, 0), at(20, 0)),
        b('early', at(9, 0), at(9, 30)),
      ];
      expect(backToBackFrom(day[0], day).map((x) => x.id), [
        'ready',
        'home',
        'train',
      ]);
      expect(backToBackFrom(day[3], day).map((x) => x.id), ['dinner']);
    },
  );

  group('placing a chain', () {
    late AppDatabase db;
    late PlanToolsRepo tools;
    late BlockRepo blocks;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      final clock = HlcClock('test');
      blocks = BlockRepo(db, clock);
      tools = PlanToolsRepo(db, clock, blocks);
    });
    tearDown(() => db.close());

    test(
      'fitted before a "Reach by 4:55" it ends exactly there, as sketches',
      () async {
        await tools.saveChain('Commute', const [
          ChainStep(5, note: 'getting ready'),
          ChainStep(5, note: 'home to stn'),
          ChainStep(40, note: 'train'),
        ]);
        final chain = (await tools.watchChains().first).single;
        expect(chain.length, 50);

        final reachBy = at(16, 55);
        expect(await tools.applyChain(chain, reachBy - chain.length), 3);

        final edits = await db.select(db.blockEdits).get()
          ..sort((a, b) => a.startMin.compareTo(b.startMin));
        expect(edits.map((e) => (e.note, e.startMin, e.startMin + e.durMin)), [
          ('getting ready', at(16, 5), at(16, 10)),
          ('home to stn', at(16, 10), at(16, 15)),
          ('train', at(16, 15), at(16, 55)),
        ]);
        expect(await db.select(db.blocks).get(), isEmpty, reason: 'sketches');
      },
    );
  });
}
