import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import 'update_logic.dart';
import 'update_service.dart';

final updateServiceProvider = Provider(
  (ref) => UpdateService(ref.watch(databaseProvider)),
);

/// "1.2.3 (45)" for Settings › About.
final appVersionLabelProvider = FutureProvider<String>(
  (ref) => ref.watch(updateServiceProvider).currentVersionLabel(),
);

/// Start-up check (Android release builds only, at most every 6 h). Shows
/// the prompt when a newer release is out.
Future<void> checkForUpdateOnStart(BuildContext context, WidgetRef ref) async {
  // Debug builds are debug-signed; Android would refuse the update.
  if (!updatesSupported || kDebugMode) return;
  final offer = await ref.read(updateServiceProvider).autoCheck();
  if (offer == null || !context.mounted) return;
  await showUpdatePrompt(context, ref, offer);
}

/// The manual "Check for updates": ignores the throttle and skipped
/// versions, and says what happened.
Future<void> checkForUpdateNow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  say('Checking for updates…');
  try {
    final offer = await ref.read(updateServiceProvider).check();
    messenger.hideCurrentSnackBar();
    if (offer == null) {
      say('Donut is up to date.');
    } else if (context.mounted) {
      await showUpdatePrompt(context, ref, offer);
    }
  } catch (e) {
    say("Couldn't check for updates: $e");
  }
}

enum _Choice { later, skip, update }

Future<void> showUpdatePrompt(
  BuildContext context,
  WidgetRef ref,
  UpdateOffer offer,
) async {
  final service = ref.read(updateServiceProvider);
  final mb = (offer.apk.size / (1024 * 1024)).toStringAsFixed(1);
  final notes = offer.release.notes.trim();
  final choice = await showDialog<_Choice>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.system_update_rounded),
      title: Text('Donut ${offer.version} is out'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (notes.isNotEmpty) ...[Text(notes), const SizedBox(height: 12)],
            Text(
              '$mb MB download. Android will ask you to confirm the install.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _Choice.skip),
          child: const Text('Skip this version'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _Choice.later),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _Choice.update),
          child: const Text('Update'),
        ),
      ],
    ),
  );
  switch (choice) {
    case _Choice.skip:
      await service.skip(offer.release.tag);
    case _Choice.update:
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _UpdateDownload(service: service, offer: offer),
        );
      }
    case _Choice.later || null:
      break;
  }
}

/// Download progress, then the install hand-off (with the "Install unknown
/// apps" detour when Android hasn't allowed it yet).
class _UpdateDownload extends StatefulWidget {
  const _UpdateDownload({required this.service, required this.offer});

  final UpdateService service;
  final UpdateOffer offer;

  @override
  State<_UpdateDownload> createState() => _UpdateDownloadState();
}

class _UpdateDownloadState extends State<_UpdateDownload>
    with WidgetsBindingObserver {
  double? _progress;
  File? _file;
  String? _error;
  bool _needsPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _download();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from "Install unknown apps": carry on if it was allowed.
    if (state == AppLifecycleState.resumed && _needsPermission) _install();
  }

  Future<void> _download() async {
    setState(() {
      _error = null;
      _progress = 0;
    });
    try {
      final file = await widget.service.download(
        widget.offer.apk,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() => _file = file);
      await _install();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _install() async {
    final file = _file;
    if (file == null) return;
    try {
      if (!await widget.service.canInstall()) {
        if (mounted) setState(() => _needsPermission = true);
        return;
      }
      if (mounted) setState(() => _needsPermission = false);
      await widget.service.install(file);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _file != null;
    return AlertDialog(
      title: Text('Donut ${widget.offer.version}'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (_needsPermission)
            const Text(
              'To install updates, allow Donut to "Install unknown apps", '
              'then come back here.',
            )
          else if (!ready) ...[
            const Text('Downloading…'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress),
          ] else
            const Text(
              'Downloaded. Confirm the install on the Android screen; '
              'Donut restarts on the new version.',
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ready || _error != null ? 'Close' : 'Cancel'),
        ),
        if (_error != null)
          FilledButton(
            onPressed: ready ? _install : _download,
            child: const Text('Retry'),
          )
        else if (_needsPermission)
          FilledButton(
            onPressed: widget.service.openInstallPermissionSettings,
            child: const Text('Open settings'),
          )
        else if (ready)
          FilledButton(onPressed: _install, child: const Text('Install')),
      ],
    );
  }
}

/// Settings › About rows: the running version and, on Android, "Check for
/// updates".
class UpdateSettingsTiles extends ConsumerWidget {
  const UpdateSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionLabelProvider).value;
    return ListTile(
      leading: const Icon(Icons.system_update_rounded),
      title: Text(updatesSupported ? 'Check for updates' : 'Version'),
      subtitle: Text(
        [
          if (version != null) 'Version $version',
          if (updatesSupported) 'from github.com/$updateRepo',
        ].join(' · '),
      ),
      onTap: updatesSupported ? () => checkForUpdateNow(context, ref) : null,
    );
  }
}
