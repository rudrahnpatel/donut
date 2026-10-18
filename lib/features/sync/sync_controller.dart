import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:googleapis/calendar/v3.dart' show DetailedApiRequestError;

import '../../app/providers.dart';
import '../../data/repos/settings_repo.dart';
import 'calendar_sync.dart';
import 'drive_sync.dart';
import 'google_auth.dart';
import 'sync_store.dart';

/// What the Settings screen shows about sync.
class SyncStatus {
  const SyncStatus({
    this.account,
    this.busy = false,
    this.lastSync,
    this.summary,
    this.error,
    this.consenting = false,
  });

  /// The signed-in account (an email where available), or null.
  final String? account;
  final bool busy;
  final DateTime? lastSync;
  final String? summary;
  final String? error;

  /// Waiting for the user to finish Google's consent page (in the browser
  /// on desktop); can be cancelled.
  final bool consenting;

  bool get signedIn => account != null;

  SyncStatus copyWith({
    Object? account = _keep,
    bool? busy,
    DateTime? lastSync,
    String? summary,
    Object? error = _keep,
    bool? consenting,
  }) => SyncStatus(
    account: account == _keep ? this.account : account as String?,
    busy: busy ?? this.busy,
    lastSync: lastSync ?? this.lastSync,
    summary: summary ?? this.summary,
    error: error == _keep ? this.error : error as String?,
    consenting: consenting ?? this.consenting,
  );
}

const Object _keep = Object();

class _NeedsConsent implements Exception {
  const _NeedsConsent();
}

class _ConsentCancelled implements Exception {
  const _ConsentCancelled();
}

/// Busy times from your other Google calendars (absolute floating
/// minutes), drawn as ghost arcs. Empty unless calendar sync is on.
final ghostsProvider = NotifierProvider<GhostsNotifier, List<(int, int)>>(
  GhostsNotifier.new,
);

class GhostsNotifier extends Notifier<List<(int, int)>> {
  @override
  List<(int, int)> build() => const [];

  void set(List<(int, int)> v) => state = v;
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

/// Signs in, runs device sync (Drive) and, in calendar mode, the Donut
/// calendar mirror. Syncs at start, on resume, 3 s after local edits and
/// every 30 s while the app is in the foreground; a quiet poll is one Drive
/// list call (plus one calendar call in calendar mode).
class SyncController extends Notifier<SyncStatus> {
  late final GoogleAuth _auth = GoogleAuth();
  bool _started = false;
  Timer? _debounce;
  Timer? _periodic;
  StreamSubscription<void>? _changes;
  String? _timeZone;
  final _drive = DriveSyncMemo();
  DateTime _busyAt = DateTime(0);
  bool _foreground = true;
  Completer<void>? _cancelConsent;

  static const _ghostsKey = 'gcal_ghosts';
  static const _poll = Duration(seconds: 30);
  static const _busyEvery = Duration(minutes: 10);

