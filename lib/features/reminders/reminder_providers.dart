import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time/day_minutes.dart';
import '../../data/db/app_database.dart';
import '../../data/repos/block_repo.dart';
import 'reminder_service.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = ReminderService();
  ref.onDispose(service.dispose);
  return service;
});

/// Saved entries from the start of today to the end of tomorrow; enough to
/// cover the 48 h reminder horizon from any time today.
final _upcomingSavedProvider = StreamProvider<List<PlanBlock>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(blockRepoProvider)
      .watchSavedInRange(today.startMin, today.endMin + minutesPerDay);
});

final _upcomingPinsProvider = StreamProvider<List<PinRow>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(pinRepoProvider)
      .watchRange(today.startMin, today.endMin + minutesPerDay);
});

/// The reminders that should exist right now. Recomputed when saved
/// entries, tasks or settings change; not every minute.
final remindersPlanProvider = Provider<List<Reminder>>((ref) {
  final settings = ref.watch(settingsProvider);
  if (!settings.remindersEnabled) return const [];
  final blocks = ref.watch(_upcomingSavedProvider).value ?? const <PlanBlock>[];
  return planReminders(
    blocks,
    ref.watch(activityMapProvider),
    pins: ref.watch(_upcomingPinsProvider).value ?? const [],
    nowMin: nowAbsMinute(),
    leadMin: settings.reminderLeadMin,
    use24h: settings.use24h,
  );
});

/// Starts the reminder service and keeps its schedule in step with
/// [remindersPlanProvider]. Call once from the app shell.
Future<void> startReminders(WidgetRef ref) async {
  final service = ref.read(reminderServiceProvider);
  await service.init();
  if (ref.read(settingsProvider).remindersEnabled) {
    await service.requestPermission();
  }
  await service.apply(ref.read(remindersPlanProvider));
  ref.listenManual(remindersPlanProvider, (prev, next) {
    if (prev == null || !listEquals(prev, next)) service.apply(next);
  });
}
