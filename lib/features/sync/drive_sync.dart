import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'merge.dart';
import 'sync_store.dart';

/// What [DriveSync] remembers between runs so a quiet poll costs one list
/// call: the version of each remote file already merged, and the newest
/// change already uploaded.
class DriveSyncMemo {
  final versions = <String, String>{};
  String? uploadedHlc;
}

/// Device sync through the app's hidden Drive folder (`drive.appdata`).
///
/// Each device writes only its own file, `donut-state-<device>.json`, and
/// reads everyone else's. Drive has no conditional writes, so a shared file
/// could lose updates; per-device files can't, and last-writer-wins
/// merging makes the order of reads irrelevant.
class DriveSync {
  DriveSync(this._store, this._device, this._memo);

  final SyncStore _store;
  final String _device;
  final DriveSyncMemo _memo;

  static const _prefix = 'donut-state-';

  /// Merges other devices' changed files into the local database, then
  /// uploads this device's state if it changed. Returns how many local rows
  /// changed.
  Future<int> run(http.Client client) async {
    final api = drive.DriveApi(client);
    final mine = '$_prefix$_device.json';

    // The app folder holds only Donut's files, so list it all and filter
    // here rather than trust Drive's word-prefix `name contains` search.
    final files = <drive.File>[];
    String? pageToken;
    do {
      final page = await api.files.list(
        spaces: 'appDataFolder',
        $fields: 'nextPageToken, files(id, name, version)',
        pageSize: 100,
        pageToken: pageToken,
      );
      files.addAll(page.files ?? const []);
      pageToken = page.nextPageToken;
    } while (pageToken != null);

    String? myFileId;
    final remotes = <Snapshot>[];
    final merged = <String, String>{};
    for (final f in files) {
      final name = f.name ?? '';
      if (!name.startsWith(_prefix) || f.id == null) continue;
      if (name == mine) {
        myFileId ??= f.id;
        continue;
      }
      if (f.version != null && _memo.versions[f.id] == f.version) continue;
      final media = await api.files.get(
        f.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      try {
        remotes.add(
          Snapshot.fromJson(
            jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
          ),
        );
      } on FormatException {
        // A half-written or foreign file: skip it rather than fail the sync.
      }
      if (f.version != null) merged[f.id!] = f.version!;
    }

    var local = await _store.snapshot(_device);
    var changed = 0;
    if (remotes.isNotEmpty) {
      changed = await _store.apply(rowsToApply(local, remotes));
      if (changed > 0) local = await _store.snapshot(_device);
    }
    // Only once applied: a failed merge is retried on the next run.
    _memo.versions.addAll(merged);

    final newest = local.newestHlc;
    if (myFileId != null && newest == _memo.uploadedHlc) return changed;
    final body = utf8.encode(jsonEncode(local.toJson()));
    final media = drive.Media(
      Stream.value(body),
      body.length,
      contentType: 'application/json',
    );
    if (myFileId == null) {
      await api.files.create(
        drive.File(name: mine, parents: ['appDataFolder']),
        uploadMedia: media,
      );
    } else {
      await api.files.update(drive.File(), myFileId, uploadMedia: media);
    }
    _memo.uploadedHlc = newest;
    return changed;
  }
}
