import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../data/repos/settings_repo.dart';
import '../sync/sync_settings_section.dart';

const _seedChoices = [
  0xFFE86A92,
  0xFFF2A541,
  0xFF43B581,
  0xFF26A69A,
  0xFF3E8ED0,
  0xFF7C6CF2,
  0xFFAB47BC,
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final repo = ref.read(settingsRepoProvider);
    final scheme = Theme.of(context).colorScheme;
    void set(AppSettings next) => repo.save(next);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
        children: [
          const _Header('Appearance'),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SegmentedButton<ThemePref>(
                    segments: const [
                      ButtonSegment(
                        value: ThemePref.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded),
                      ),
                      ButtonSegment(
                        value: ThemePref.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: ThemePref.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                    ],
                    selected: {s.theme},
                    onSelectionChanged: (v) => set(s.copyWith(theme: v.single)),
                  ),
                ),
                SwitchListTile(
                  title: const Text('AMOLED black'),
                  subtitle: const Text('Pure black backgrounds in dark mode'),
                  value: s.amoled,
                  onChanged: (v) => set(s.copyWith(amoled: v)),
                ),
                SwitchListTile(
                  title: const Text('Material You colours'),
                  subtitle: const Text(
                    'Follow your wallpaper or system accent',
                  ),
                  value: s.useDynamicColor,
                  onChanged: (v) => set(s.copyWith(useDynamicColor: v)),
                ),
                if (!s.useDynamicColor)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in _seedChoices)
                          GestureDetector(
                            onTap: () => set(s.copyWith(seedColor: c)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.onSurface,
                                  width: s.seedColor == c ? 3 : 0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                SwitchListTile(
                  title: const Text('24-hour time'),
                  value: s.use24h,
                  onChanged: (v) => set(s.copyWith(use24h: v)),
                ),
              ],
            ),
          ),
          const _Header('Planner'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Snap on the day dial'),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 5, label: Text('5m')),
                      ButtonSegment(value: 10, label: Text('10m')),
                      ButtonSegment(value: 15, label: Text('15m')),
                      ButtonSegment(value: 30, label: Text('30m')),
                    ],
                    selected: {s.snapStep},
                    onSelectionChanged: (v) =>
                        set(s.copyWith(snapStep: v.single)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Snap on the hour dial'),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1m')),
                      ButtonSegment(value: 5, label: Text('5m')),
                      ButtonSegment(value: 10, label: Text('10m')),
                      ButtonSegment(value: 15, label: Text('15m')),
                    ],
                    selected: {s.hourSnapStep},
                    onSelectionChanged: (v) =>
                        set(s.copyWith(hourSnapStep: v.single)),
                  ),
                ],
              ),
            ),
          ),
          const _Header('Hold menu'),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('Tasks shown'),
                  subtitle: Text(
                    s.quickActivityMode == QuickMode.auto
                        ? 'Pinned first, then most used'
                        : 'Pinned first, then your Library order',
                  ),
                  trailing: SegmentedButton<QuickMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: QuickMode.auto, label: Text('Auto')),
                      ButtonSegment(
                        value: QuickMode.pinned,
                        label: Text('Order'),
                      ),
                    ],
                    selected: {s.quickActivityMode},
                    onSelectionChanged: (v) =>
                        set(s.copyWith(quickActivityMode: v.single)),
                  ),
                ),
              ],
            ),
          ),
          const _Header('Reminders'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Remind me when a block starts'),
                  subtitle: const Text('Saved blocks only — drafts stay quiet'),
                  value: s.remindersEnabled,
                  onChanged: (v) => set(s.copyWith(remindersEnabled: v)),
                ),
                ListTile(
                  enabled: s.remindersEnabled,
                  title: const Text('Notify'),
                  trailing: DropdownButton<int>(
                    value: s.reminderLeadMin,
                    underline: const SizedBox.shrink(),
                    onChanged: s.remindersEnabled
                        ? (v) => set(s.copyWith(reminderLeadMin: v))
                        : null,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('At start')),
                      DropdownMenuItem(value: 5, child: Text('5 min before')),
                      DropdownMenuItem(value: 10, child: Text('10 min before')),
                      DropdownMenuItem(value: 15, child: Text('15 min before')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _Header('Sync'),
          const SyncSettingsSection(),
          const _Header('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Text('🍩', style: TextStyle(fontSize: 28)),
                  title: Text('Donut'),
                  subtitle: Text('Plan your day on a clock.'),
                ),
                ListTile(
                  title: const Text('Licences'),
                  subtitle: const Text(
                    'Emoji: Twemoji by Twitter, Inc. and contributors, CC-BY 4.0 '
                    '(Mozilla build). Font: Nunito, SIL OFL 1.1.',
                  ),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Donut',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
