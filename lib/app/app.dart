import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/repos/settings_repo.dart';
import '../features/day/plan_mode.dart';
import '../features/mcp/mcp_provider.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'providers.dart';
import 'shell.dart';
import 'theme/theme.dart';

class DonutApp extends ConsumerWidget {
  const DonutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final planning = ref.watch(planningProvider);
    // Desktop: keeps the localhost MCP server for Claude running.
    ref.listen(mcpServerProvider, (_, _) {});
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final seed = Color(s.seedColor);
        var light = ColorScheme.fromSeed(seedColor: seed);
        var dark = ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        );
        if (s.useDynamicColor && lightDynamic != null && darkDynamic != null) {
          // Rebuild from the platform's primary so every tone is filled in;
          // some platforms hand back sparse schemes.
          light = ColorScheme.fromSeed(seedColor: lightDynamic.primary);
          dark = ColorScheme.fromSeed(
            seedColor: darkDynamic.primary,
            brightness: Brightness.dark,
          );
        }
        if (s.amoled) dark = amoled(dark);
        // Plan mode is a different place, like an incognito window: the
        // whole app turns to one night-violet palette, whatever the normal
        // theme, and fades back when the plan is saved or discarded.
        final plan = ColorScheme.fromSeed(
          seedColor: planSeed,
          brightness: Brightness.dark,
        );
        return MaterialApp(
          title: 'Donut',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(planning ? plan : light),
          darkTheme: buildTheme(planning ? plan : dark),
          themeMode: planning
              ? ThemeMode.dark
              : switch (s.theme) {
                  ThemePref.system => ThemeMode.system,
                  ThemePref.light => ThemeMode.light,
                  ThemePref.dark => ThemeMode.dark,
                },
          themeAnimationDuration: const Duration(milliseconds: 450),
          themeAnimationCurve: Curves.easeInOutCubic,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // emoji_picker_flutter still reads the framework's built-in Material
          // theme; the bridge hands it ours until it moves to material_ui.
          builder: (context, child) =>
              // ignore: deprecated_member_use
              MaterialUiCompatibilityBridge(child: child!),
          home: const _Home(),
        );
      },
    );
  }
}

/// The welcome tour on a device's first run, then the app.
class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(onboardedProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: onboarded
          ? const AppShell()
          : OnboardingScreen(
              onDone: () => ref.read(onboardedProvider.notifier).finish(),
            ),
    );
  }
}
