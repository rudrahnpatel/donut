import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/time/day_minutes.dart';
import '../features/calendar/month_screen.dart';
import '../features/day/day_screen.dart';
import '../features/library/library_screen.dart';
import '../features/reminders/reminder_providers.dart';
import '../features/settings/settings_screen.dart';
import '../features/sync/sync_controller.dart';
import '../features/widget_bridge/widget_bridge.dart';
import 'providers.dart';

/// Which top-level destination is showing.
final shellTabProvider = NotifierProvider<ShellTab, int>(ShellTab.new);

class ShellTab extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) => state = i;
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  Timer? _midnight;

  static const _destinations = [
    (Icons.donut_large_rounded, Icons.donut_small_rounded, 'Today'),
    (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Month'),
    (Icons.category_rounded, Icons.category_outlined, 'Library'),
    (Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _onNewDay();
    startReminders(ref);
    startWidgetBridge(ref);
    ref.read(syncControllerProvider.notifier).start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sync = ref.read(syncControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        _onNewDay();
        // Notification permission may have changed in system settings.
        ref.invalidate(notificationsAllowedProvider);
        sync.setForeground(true);
        sync.syncNow();
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        sync.setForeground(false);
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// Refreshes "today", tops up recurring blocks, and re-arms the midnight
  /// timer. Safe to call repeatedly.
  void _onNewDay() {
    ref.read(todayProvider.notifier).refresh();
    ref.read(planToolsRepoProvider).generate(from: Day.today());
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnight = Timer(next.difference(now), _onNewDay);
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(shellTabProvider);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final body = IndexedStack(
      index: tab,
      children: const [
        DayScreen(),
        MonthScreen(),
        LibraryScreen(),
        SettingsScreen(),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: tab,
              onDestinationSelected: ref.read(shellTabProvider.notifier).set,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('🍩', style: TextStyle(fontSize: 28)),
              ),
              destinations: [
                for (final (sel, icon, label) in _destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(sel),
                    label: Text(label),
                  ),
              ],
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: ref.read(shellTabProvider.notifier).set,
        destinations: [
          for (final (sel, icon, label) in _destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(sel),
              label: label,
            ),
        ],
      ),
    );
  }
}
