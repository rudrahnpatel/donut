import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time/day_minutes.dart';
import '../../data/repos/work_repo.dart';

/// Where the Noctalia "Donut Work" tracker writes one file per day.
String _workDir(String home) => '$home/.local/share/donut/work';

String _dayKey(Day d) {
  final t = d.toLocalDateTime();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)}';
}

/// Linux desktop: keeps the worked sessions in step with the tracker's
/// files for today and yesterday, every minute, and once estimates
/// earlier days from Claude Code's logs. Does nothing elsewhere.
void startWorkImport(WidgetRef ref) {
  if (kIsWeb || !Platform.isLinux) return;
  final home = Platform.environment['HOME'];
  if (home == null) return;
  final repo = ref.read(workRepoProvider);

  Future<void> importTracker() async {
    final today = ref.read(todayProvider);
    for (final day in [today.addDays(-1), today]) {
      final file = File('${_workDir(home)}/${_dayKey(day)}.json');
      if (!await file.exists()) continue;
      try {
        final data = jsonDecode(await file.readAsString()) as Map;
        final sessions = [
          for (final s in (data['sessions'] as List? ?? const []))
            TrackedSession.fromJson(s as Map<String, dynamic>),
        ];
        await repo.importDay(day, sessions, source: 'tracker');
      } catch (e) {
        debugPrint('Work: could not read ${file.path}: $e');
      }
    }
  }

  Future<void> backfill() async {
    final db = ref.read(databaseProvider);
    if (await db.getLocal(_backfillKey) != null) return;
    final today = ref.read(todayProvider);
    final personal = await _personalProjects(home);
    final byDay = await Isolate.run(
      () => estimateFromClaudeLogs(
        '$home/.claude/projects',
        days: 30,
        skip: personal,
      ),
    );
    for (final MapEntry(key: epochDay, value: sessions) in byDay.entries) {
      final day = Day.fromEpochDay(epochDay);
      // Only days the tracker never saw.
      if (!(day < today) || await repo.hasDay(day)) continue;
      await repo.importDay(day, sessions, source: 'claude-logs');
    }
    await db.setLocal(_backfillKey, '1');
  }

  unawaited(importTracker().then((_) => backfill()));
  Timer.periodic(const Duration(minutes: 1), (_) => importTracker());
}

const _backfillKey = 'work_backfilled';

/// The tracker's personal projects (lower-case), from its settings.
Future<Set<String>> _personalProjects(String home) async {
  try {
    final file = File(
      '$home/.config/noctalia/plugins/donut-work/settings.json',
    );
    final data = jsonDecode(await file.readAsString()) as Map;
    return {
      for (final p in (data['personalProjects'] as String? ?? '').split(','))
        if (p.trim().isNotEmpty) p.trim().toLowerCase(),
    };
  } catch (_) {
    return const {};
  }
}

/// Past working time estimated from Claude Code's session logs under
/// [projectsDir]: every logged message is a moment of work in its session's
/// project (the first `cwd` in the log: where it started, since later ones
/// wander into subfolders); moments less than [gapMinutes] apart join into
/// one session.
/// Covers the last [days] days, by local epoch day; projects in [skip]
/// (personal ones, lower-case) don't count.
Future<Map<int, List<TrackedSession>>> estimateFromClaudeLogs(
  String projectsDir, {
  int days = 30,
  int gapMinutes = 10,
  Set<String> skip = const {},
}) async {
  final root = Directory(projectsDir);
  if (!await root.exists()) return const {};
  final since = DateTime.now().subtract(Duration(days: days));
  final stamp = RegExp(r'"timestamp":"([^"]+)"');
  final cwd = RegExp(r'"cwd":"([^"]+)"');
  final events = <(int, String)>[];
  await for (final f in root.list(recursive: true, followLinks: false)) {
    if (f is! File || !f.path.endsWith('.jsonl')) continue;
    if ((await f.lastModified()).isBefore(since)) continue;
    String? project;
    final moments = <int>[];
    await for (final line
        in f
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      project ??= cwd
          .firstMatch(line)
          ?.group(1)
          ?.split('/')
          .where((p) => p.isNotEmpty)
          .lastOrNull;
      final t = stamp.firstMatch(line);
      final when = t == null ? null : DateTime.tryParse(t.group(1)!);
      if (when != null && !when.isBefore(since)) {
        moments.add(when.millisecondsSinceEpoch);
      }
    }
    final name = project ?? 'claude';
    if (skip.contains(name.toLowerCase())) continue;
    events.addAll(moments.map((m) => (m, name)));
  }
  return sessionsFromEvents(events, gapMinutes: gapMinutes);
}

/// Joins `(epoch ms, project)` moments less than [gapMinutes] apart into
/// sessions, grouped by the local epoch day they start on. Each stretch
/// between two moments counts for the project of the first.
Map<int, List<TrackedSession>> sessionsFromEvents(
  List<(int, String)> events, {
  int gapMinutes = 10,
}) {
  final sorted = [...events]..sort((a, b) => a.$1.compareTo(b.$1));
  final gap = gapMinutes * 60000;
  final out = <int, List<TrackedSession>>{};
  var i = 0;
  while (i < sorted.length) {
    final start = sorted[i].$1;
    var end = start;
    final projects = <String, int>{};
    var j = i;
    while (j + 1 < sorted.length && sorted[j + 1].$1 - sorted[j].$1 <= gap) {
      final p = sorted[j].$2;
      projects[p] =
          (projects[p] ?? 0) + (sorted[j + 1].$1 - sorted[j].$1) ~/ 1000;
      end = sorted[j + 1].$1;
      j++;
    }
    // A lone message still means a minute of work.
    if (end - start < 60000) {
      end = start + 60000;
      projects[sorted[i].$2] = (projects[sorted[i].$2] ?? 0) + 60;
    }
    final day = Day.containing(
      absMinuteOf(DateTime.fromMillisecondsSinceEpoch(start)),
    ).epochDay;
    (out[day] ??= []).add(
      TrackedSession(start: start, end: end, projects: projects),
    );
    i = j + 1;
  }
  return out;
}
