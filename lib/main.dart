import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/time/hlc.dart';
import 'data/db/app_database.dart';
import 'data/repos/block_repo.dart';
import 'data/repos/library_repo.dart';
import 'dev/dev_harness.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dev = DevHarness.fromEnvironment();
  final db = dev?.openDatabase() ?? AppDatabase();

  var deviceId = await db.getLocal('device_id');
  if (deviceId == null) {
    deviceId = const Uuid().v4().substring(0, 8);
    await db.setLocal('device_id', deviceId);
  }
  final clock = HlcClock(deviceId);
  // If the wall clock went backwards since the last run, stay ahead of the
  // newest stamp we already wrote.
  final newest = await db
      .customSelect(
        'SELECT MAX(h) AS h FROM (SELECT MAX(hlc) AS h FROM blocks '
        'UNION ALL SELECT MAX(hlc) FROM settings UNION ALL SELECT MAX(hlc) FROM activities)',
      )
      .getSingle();
  final h = newest.read<String?>('h');
  if (h != null) clock.receive(h);

  final onboarded = await db.getLocal(OnboardedNotifier.key) != null;
  await LibraryRepo(db, clock).seedIfEmpty();
  await BlockRepo(db, clock).assignMissingColors();
  await dev?.seed(db, clock);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hlcClockProvider.overrideWithValue(clock),
        // The harness skips the tour unless asked to show it.
        onboardedAtStartProvider.overrideWithValue(
          dev == null ? onboarded : !dev.showsOnboarding,
        ),
        ...?dev?.overrides,
      ],
      child: dev?.wrap(const DonutApp()) ?? const DonutApp(),
    ),
  );
  dev?.start();
}