  @override
  SyncStatus build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _periodic?.cancel();
      _changes?.cancel();
    });
    return const SyncStatus();
  }

  SyncMode get _mode => ref.read(settingsProvider).syncMode;

  static List<String> _scopes(SyncMode m) =>
      m == SyncMode.calendar ? GoogleScopes.calendar : GoogleScopes.device;

  Future<void> start() async {
    if (_started || !GoogleConfig.configured) return;
    _started = true;
    final db = ref.read(databaseProvider);
    final saved = await db.getLocal(_ghostsKey);
    if (saved != null) {
      ref.read(ghostsProvider.notifier).set([
        for (final p in (jsonDecode(saved) as List).cast<List>())
          (p[0] as int, p[1] as int),
      ]);
    }
    try {
      state = state.copyWith(account: await _auth.restore());
    } catch (e) {
      debugPrint('Sync: could not restore sign-in: $e');
    }
    _changes = db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            db.blocks,
            db.activities,
            db.todos,
            db.templates,
            db.series,
            db.settings,
          ]),
        )
        .listen((_) => _schedule());
    _periodic = Timer.periodic(_poll, (_) => syncNow());
    await syncNow();
  }

  /// Polls only while the app is in the foreground; coming back syncs at
  /// once.
  void setForeground(bool foreground) {
    if (!_started || foreground == _foreground) return;
    _foreground = foreground;
    _periodic?.cancel();
    _periodic = null;
    if (foreground) {
      _periodic = Timer.periodic(_poll, (_) => syncNow());
      syncNow();
    }
  }

  /// Syncs a little after local edits settle. Writes made by a sync itself
  /// are ignored; the periodic sync picks up anything missed meanwhile.
  void _schedule() {
    if (!state.signedIn || state.busy || _mode == SyncMode.off) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), syncNow);
  }

  Future<void> signIn() async {
    var mode = _mode;
    if (mode == SyncMode.off) mode = SyncMode.device;
    state = state.copyWith(busy: true, error: null);
    try {
      final account = await _consent(_scopes(mode));
      await _setModeSetting(mode);
      state = state.copyWith(account: account, busy: false);
    } catch (e) {
      state = state.copyWith(busy: false, error: _describe(e));
      return;
    }
    await syncNow();
  }

  /// Stops waiting for an unfinished consent page.
  void cancelSignIn() {
    final c = _cancelConsent;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Runs Google's consent flow, giving up on cancel or after 5 minutes.
  /// On desktop, a page Google blocks (e.g. "Access blocked") never
  /// redirects back to the app, so without this the wait never ends.
  Future<String> _consent(List<String> scopes) async {
    final cancel = _cancelConsent = Completer<void>();
    state = state.copyWith(consenting: true);
    try {
      return await Future.any([
        _auth.signIn(scopes),
        cancel.future.then<String>((_) => throw const _ConsentCancelled()),
      ]).timeout(const Duration(minutes: 5));
    } finally {
      _cancelConsent = null;
      state = state.copyWith(consenting: false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _drive.versions.clear();
    _drive.uploadedHlc = null;
    ref.read(ghostsProvider.notifier).set(const []);
    state = const SyncStatus();
  }

  /// Switches mode; calendar mode asks for the extra calendar access first.
  Future<void> setMode(SyncMode mode) async {
    if (mode == SyncMode.off) {
      ref.read(ghostsProvider.notifier).set(const []);
      await _setModeSetting(mode);
      return;
    }
    if (!state.signedIn) {
      await _setModeSetting(mode);
      return;
    }
    if (await _auth.client(_scopes(mode)) == null) {
      try {
        await _consent(_scopes(mode));
      } catch (e) {
        state = state.copyWith(error: _describe(e));
        return;
      }
    }
    if (mode != SyncMode.calendar) {
      ref.read(ghostsProvider.notifier).set(const []);
    }
    _busyAt = DateTime(0);
    await _setModeSetting(mode);
    await syncNow();
  }

  Future<void> _setModeSetting(SyncMode mode) async {
    final s = ref.read(settingsProvider);
    if (s.syncMode != mode) {
      await ref.read(settingsRepoProvider).save(s.copyWith(syncMode: mode));
    }
  }

  Future<void> syncNow() async {
    final mode = _mode;
    if (mode == SyncMode.off || !state.signedIn || state.busy) return;
    state = state.copyWith(busy: true, error: null);
    try {
      final client = await _auth.client(_scopes(mode));
      if (client == null) throw const _NeedsConsent();
      try {
        final db = ref.read(databaseProvider);
        final clock = ref.read(hlcClockProvider);
        final device = await db.getLocal('device_id') ?? 'device';
        final merged = await DriveSync(
          SyncStore(db, clock),
          device,
          _drive,
        ).run(client);
        var summary = merged == 0 ? 'Up to date' : '$merged changes merged';
        if (mode == SyncMode.calendar) {
          final activities = ref.read(activityMapProvider);
          final result = await CalendarSync(
            db,
            clock,
            titleFor: (b) => b.note ?? activities[b.activityId]?.name,
            timeZone: _timeZone ??=
                (await FlutterTimezone.getLocalTimezone()).identifier,
          ).run(client, busy: DateTime.now().difference(_busyAt) > _busyEvery);
          if (result.busy case final busy?) {
            _busyAt = DateTime.now();
            ref.read(ghostsProvider.notifier).set(busy);
            await db.setLocal(
              _ghostsKey,
              jsonEncode([
                for (final (s, e) in busy) [s, e],
              ]),
            );
          }
          summary += ' · calendar ↑${result.pushed} ↓${result.pulled}';
        }
        state = state.copyWith(
          busy: false,
          lastSync: DateTime.now(),
          summary: summary,
        );
      } finally {
        client.close();
      }
    } catch (e) {
      state = state.copyWith(busy: false, error: _describe(e));
    }
  }

  static String _describe(Object e) => switch (e) {
    _NeedsConsent() => 'Google needs you to allow access again: tap Sign in.',
    _ConsentCancelled() => 'Sign-in cancelled.',
    TimeoutException() =>
      'Sign-in didn\'t finish. If Google said "Access blocked", see '
          'docs/google-setup.md (Troubleshooting).',
    DetailedApiRequestError(:final status, :final message) =>
      'Google returned an error ($status): ${message ?? 'no details'}',
    SocketException() ||
    HttpException() => 'Offline; will retry automatically.',
    _ => '$e',
  };
}
