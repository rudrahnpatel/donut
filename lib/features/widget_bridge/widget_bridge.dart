import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/time/day_minutes.dart';
import '../../data/repos/block_repo.dart';

/// Key the Android widget reads (see DayClockWidget.kt).
const _dataKey = 'donut_days';

/// The day-view and hour-view widgets (see DayClockWidget.kt).
const _widgetClasses = [
  'dev.rudra.donut.DayClockWidget',
  'dev.rudra.donut.HourClockWidget',
];

/// Saved entries for today and tomorrow, so the widget can turn over at
/// midnight without the app running.
final _widgetBlocksProvider = StreamProvider<List<PlanBlock>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(blockRepoProvider)
      .watchSavedInRange(today.startMin, today.endMin + minutesPerDay);
});

/// `{"<epochDay>": [[startMin, endMin, argb], ...]}` for [days]; entries
/// are clipped to each day and coloured as the app's dark theme draws them.
@visibleForTesting
String encodeWidgetDays(
  Iterable<PlanBlock> blocks,
  List<Day> days,
  int? Function(PlanBlock) activityColor,
) {
  final out = <String, List<List<int>>>{};
  for (final day in days) {
    out['${day.epochDay}'] = [
      for (final b in blocks)
        if (b.overlaps(day.startMin, day.endMin))
          [
            (b.startMin - day.startMin).clamp(0, minutesPerDay),
            (b.endMin - day.startMin).clamp(0, minutesPerDay),
            blockColor(
              b.color ?? activityColor(b) ?? fallbackEntryColor(b.id),
              Brightness.dark,
            ).toARGB32(),
          ],
    ];
  }
  return jsonEncode(out);
}

/// Keeps the Android home-screen widget in step with saved entries. Call
/// once from the app shell; does nothing on other platforms.
void startWidgetBridge(WidgetRef ref) {
  if (kIsWeb || !Platform.isAndroid) return;
  Future<void> push(List<PlanBlock> blocks) async {
    final today = ref.read(todayProvider);
    final activities = ref.read(activityMapProvider);
    final json = encodeWidgetDays(blocks, [
      today,
      today.addDays(1),
    ], (b) => activities[b.activityId]?.color);
    try {
      await HomeWidget.saveWidgetData<String>(_dataKey, json);
      for (final name in _widgetClasses) {
        await HomeWidget.updateWidget(qualifiedAndroidName: name);
      }
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  ref.listenManual(_widgetBlocksProvider, (prev, next) {
    final blocks = next.value;
    if (blocks != null) push(blocks);
  }, fireImmediately: true);
}
