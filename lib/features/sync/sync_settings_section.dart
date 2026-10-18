import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../data/repos/settings_repo.dart';
import 'google_auth.dart';
import 'sync_controller.dart';

/// Google account, sync mode and status.
class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final status = ref.watch(syncControllerProvider);
    final sync = ref.read(syncControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (!GoogleConfig.configured) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off_rounded),
          title: const Text('Google sync isn\'t set up in this build'),
          subtitle: const Text(
            'Create OAuth client ids and build with '
            '--dart-define-from-file=google.json (see docs/google-setup.md).',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.signedIn
                      ? Icons.account_circle_rounded
                      : Icons.cloud_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.account ?? 'Not signed in',
                    style: t.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (status.signedIn)
                  TextButton(
                    onPressed: sync.signOut,
                    child: const Text('Sign out'),
                  )
                else if (status.consenting)
                  TextButton(
                    onPressed: sync.cancelSignIn,
                    child: const Text('Cancel'),
                  )
                else
                  FilledButton.icon(
                    onPressed: status.busy ? null : sync.signIn,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Sign in with Google'),
                  ),
              ],
            ),
            if (status.consenting) ...[
              const SizedBox(height: 8),
              Text(
                Platform.isAndroid
                    ? 'Signing in with Google…'
                    : 'Finish signing in with Google in your browser…',
                style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ] else if (!status.signedIn && status.error != null) ...[
              const SizedBox(height: 8),
              Text(
                status.error!,
                style: t.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<SyncMode>(
              segments: const [
                ButtonSegment(value: SyncMode.off, label: Text('Off')),
                ButtonSegment(value: SyncMode.device, label: Text('Devices')),
                ButtonSegment(
                  value: SyncMode.calendar,
                  label: Text('Calendar'),
                ),
              ],
              selected: {s.syncMode},
              onSelectionChanged: status.busy
                  ? null
                  : (v) => sync.setMode(v.single),
            ),
            const SizedBox(height: 8),
            Text(switch (s.syncMode) {
              SyncMode.off => 'Everything stays on this device.',
              SyncMode.device =>
                'Your entries, tasks and settings sync between your devices through a hidden '
                    'Google Drive folder only Donut can see.',
              SyncMode.calendar =>
                'Device sync, plus your saved entries in a "Donut" Google calendar (edits there '
                    'come back here) and busy times from your other calendars as faint arcs.',
            }),
            if (status.signedIn && s.syncMode != SyncMode.off) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: status.busy
                        ? const LinearProgressIndicator()
                        : Text(
                            status.error ??
                                (status.lastSync == null
                                    ? 'Not synced yet'
                                    : 'Synced ${DateFormat.jm().format(status.lastSync!)} · '
                                          '${status.summary}'),
                            style: t.bodySmall?.copyWith(
                              color: status.error != null
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: status.busy ? null : sync.syncNow,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync now'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
