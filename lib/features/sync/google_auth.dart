import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// OAuth client ids, passed at build time:
/// `flutter build … --dart-define-from-file=google.json` (see
/// docs/google-setup.md). Empty when the build has no Google setup.
abstract final class GoogleConfig {
  /// The Web client id; Android sign-in needs it as `serverClientId`.
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// A "Desktop app" client for Linux and Windows. Google treats its
  /// secret as not confidential for installed apps.
  static const desktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
  );
  static const desktopClientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
  );

  static bool get configured =>
      !kIsWeb &&
      (Platform.isAndroid
          ? serverClientId.isNotEmpty
          : desktopClientId.isNotEmpty);
}

abstract final class GoogleScopes {
  /// The app's hidden Drive folder: device sync.
  static const drive = 'https://www.googleapis.com/auth/drive.appdata';

  /// Create the "Donut" calendar and manage only its events.
  static const calendarAppCreated =
      'https://www.googleapis.com/auth/calendar.app.created';

  /// List your calendars and read their busy times (ghost arcs) without
  /// seeing what the events are.
  static const calendarList =
      'https://www.googleapis.com/auth/calendar.calendarlist.readonly';
  static const freeBusy =
      'https://www.googleapis.com/auth/calendar.events.freebusy';

  static const device = [drive];
  static const calendar = [drive, calendarAppCreated, calendarList, freeBusy];
}

/// Sign-in and authorised HTTP clients for Google APIs, per platform.
abstract class GoogleAuth {
  factory GoogleAuth() =>
      Platform.isAndroid ? _AndroidGoogleAuth() : _DesktopGoogleAuth();

  /// Restores a previous sign-in without any UI. Returns the account
  /// label (an email where available), or null if signed out.
  Future<String?> restore();

  /// Interactive sign-in granting [scopes]. Returns the account label.
  Future<String> signIn(List<String> scopes);

  /// A client authorised for [scopes], or null if the user has to grant
  /// them interactively first.
  Future<http.Client?> client(List<String> scopes);

  Future<void> signOut();
}

// ── Android: Google Sign-In + Credential Manager ─────────────────────────

class _AndroidGoogleAuth implements GoogleAuth {
  final _gsi = GoogleSignIn.instance;
  GoogleSignInAccount? _account;
  Future<void>? _init;

  Future<void> _ready() =>
      _init ??= _gsi.initialize(serverClientId: GoogleConfig.serverClientId);

  @override
  Future<String?> restore() async {
    await _ready();
    _account = await _gsi.attemptLightweightAuthentication();
    return _account?.email;
  }

  @override
  Future<String> signIn(List<String> scopes) async {
    await _ready();
    final account = _account ?? await _gsi.authenticate(scopeHint: scopes);
    _account = account;
    await account.authorizationClient.authorizeScopes(scopes);
    return account.email;
  }

  @override
  Future<http.Client?> client(List<String> scopes) async {
    final account = _account;
    if (account == null) return null;
    // Access tokens last about an hour and carry no expiry here, so ask
    // for a fresh one on every sync run.
    final authz = await account.authorizationClient.authorizationForScopes(
      scopes,
    );
    return authz?.authClient(scopes: scopes);
  }

  @override
  Future<void> signOut() async {
    await _ready();
    await _gsi.disconnect();
    _account = null;
  }
}

// ── Linux / Windows: browser consent with a loopback redirect ────────────

class _DesktopGoogleAuth implements GoogleAuth {
  static const _key = 'google_credentials';
  static const _emailScope = 'email';

  final _secure = const FlutterSecureStorage();
  gauth.AccessCredentials? _creds;
  String? _label;

  gauth.ClientId get _clientId => gauth.ClientId(
    GoogleConfig.desktopClientId,
    GoogleConfig.desktopClientSecret,
  );

  @override
  Future<String?> restore() async {
    final raw = await _read();
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _creds = gauth.AccessCredentials.fromJson(
      json['credentials'] as Map<String, dynamic>,
    );
    _label = json['label'] as String? ?? 'Google account';
    return _label;
  }

  @override
  Future<String> signIn(List<String> scopes) async {
    final base = http.Client();
    try {
      final creds = await gauth.obtainAccessCredentialsViaUserConsent(
        _clientId,
        {...scopes, _emailScope}.toList(),
        base,
        (url) =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      );
      _creds = creds;
      _label = await _email(creds, base) ?? 'Google account';
      await _save();
      return _label!;
    } finally {
      base.close();
    }
  }

  @override
  Future<http.Client?> client(List<String> scopes) async {
    final creds = _creds;
    if (creds == null || !scopes.every(creds.scopes.contains)) return null;
    final client = gauth.autoRefreshingClient(_clientId, creds, http.Client());
    // Refreshed tokens are saved so the next start can reuse them.
    client.credentialUpdates.listen((c) {
      _creds = c;
      _save();
    });
    return client;
  }

  @override
  Future<void> signOut() async {
    _creds = null;
    _label = null;
    try {
      await _secure.delete(key: _key);
    } catch (_) {}
    final f = await _fallbackFile();
    if (await f.exists()) await f.delete();
  }

  Future<String?> _email(
    gauth.AccessCredentials creds,
    http.Client base,
  ) async {
    try {
      final r = await gauth
          .authenticatedClient(base, creds)
          .get(Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'));
      return (jsonDecode(r.body) as Map<String, dynamic>)['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final raw = jsonEncode({'credentials': _creds!.toJson(), 'label': _label});
    try {
      await _secure.write(key: _key, value: raw);
      return;
    } catch (e) {
      // No Secret Service (gnome-keyring / KWallet) running: fall back to
      // a file only this user can read.
      debugPrint('Secure storage unavailable ($e); using a private file');
    }
    final f = await _fallbackFile();
    await f.writeAsString(raw);
    if (!Platform.isWindows) await Process.run('chmod', ['600', f.path]);
  }

  Future<String?> _read() async {
    try {
      final v = await _secure.read(key: _key);
      if (v != null) return v;
    } catch (_) {}
    final f = await _fallbackFile();
    return await f.exists() ? f.readAsString() : null;
  }

  Future<File> _fallbackFile() async => File(
    '${(await getApplicationSupportDirectory()).path}/google_credentials.json',
  );
}
