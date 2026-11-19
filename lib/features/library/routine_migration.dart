import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repos/settings_repo.dart';
import '../sync/google_auth.dart';
import '../sync/sync_controller.dart';

/// Whether the one-time routine re-file may run now: when this device
/// can't sync (no Google setup, or sync switched off), or once a sync has
/// finished this launch, so a device coming back with stale data first
/// takes what the others changed (and finds the work already done).
bool routineMigrationMayRun({
  required bool syncConfigured,
  required SyncMode mode,
  required SyncStatus status,
}) => !syncConfigured || mode == SyncMode.off || status.lastSync != null;

/// Runs [LibraryRepo.fileRoutineIntoNewCategories] as soon as
/// [routineMigrationMayRun] allows: right away, or after the first
/// successful sync (which may come later, e.g. when back online).
void startRoutineMigration(WidgetRef ref) {
  var done = false;
  Future<void> tryRun() async {
    if (done || !ref.read(settingsLoadedProvider)) return;
    final may = routineMigrationMayRun(
      syncConfigured: GoogleConfig.configured,
      mode: ref.read(settingsProvider).syncMode,
      status: ref.read(syncControllerProvider),
    );
    if (!may) return;
    done = true;
    final n = await ref
        .read(libraryRepoProvider)
        .fileRoutineIntoNewCategories();
    if (n != null) debugPrint('Routine categories: $n rows changed');
  }

  ref.listenManual(syncControllerProvider, (_, _) => tryRun());
  ref.listenManual(settingsLoadedProvider, (_, _) => tryRun());
  ref.listenManual(settingsProvider, (_, _) => tryRun());
  tryRun();
}
