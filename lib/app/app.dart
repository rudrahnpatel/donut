import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/repos/settings_repo.dart';
import 'providers.dart';
import 'shell.dart';
import 'theme/theme.dart';

class DonutApp extends ConsumerWidget {
  const DonutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
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
        return MaterialApp(
          title: 'Donut',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(light),
          darkTheme: buildTheme(dark),
          themeMode: switch (s.theme) {
            ThemePref.system => ThemeMode.system,
            ThemePref.light => ThemeMode.light,
            ThemePref.dark => ThemeMode.dark,
          },
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // emoji_picker_flutter still reads the framework's built-in Material
          // theme; the bridge hands it ours until it moves to material_ui.
          builder: (context, child) =>
              // ignore: deprecated_member_use
              MaterialUiCompatibilityBridge(child: child!),
          home: const AppShell(),
        );
      },
    );
  }
}
