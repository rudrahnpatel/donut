import 'dart:convert';

import 'package:donut/core/time/hlc.dart';
import 'package:donut/data/db/app_database.dart';
import 'package:donut/data/repos/library_repo.dart';
import 'package:donut/data/repos/refile.dart';
import 'package:donut/data/repos/settings_repo.dart';
import 'package:donut/features/library/routine_migration.dart';
import 'package:donut/features/sync/sync_controller.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('refile rules', () {
    const rules = [
      RefileRule(label: 'Home chores', from: null, to: 'chores'),
      RefileRule(label: 'Personal project', from: 'fun', to: 'projects'),
    ];

    test('match label (trimmed, any case) and the current activity', () {
      expect(refiledActivity('Home chores', null, rules), 'chores');
      expect(refiledActivity(' home CHORES ', null, rules), 'chores');
      expect(refiledActivity('Personal project', 'fun', rules), 'projects');
    });

    test('leave entries the user filed elsewhere alone', () {
      expect(refiledActivity('Home chores', 'work', rules), isNull);
      expect(refiledActivity('Personal project', null, rules), isNull);
      expect(refiledActivity('Personal project', 'projects', rules), isNull);
      expect(refiledActivity(null, null, rules), isNull);
      expect(refiledActivity('Chores', null, rules), isNull);
    });

    test('templates: only matching items change; null when none do', () {
      final json = jsonEncode([
        {'s': 1140, 'd': 30, 'e': '🧹', 'n': 'Home chores'},
        {'s': 1200, 'd': 75, 'a': 'fun', 'n': 'Personal project'},
        {'s': 1275, 'd': 45, 'a': 'meal', 'n': 'Dinner'},
      ]);
      final out = jsonDecode(refileTemplateJson(json, rules)!) as List;
      expect(out[0], {
        's': 1140,
        'd': 30,
        'e': '🧹',
        'n': 'Home chores',
        'a': 'chores',
      });
      expect(out[1]['a'], 'projects');
      expect(out[2]['a'], 'meal');
      expect(refileTemplateJson(jsonEncode(out), rules), isNull);
    });
  });

  group('routineMigrationMayRun', () {
    test('waits for a sync on a device that syncs', () {
      expect(
        routineMigrationMayRun(
          syncConfigured: true,
          mode: SyncMode.device,
          status: const SyncStatus(account: 'me'),
        ),
        isFalse,
      );
      expect(
        routineMigrationMayRun(
          syncConfigured: true,
          mode: SyncMode.device,
          status: SyncStatus(account: 'me', lastSync: DateTime(2026)),
        ),
        isTrue,
      );
    });

    test('runs at once where nothing syncs', () {
      expect(
        routineMigrationMayRun(
          syncConfigured: false,
          mode: SyncMode.device,
          status: const SyncStatus(),
        ),
        isTrue,
      );
      expect(
        routineMigrationMayRun(
          syncConfigured: true,
          mode: SyncMode.off,
          status: const SyncStatus(),
        ),
        isTrue,
      );
    });
  });

  group('fileRoutineIntoNewCategories', () {
    late AppDatabase db;
    late HlcClock clock;
    late LibraryRepo lib;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      clock = HlcClock('test');
      lib = LibraryRepo(db, clock);
    });
    tearDown(() => db.close());

    /// An install from before the new starters: just the first seven.
    Future<Map<String, String>> oldInstall() async {
      final ids = <String, String>{};
      for (final (i, (name, emoji, color))
          in LibraryRepo.defaultActivities.indexed) {
        if (LibraryRepo.addedLater.contains(name)) continue;
        final id = 'old-$name';
        ids[name] = id;
        await db
            .into(db.activities)
            .insert(
              ActivitiesCompanion.insert(
                id: id,
                name: name,
                emoji: emoji,
                color: color,
                sortOrder: Value(i),
                hlc: '000000000000000-00000-seed',
              ),
            );
      }
      await db.setLocal('seeded', '1');
      return ids;
    }

    Future<void> block(String id, String? note, String? activity) => db
        .into(db.blocks)
        .insert(
          BlocksCompanion.insert(
            id: id,
            startMin: 0,
            durMin: 30,
            note: Value(note),
            activityId: Value(activity),
            hlc: '000000000000001-00000-x',
          ),
        );

    Future<BlockRow> saved(String id) =>
        (db.select(db.blocks)..where((t) => t.id.equals(id))).getSingle();

    test('adds the categories and re-files the routine, once', () async {
      final old = await oldInstall();
      await block('chores', 'Home chores', null);
      await block('jobs', 'Job applications', null);
      await block('proj', 'Personal project', old['Fun']);
      await block('fun', 'Personal project', old['Work']); // filed by hand
      await block('meal', 'Dinner', old['Meal']);
      await block('sketched', 'Home chores', null);
      await db
          .into(db.blockEdits)
          .insert(
            BlockEditsCompanion.insert(
              blockId: 'sketched',
              startMin: 60,
              durMin: 30,
              note: const Value('Home chores'),
              state: EditState.pending,
              editedAt: 0,
            ),
          );
      await db
          .into(db.templates)
          .insert(
            TemplatesCompanion.insert(
              id: 't',
              name: 'Planned Day',
              blocksJson: jsonEncode([
                {'s': 1170, 'd': 30, 'e': '📨', 'n': 'Job applications'},
              ]),
              hlc: '000000000000001-00000-x',
            ),
          );

      // 3 activities + 3 blocks + 1 template.
      expect(await lib.fileRoutineIntoNewCategories(), 7);

      final chores = LibraryRepo.starterId('Chores');
      final jobs = LibraryRepo.starterId('Job hunt');
      final projects = LibraryRepo.starterId('Projects');
      final acts = await lib.watchActivities().first;
      expect(acts.map((a) => a.name).toList(), [
        'Study',
        'Work',
        'Gym',
        'Meal',
        'Sleep',
        'Break',
        'Fun',
        'Chores',
        'Job hunt',
        'Projects',
      ]);
      expect((await saved('chores')).activityId, chores);
      expect((await saved('jobs')).activityId, jobs);
      expect((await saved('proj')).activityId, projects);
      expect((await saved('fun')).activityId, old['Work']);
      expect((await saved('meal')).activityId, old['Meal']);
      // The sketch carries the change; its saved row waits for ✓.
      expect((await saved('sketched')).activityId, isNull);
      final edit = await (db.select(
        db.blockEdits,
      )..where((t) => t.blockId.equals('sketched'))).getSingle();
      expect(edit.activityId, chores);
      final t = await (db.select(db.templates)).getSingle();
      expect((jsonDecode(t.blocksJson) as List).single['a'], jobs);
      // Re-filed rows carry fresh HLCs, so they sync.
      expect((await saved('chores')).hlc, isNot('000000000000001-00000-x'));

      expect(await lib.fileRoutineIntoNewCategories(), isNull);
    });

    test(
      'a second device that already synced the change writes nothing',
      () async {
        await oldInstall();
        await lib.fileRoutineIntoNewCategories();
        await (db.delete(
          db.localKv,
        )..where((t) => t.key.equals(LibraryRepo.routineMigrationKey))).go();
        expect(await lib.fileRoutineIntoNewCategories(), 0);
      },
    );

    test('keeps a same-named activity the user already made', () async {
      await oldInstall();
      final mine = await lib.addActivity('chores', '🧽', 0xFF26A69A);
      await block('c', 'Home chores', null);
      await lib.fileRoutineIntoNewCategories();
      final names = (await lib.watchActivities().first).map((a) => a.name);
      expect(names.where((n) => n.toLowerCase() == 'chores'), ['chores']);
      expect((await saved('c')).activityId, mine);
    });

    test('does not bring back a category deleted on another device', () async {
      await oldInstall();
      await db
          .into(db.activities)
          .insert(
            ActivitiesCompanion.insert(
              id: LibraryRepo.starterId('Projects'),
              name: 'Projects',
              emoji: '🛠️',
              color: 0,
              deleted: const Value(true),
              hlc: clock.now(),
            ),
          );
      await lib.fileRoutineIntoNewCategories();
      final names = (await lib.watchActivities().first).map((a) => a.name);
      expect(names, isNot(contains('Projects')));
    });

    test('a fresh install seeds all ten and has nothing to re-file', () async {
      await lib.seedIfEmpty();
      expect(await lib.watchActivities().first, hasLength(10));
      expect(await lib.fileRoutineIntoNewCategories(), 0);
    });
  });
}
