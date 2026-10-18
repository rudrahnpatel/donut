import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'schema.dart';

export 'schema.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Blocks,
    BlockEdits,
    Activities,
    Todos,
    Templates,
    Series,
    RemoteLinks,
    Settings,
    LocalKv,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'donut'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX blocks_start ON blocks (start_min)');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(blocks, blocks.color);
        await m.addColumn(blockEdits, blockEdits.color);
      }
    },
  );

  Future<String?> getLocal(String key) async {
    final row = await (select(
      localKv,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setLocal(String key, String value) => into(localKv)
      .insertOnConflictUpdate(LocalKvCompanion.insert(key: key, value: value));
}
