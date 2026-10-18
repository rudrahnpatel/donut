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

/// Unsaved sketches across all days.
final draftCountProvider = StreamProvider<int>(
  (ref) => ref.watch(blockRepoProvider).watchDraftCount(),
);

/// Plan mode is on while the user has it switched on, or while any sketch
/// is still waiting for ✓ or ✕ (e.g. the app was closed mid-plan, or a
/// template was applied). Outside plan mode every edit saves instantly.
final planningProvider = Provider<bool>(
  (ref) =>
      ref.watch(planModeProvider) ||
      (ref.watch(draftCountProvider).value ?? 0) > 0,
);
