import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/time/hlc.dart';
import '../db/app_database.dart';

enum ThemePref { system, light, dark }

enum QuickMode { auto, pinned }

enum SyncMode { off, device, calendar }

/// User preferences. Stored one key per field in the synced `settings` table
/// so devices merge per setting, not all-or-nothing.
class AppSettings {
  const AppSettings({
    this.theme = ThemePref.system,
    this.amoled = false,
    this.useDynamicColor = true,
    this.seedColor = 0xFFE86A92,
    this.snapStep = 15,
    this.hourSnapStep = 5,
    this.use24h = false,
    this.quickEmojiMode = QuickMode.auto,
    this.pinnedEmojis = const ['📚', '💼', '💪', '🍽️', '😴', '☕', '🎮'],
    this.quickActivityMode = QuickMode.auto,
    this.remindersEnabled = true,
    this.reminderLeadMin = 0,
    this.syncMode = SyncMode.off,
    this.ghostTitles = false,
  });

  final ThemePref theme;
  final bool amoled;
  final bool useDynamicColor;
  final int seedColor;

  /// Snap on the day dial.
  final int snapStep;

  /// Snap on the hour dial.
  final int hourSnapStep;
  final bool use24h;
  final QuickMode quickEmojiMode;
  final List<String> pinnedEmojis;
  final QuickMode quickActivityMode;
  final bool remindersEnabled;
  final int reminderLeadMin;
  final SyncMode syncMode;

  /// Show event titles (not just busy times) on ghost arcs; needs an extra
  /// Calendar scope.
  final bool ghostTitles;

  Map<String, Object> toMap() => {
    'theme': theme.name,
    'amoled': amoled,
    'useDynamicColor': useDynamicColor,
    'seedColor': seedColor,
    'snapStep': snapStep,
    'hourSnapStep': hourSnapStep,
    'use24h': use24h,
    'quickEmojiMode': quickEmojiMode.name,
    'pinnedEmojis': pinnedEmojis,
    'quickActivityMode': quickActivityMode.name,
    'remindersEnabled': remindersEnabled,
    'reminderLeadMin': reminderLeadMin,
    'syncMode': syncMode.name,
    'ghostTitles': ghostTitles,
  };

  static AppSettings fromMap(Map<String, Object?> m) {
    const d = AppSettings();
    T pick<T>(String k, T fallback) {
      final v = m[k];
      return v is T ? v : fallback;
    }

    E pickEnum<E extends Enum>(String k, List<E> values, E fallback) {
      final v = m[k];
      return values.firstWhere((e) => e.name == v, orElse: () => fallback);
    }

    return AppSettings(
      theme: pickEnum('theme', ThemePref.values, d.theme),
      amoled: pick('amoled', d.amoled),
      useDynamicColor: pick('useDynamicColor', d.useDynamicColor),
      seedColor: pick('seedColor', d.seedColor),
      snapStep: pick('snapStep', d.snapStep),
      hourSnapStep: pick('hourSnapStep', d.hourSnapStep),
      use24h: pick('use24h', d.use24h),
      quickEmojiMode: pickEnum(
        'quickEmojiMode',
        QuickMode.values,
        d.quickEmojiMode,
      ),
      pinnedEmojis:
          (m['pinnedEmojis'] as List?)?.cast<String>() ?? d.pinnedEmojis,
      quickActivityMode: pickEnum(
        'quickActivityMode',
        QuickMode.values,
        d.quickActivityMode,
      ),
      remindersEnabled: pick('remindersEnabled', d.remindersEnabled),
      reminderLeadMin: pick('reminderLeadMin', d.reminderLeadMin),
      syncMode: pickEnum('syncMode', SyncMode.values, d.syncMode),
      ghostTitles: pick('ghostTitles', d.ghostTitles),
    );
  }

  AppSettings copyWith({
    ThemePref? theme,
    bool? amoled,
    bool? useDynamicColor,
    int? seedColor,
    int? snapStep,
    int? hourSnapStep,
    bool? use24h,
    QuickMode? quickEmojiMode,
    List<String>? pinnedEmojis,
    QuickMode? quickActivityMode,
    bool? remindersEnabled,
    int? reminderLeadMin,
    SyncMode? syncMode,
    bool? ghostTitles,
  }) => AppSettings(
    theme: theme ?? this.theme,
    amoled: amoled ?? this.amoled,
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    seedColor: seedColor ?? this.seedColor,
    snapStep: snapStep ?? this.snapStep,
    hourSnapStep: hourSnapStep ?? this.hourSnapStep,
    use24h: use24h ?? this.use24h,
    quickEmojiMode: quickEmojiMode ?? this.quickEmojiMode,
    pinnedEmojis: pinnedEmojis ?? this.pinnedEmojis,
    quickActivityMode: quickActivityMode ?? this.quickActivityMode,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderLeadMin: reminderLeadMin ?? this.reminderLeadMin,
    syncMode: syncMode ?? this.syncMode,
    ghostTitles: ghostTitles ?? this.ghostTitles,
  );
}

class SettingsRepo {
  SettingsRepo(this._db, this._clock);

  final AppDatabase _db;
  final HlcClock _clock;

  Stream<AppSettings> watch() => _db.select(_db.settings).watch().map(_decode);

  Future<AppSettings> load() async =>
      _decode(await _db.select(_db.settings).get());

  /// Writes only the keys whose values changed, each with a fresh HLC.
  Future<void> save(AppSettings next) async {
    final current = (await load()).toMap();
    final changed = next.toMap()
      ..removeWhere((k, v) => jsonEncode(current[k]) == jsonEncode(v));
    if (changed.isEmpty) return;
    await _db.batch((b) {
      for (final e in changed.entries) {
        b.insert(
          _db.settings,
          SettingsCompanion.insert(
            key: e.key,
            value: jsonEncode(e.value),
            hlc: _clock.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  static AppSettings _decode(List<SettingRow> rows) =>
      AppSettings.fromMap({for (final r in rows) r.key: jsonDecode(r.value)});
}
