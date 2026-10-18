import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';

/// Full emoji picker in a bottom sheet, rendered with the bundled font.
Future<String?> pickEmoji(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.55,
      child: EmojiPicker(
        onEmojiSelected: (_, e) => Navigator.pop(ctx, e.emoji),
        config: Config(
          emojiTextStyle: emojiStyle,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: scheme.surfaceContainerLow,
            columns: 8,
            emojiSizeMax: 30,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: scheme.surfaceContainerLow,
            indicatorColor: scheme.primary,
            iconColorSelected: scheme.primary,
            iconColor: scheme.onSurfaceVariant,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
          searchViewConfig: SearchViewConfig(
            backgroundColor: scheme.surfaceContainerLow,
          ),
        ),
      ),
    ),
  );
}

/// Pick one of the user's activities.
Future<String?> pickActivity(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final list = ref.watch(activitiesProvider).value ?? const [];
          final brightness = Theme.of(ctx).brightness;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in list)
                    ActionChip(
                      avatar: Text(
                        a.emoji,
                        style: emojiStyle.copyWith(fontSize: 18),
                      ),
                      label: Text(a.name),
                      side: BorderSide(
                        color: blockColor(a.color, brightness),
                        width: 2,
                      ),
                      onPressed: () => Navigator.pop(ctx, a.id),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

/// Asks for a start and end time; returns minutes-of-day `(start, end)`.
/// An end before the start means the block runs past midnight.
Future<(int, int)?> pickTimeRange(
  BuildContext context, {
  required int start,
  required int end,
}) async {
  final s = await showTimePicker(
    context: context,
    helpText: 'Starts at',
    initialTime: TimeOfDay(hour: (start ~/ 60) % 24, minute: start % 60),
  );
  if (s == null || !context.mounted) return null;
  final e = await showTimePicker(
    context: context,
    helpText: 'Ends at',
    initialTime: TimeOfDay(hour: (end ~/ 60) % 24, minute: end % 60),
  );
  if (e == null) return null;
  final sm = s.hour * 60 + s.minute;
  var em = e.hour * 60 + e.minute;
  if (em <= sm) em += 1440;
  return (sm, em);
}

Future<String?> promptText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
