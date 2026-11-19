import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Room to leave at the bottom of a scrolling list so its last item can
/// scroll clear of the floating nav bar. Inside the shell the bar is laid
/// out with `extendBody`, so the bottom padding already includes the bar
/// (and the system gesture area under it); elsewhere it is just the
/// system inset.
double floatingNavInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom;

/// Lifts a screen's floating action button above the floating nav bar: a
/// nested Scaffold places its FAB from the system inset alone, which would
/// leave it under the bar.
Widget aboveFloatingNav(BuildContext context, Widget fab) => Padding(
  padding: EdgeInsets.only(
    bottom:
        (floatingNavInset(context) - MediaQuery.viewPaddingOf(context).bottom)
            .clamp(0.0, double.infinity),
  ),
  child: fab,
);

typedef FloatingNavDestination = ({
  IconData icon,
  IconData selectedIcon,
  String label,
});

/// An iOS-style floating tab bar: a translucent, blurred pill inset from the
/// screen edges, with content scrolling underneath it. Sits above the
/// system gesture area and stays phone-sized on wide windows.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FloatingNavDestination> destinations;
  final int selectedIndex;

  /// Called for every tap, including on the tab already showing (so a
  /// screen can treat a second tap as "back to the start").
  final ValueChanged<int> onSelected;

  static const height = 64.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final system = MediaQuery.viewPaddingOf(context).bottom;
    final radius = BorderRadius.circular(height / 2);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, system + 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            // Clip first, or the blur would cover the whole screen.
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh.withValues(
                      alpha: dark ? 0.7 : 0.78,
                    ),
                    borderRadius: radius,
                    // A hairline keeps the pill visible on AMOLED black.
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      height: height,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            for (final (i, d) in destinations.indexed)
                              Expanded(
                                child: _NavItem(
                                  destination: d,
                                  selected: i == selectedIndex,
                                  onTap: () {
                                    if (i != selectedIndex) {
                                      HapticFeedback.selectionClick();
                                    }
                                    onSelected(i);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 52 : 36,
              height: 28,
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: selected
                    ? scheme.secondaryContainer
                    : scheme.secondaryContainer.withValues(alpha: 0),
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: fg,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: t.labelSmall?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
