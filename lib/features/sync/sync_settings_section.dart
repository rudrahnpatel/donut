import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../data/repos/settings_repo.dart';

/// Sync mode picker and Google account status.
class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              onSelectionChanged: (v) => ref
                  .read(settingsRepoProvider)
                  .save(s.copyWith(syncMode: v.single)),
            ),
            const SizedBox(height: 8),
            Text(switch (s.syncMode) {
              SyncMode.off => 'Everything stays on this device.',
              SyncMode.device =>
                'Syncs your plan between your devices through a hidden '
                    'Google Drive app folder.',
              SyncMode.calendar =>
                'Saved blocks go to a “Donut” Google calendar (2-way), '
                    'and your other calendars show as ghost arcs.',
            }),
          ],
        ),
      ),
    );
  }
}
