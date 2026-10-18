import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'merge.dart';
import 'sync_store.dart';

/// Device sync through the app's hidden Drive folder (`drive.appdata`).
///
/// Each device writes only its own file, `donut-state-<device>.json`, and
/// reads everyone else's. Drive has no conditional writes, so a shared file
/// could lose updates; per-device files can't, and last-writer-wins
/// merging makes the order of reads irrelevant.
class DriveSync {
  DriveSync(this._store, this._device);

  final SyncStore _store;
  final String _device;

  static const _prefix = 'donut-state-';

  /// Merges other devices' files into the local database, then uploads this
  /// device's merged state. Returns how many local rows changed.
  Future<int> run(http.Client client) async {
    final api = drive.DriveApi(client);
    final mine = '$_prefix$_device.json';
    final listing = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains '$_prefix'",
      $fields: 'files(id,name)',
      pageSize: 100,
    );

    String? myFileId;
    final remotes = <Snapshot>[];
    for (final f in listing.files ?? const <drive.File>[]) {
      if (f.name == mine) {
        myFileId = f.id;
        continue;
      }
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
    }

    final local = await _store.snapshot(_device);
    final changed = await _store.apply(rowsToApply(local, remotes));
    final state = changed > 0 ? await _store.snapshot(_device) : local;

    final body = utf8.encode(jsonEncode(state.toJson()));
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
    return changed;
  }
}
