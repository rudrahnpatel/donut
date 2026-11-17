import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time/day_minutes.dart';
import '../core/time/hlc.dart';
import '../data/db/app_database.dart';
import '../data/repos/block_repo.dart';
import '../data/repos/library_repo.dart';
import '../data/repos/pin_repo.dart';
import '../data/repos/plan_tools_repo.dart';
import '../data/repos/settings_repo.dart';
import '../data/repos/work_repo.dart';

/// Overridden in `main` once the database is open.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(),
);

/// Overridden in `main` with this device's id.
final hlcClockProvider = Provider<HlcClock>(
  (ref) => throw UnimplementedError(),
);

final blockRepoProvider = Provider(
  (ref) => BlockRepo(ref.watch(databaseProvider), ref.watch(hlcClockProvider)),
);

final libraryRepoProvider = Provider(
  (ref) =>
      LibraryRepo(ref.watch(databaseProvider), ref.watch(hlcClockProvider)),
);

final planToolsRepoProvider = Provider(
  (ref) => PlanToolsRepo(
    ref.watch(databaseProvider),
    ref.watch(hlcClockProvider),
    ref.watch(blockRepoProvider),
  ),
);

final templatesProvider = StreamProvider<List<TemplateRow>>(
  (ref) => ref.watch(planToolsRepoProvider).watchTemplates(),
);

final chainsProvider = StreamProvider<List<ChainRow>>(
  (ref) => ref.watch(planToolsRepoProvider).watchChains(),
);

final seriesProvider = StreamProvider<List<SeriesRow>>(
  (ref) => ref.watch(planToolsRepoProvider).watchSeries(),
);

final settingsRepoProvider = Provider(
  (ref) =>
      SettingsRepo(ref.watch(databaseProvider), ref.watch(hlcClockProvider)),
);

final _settingsStream = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepoProvider).watch(),
);

/// Current settings, with defaults until the first load completes.
final settingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(_settingsStream).value ?? const AppSettings(),
);

/// Whether the stored settings have loaded (until then [settingsProvider]
/// holds defaults).
final settingsLoadedProvider = Provider<bool>(
  (ref) => ref.watch(_settingsStream).hasValue,
);

final dayPlanProvider = StreamProvider.family<DayPlan, Day>(
  (ref, day) => ref.watch(blockRepoProvider).watchDay(day),
);

final pinRepoProvider = Provider(
  (ref) => PinRepo(ref.watch(databaseProvider), ref.watch(hlcClockProvider)),
);

/// Pins on [day] and the days either side: the dial can show the edges of
/// both.
final dayPinsProvider = StreamProvider.family<List<PinRow>, Day>(
  (ref, day) => ref
      .watch(pinRepoProvider)
      .watchRange(day.startMin - minutesPerDay, day.endMin + minutesPerDay),
);

final workRepoProvider = Provider(
  (ref) => WorkRepo(ref.watch(databaseProvider), ref.watch(hlcClockProvider)),
);

/// Worked sessions overlapping [day] (and the edges of its neighbours).
final dayWorkProvider = StreamProvider.family<List<WorkSessionRow>, Day>(
  (ref, day) => ref
      .watch(workRepoProvider)
      .watchRange(day.startMin - minutesPerDay, day.endMin + minutesPerDay),
);

final recentPinTextsProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(pinRepoProvider).watchRecentCustom(),
);

final activitiesProvider = StreamProvider<List<ActivityRow>>(
  (ref) => ref.watch(libraryRepoProvider).watchActivities(),
);

final activityMapProvider = Provider<Map<String, ActivityRow>>((ref) {
  final list = ref.watch(activitiesProvider).value ?? const [];
  return {for (final a in list) a.id: a};
});

final allTodosProvider = StreamProvider<List<TodoRow>>(
  (ref) => ref.watch(libraryRepoProvider).watchTodos(),
);

/// Today's date; refreshed by the shell when the app resumes or at midnight.
final todayProvider = NotifierProvider<TodayNotifier, Day>(TodayNotifier.new);

class TodayNotifier extends Notifier<Day> {
  @override
  Day build() => Day.today();

  void refresh() {
    final t = Day.today();
    if (t != state) state = t;
  }
}

/// The day the planner is showing.
final focusedDayProvider = NotifierProvider<FocusedDayNotifier, Day>(
  FocusedDayNotifier.new,
);

class FocusedDayNotifier extends Notifier<Day> {
  @override
  Day build() => Day.today();

  void set(Day d) => state = d;
}

/// Quick-slot rankings, recomputed at most once per day so slot positions
/// stay put for muscle memory.
final quickRankingProvider =
    FutureProvider<({List<String> emojis, List<String> activityIds})>((
      ref,
    ) async {
      ref.watch(todayProvider);
      final lib = ref.watch(libraryRepoProvider);
      return (
        emojis: await lib.topEmojis(),
        activityIds: await lib.topActivityIds(),
      );
    });

final recentLabelsProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(libraryRepoProvider).watchRecentLabels(),
);
