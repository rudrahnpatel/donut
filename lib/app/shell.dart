import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/time/day_minutes.dart';
import '../features/calendar/month_screen.dart';
import '../features/day/day_screen.dart';
import '../features/day/dial_mode.dart';
import '../features/library/library_screen.dart';
import '../features/library/routine_migration.dart';
import '../features/reminders/reminder_providers.dart';
import '../features/settings/settings_screen.dart';
import '../features/sync/sync_controller.dart';
import '../features/update/update_ui.dart';
import '../features/widget_bridge/widget_bridge.dart';
import '../features/work/work_import.dart';
import 'floating_nav_bar.dart';
import 'providers.dart';

/// Which top-level destination is showing.
final shellTabProvider = NotifierProvider<ShellTab, int>(ShellTab.new);

class ShellTab extends Notifier<int> {
  ShellTab([this._initial = 0]);

  final int _initial;

  @override
  int build() => _initial;

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

  static const List<FloatingNavDestination> _destinations = [
    (
      selectedIcon: Icons.donut_large_rounded,
      icon: Icons.donut_small_rounded,
      label: 'Today',
    ),
    (
      selectedIcon: Icons.calendar_month_rounded,
      icon: Icons.calendar_month_outlined,
      label: 'Month',
    ),
    (
      selectedIcon: Icons.category_rounded,
      icon: Icons.category_outlined,
      label: 'Library',
    ),
    (
      selectedIcon: Icons.settings_rounded,
      icon: Icons.settings_outlined,
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _onNewDay();
    startReminders(ref);
    startWidgetBridge(ref);
    startWorkImport(ref);
    ref.read(syncControllerProvider.notifier).start();
    // New routine categories, once this launch's first sync has landed.
    startRoutineMigration(ref);
    // Android: offer a newer GitHub release (at most every 6 h).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkForUpdateOnStart(context, ref);
    });
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

  /// A tap on the tab already showing goes back to its start: Today
  /// returns to today's day dial.
  void _onTab(int i) {
    final tab = ref.read(shellTabProvider);
    if (i == tab && i == 0) {
      ref.read(focusedDayProvider.notifier).set(ref.read(todayProvider));
      ref.read(dialModeProvider.notifier).set(const DialMode.day());
    }
    ref.read(shellTabProvider.notifier).set(i);
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(shellTabProvider);
    // The bar floats over the screens (extendBody), on phones and wide
    // windows alike; screens pad their lists with `floatingNavInset`.
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: tab,
        children: const [
          DayScreen(),
          MonthScreen(),
          LibraryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        destinations: _destinations,
        selectedIndex: tab,
        onSelected: _onTab,
      ),
    );
  }
}
