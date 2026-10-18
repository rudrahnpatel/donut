import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Whether the user switched plan mode on.
final planModeProvider = NotifierProvider<PlanModeNotifier, bool>(
  PlanModeNotifier.new,
);

class PlanModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on;
}

final _entrySketchesProvider = StreamProvider<int>(
  (ref) => ref.watch(blockRepoProvider).watchDraftCount(),
);

final _pinSketchesProvider = StreamProvider<int>(
  (ref) => ref.watch(pinRepoProvider).watchDraftCount(),
);

/// Unsaved sketches (entry edits and pins) across all days.
final draftCountProvider = Provider<int>(
  (ref) =>
      (ref.watch(_entrySketchesProvider).value ?? 0) +
      (ref.watch(_pinSketchesProvider).value ?? 0),
);

/// Plan mode is on while the user has it switched on, or while any sketch
/// is still waiting for ✓ or ✕ (e.g. the app was closed mid-plan, or a
/// template was applied). Outside plan mode every edit saves instantly.
final planningProvider = Provider<bool>(
  (ref) => ref.watch(planModeProvider) || ref.watch(draftCountProvider) > 0,
);
