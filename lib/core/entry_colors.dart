/// Colours for entries and activities, and how a new entry picks one.
library;

/// Distinct hues that stay readable in light and dark themes once passed
/// through `blockColor`.
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

/// A stable colour for an entry with none stored.
int fallbackEntryColor(String id) {
  var h = 0x811C9DC5;
  for (final c in id.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  return entryPalette[h % entryPalette.length];
}

/// A colour for an entry at `[start, end)` that differs from every entry
/// in [others] it touches or overlaps. [seed] (e.g. how many entries exist)
/// rotates where the search starts, so a day reads as many colours.
int pickEntryColor(
  Iterable<({int start, int end, int color})> others,
  int start,
  int end, {
  int seed = 0,
}) {
  final near = {
    for (final o in others)
      if (o.start <= end && o.end >= start) o.color,
  };
  for (var k = 0; k < entryPalette.length; k++) {
    final c = entryPalette[(seed + k) % entryPalette.length];
    if (!near.contains(c)) return c;
  }
  return entryPalette[seed % entryPalette.length];
}
