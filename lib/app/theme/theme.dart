import 'package:material_ui/material_ui.dart';

const emojiFontFamily = 'Twemoji';

/// Text style for emoji glyphs: the bundled Twemoji font looks the same on
/// every platform (Linux often has no colour emoji font at all).
const emojiStyle = TextStyle(fontFamily: emojiFontFamily, height: 1.1);

ThemeData buildTheme(ColorScheme scheme) {
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'Nunito',
    fontFamilyFallback: const [emojiFontFamily],
  );
  final text = base.textTheme.apply(fontFamily: 'Nunito');
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorShape: const StadiumBorder(),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorShape: const StadiumBorder(),
    ),
  );
}

/// Dark scheme with pure-black surfaces for OLED screens.
ColorScheme amoled(ColorScheme dark) => dark.copyWith(
  surface: Colors.black,
  surfaceDim: Colors.black,
  surfaceBright: const Color(0xFF232328),
  surfaceContainerLowest: Colors.black,
  surfaceContainerLow: const Color(0xFF0A0A0C),
  surfaceContainer: const Color(0xFF0F0F12),
  surfaceContainerHigh: const Color(0xFF16161A),
  surfaceContainerHighest: const Color(0xFF1E1E23),
);

final _blockColorCache = <(int, Brightness), Color>{};

/// Normalises an activity colour so blocks read well on either brightness.
Color blockColor(int argb, Brightness brightness) =>
    _blockColorCache.putIfAbsent((argb, brightness), () {
      final hsl = HSLColor.fromColor(Color(argb));
      final dark = brightness == Brightness.dark;
      return hsl
          .withSaturation(hsl.saturation.clamp(0.45, dark ? 0.7 : 0.75))
          .withLightness(dark ? 0.66 : 0.6)
          .toColor();
    });

/// Readable foreground on a block colour.
Color onBlockColor(Color c) =>
    c.computeLuminance() > 0.45 ? const Color(0xFF1B1B1F) : Colors.white;

/// Colours for entries and activities: distinct hues that stay readable in
/// light and dark themes once passed through [blockColor].
const entryPalette = [
  0xFF7C6CF2,
  0xFF3E8ED0,
  0xFF26A69A,
  0xFF43B581,
  0xFF9CCC65,
  0xFFF2A541,
  0xFFE5604D,
  0xFFE86A92,
  0xFFAB47BC,
  0xFF8D6E63,
  0xFF5C6B8A,
];

/// A stable colour for an entry with none stored (templates, older data).
int fallbackEntryColor(String id) {
  var h = 0x811C9DC5;
  for (final c in id.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  return entryPalette[h % entryPalette.length];
}
