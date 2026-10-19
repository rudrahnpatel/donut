# Running late

## What

"I'm running late" moves today's plan out of the way.
- **Where:** the ✨ menu → *Running late…* (only when viewing today), or **+5 / +10 min
  late** on the countdown notification.
- **The rule:** the entry under way runs longer, and later entries move only as far as
  they must to stay clear. The first gap absorbs the delay, and the rest of the day stays
  put. "Move everything after now" shifts it all.
- **Pins never move.** The sheet warns about any pin a move would now miss ("train would
  end 5:05 PM, after 🏁 Reach by 4:55 PM"); the snackbar names the first.
- **Undo** in one tap. In plan mode the moves are sketches.

## How

- `lib/features/day/running_late.dart`:
  - `shiftForLate(entries, now, delay, everything)` is pure. It walks entries ending after
    `now` in start order: entries under way extend by `delay`. For later ones a `carry`
    starts at `delay` and loses each gap (`start - busyUntil`, never negative, so overlaps
    move together). Movement stops when the carry reaches 0, unless `everything` is set.
  - `missedPins(shifts, pins)` reports a pin an entry's end (or start) used to be at or
    before and now passes.
  - `runLate(context, ref, delay?)` reads today's plan and pins, shows the preview sheet
    (or uses `delay` straight away), applies through `BlockRepo.update` (sketch) or
    `updateSaved` the way `DayPage._sketching` decides, and offers Undo.
- **Notification buttons:** the countdown's actions are `late:5` and `late:10`, with
  `showsUserInterface` so the app opens. `ReminderService.action` (a `ValueNotifier`) is
  set from `onDidReceiveNotificationResponse`, or from `getNotificationAppLaunchDetails`
  when the tap launched the app. `DayScreen` listens, jumps to now and calls
  `runLate(delay:)`.

## Why

- Shifting everything by the delay is rarely right: the evening doesn't move because a
  train was missed. Letting gaps absorb the delay matches how a day actually slips, and
  touches the fewest entries. The switch covers the other case.
- Pins are the fixed points the plan is built around, so they stay. Warning, rather than
  silently re-planning, keeps the user deciding.
- The notification buttons open the app (not a background isolate), so the result and its
  Undo are on screen, and edits go through the same repo paths as everything else.
