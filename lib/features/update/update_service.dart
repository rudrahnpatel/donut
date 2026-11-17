import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/db/app_database.dart';
import 'update_logic.dart';

/// Android only, and only when a release repo is configured.
bool get updatesSupported =>
    !kIsWeb && Platform.isAndroid && updateRepo.isNotEmpty;

/// Checks GitHub Releases, downloads the APK and hands it to the system
/// installer. Throttle and "skip this version" live in the device-local KV
/// (not synced settings): they're about this install, not the user's plan.
class UpdateService {
  UpdateService(this._db, {http.Client? client})
    : _client = client ?? http.Client();

  final AppDatabase _db;
  final http.Client _client;

  static const _channel = MethodChannel('donut/system');
  static const lastCheckKey = 'update_last_check';
  static const skippedTagKey = 'update_skipped_tag';
  static const autoCheckEvery = Duration(hours: 6);

  Future<AppVersion?> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return AppVersion.fromPackage(info.version, info.buildNumber);
  }

  Future<String> currentVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty
        ? info.version
        : '${info.version} (${info.buildNumber})';
  }

  /// The start-up check: at most every [autoCheckEvery], never offers a
  /// skipped version, and swallows every error (no network is normal).
  Future<UpdateOffer?> autoCheck() async {
    if (!updatesSupported) return null;
    try {
      final last = int.tryParse(await _db.getLocal(lastCheckKey) ?? '');
      final now = DateTime.now().millisecondsSinceEpoch;
      if (last != null &&
          now - last >= 0 &&
          now - last < autoCheckEvery.inMilliseconds) {
        return null;
      }
      final offer = await check();
      if (offer == null) return null;
      final skipped = await _db.getLocal(skippedTagKey);
      return offer.release.tag == skipped ? null : offer;
    } catch (e) {
      debugPrint('update check failed: $e');
      return null;
    }
  }

  /// One check against `releases/latest`; null when up to date or when the
  /// repo has no releases yet. Throws on network/HTTP errors.
  Future<UpdateOffer?> check() async {
    if (updateRepo.isEmpty) return null;
    final res = await _client
        .get(
          Uri.parse('https://api.github.com/repos/$updateRepo/releases/latest'),
          headers: {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'donut-app-updater',
          },
        )
        .timeout(const Duration(seconds: 20));
    await _db.setLocal(
      lastCheckKey,
      '${DateTime.now().millisecondsSinceEpoch}',
    );
    // No release published yet (or the repo doesn't exist): nothing to do.
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw HttpException('GitHub answered ${res.statusCode}');
    }
    final release = ReleaseInfo.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
    final current = await currentVersion();
    if (current == null) return null;
    return offerFor(release, current, deviceAbis: await _deviceAbis());
  }

  Future<void> skip(String tag) => _db.setLocal(skippedTagKey, tag);

  Future<List<String>> _deviceAbis() async {
    try {
      final abis = await _channel.invokeListMethod<String>('supportedAbis');
      if (abis != null && abis.isNotEmpty) return abis;
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
    return const ['arm64-v8a'];
  }

  /// Where [apk] is (or will be) saved: cacheDir/updates/, the folder the
  /// FileProvider shares with the installer.
  Future<File> apkFile(ReleaseAsset apk) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    await dir.create(recursive: true);
    final safe = apk.name.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_');
    return File('${dir.path}/$safe');
  }

  /// Downloads [apk], reporting progress 0..1, and checks the size matches
  /// what GitHub says. Reuses an earlier complete download (the install
  /// permission round-trip can restart the app). Old APKs are removed.
  Future<File> download(
    ReleaseAsset apk, {
    void Function(double progress)? onProgress,
  }) async {
    final file = await apkFile(apk);
    for (final old in file.parent.listSync().whereType<File>()) {
      if (old.path != file.path) await old.delete();
    }
    if (await file.exists() && await file.length() == apk.size) {
      onProgress?.call(1);
      return file;
    }
    final partial = File('${file.path}.part');
    final res = await _client.send(
      http.Request('GET', Uri.parse(apk.url))
        ..headers['User-Agent'] = 'donut-app-updater',
    );
    if (res.statusCode != 200) {
      throw HttpException('Download failed (${res.statusCode})');
    }
    final total = res.contentLength ?? apk.size;
    var got = 0;
    final sink = partial.openWrite();
    try {
      await for (final chunk in res.stream.timeout(
        const Duration(seconds: 30),
      )) {
        sink.add(chunk);
        got += chunk.length;
        if (total > 0) onProgress?.call((got / total).clamp(0, 1));
      }
    } finally {
      await sink.close();
    }
    final length = await partial.length();
    if (apk.size > 0 && length != apk.size) {
      await partial.delete();
      throw HttpException('Download incomplete ($length of ${apk.size} bytes)');
    }
    return partial.rename(file.path);
  }

  /// Whether Android lets Donut open the package installer ("Install
  /// unknown apps" for Donut).
  Future<bool> canInstall() async =>
      await _channel.invokeMethod<bool>('canInstallPackages') ?? false;

  Future<void> openInstallPermissionSettings() =>
      _channel.invokeMethod('openInstallPermissionSettings');

  /// Opens the system installer on [file]. The user confirms there; a
  /// normal app can't install silently.
  Future<void> install(File file) =>
      _channel.invokeMethod('installApk', {'path': file.path});
}
