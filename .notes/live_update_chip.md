# Live Update chip for the countdown (Android 16+)

## What

On Android 16 (API 36) and later, the "happening now" countdown asks to be a **Live Update**
(a promoted ongoing notification). Where the phone supports it, the status bar shows a pill
with the entry's emoji, drawn as a silhouette, and the time left. The system ticks that time,
the same way it ticks a call timer. Below API 36 nothing changes: the countdown still goes
through flutter_local_notifications.

**Status on the test phone (Moto edge 60 stylus, Android 16, build W1VBS36.62-22-17-10,
2026-11-19):** the notification posts with `android.requestPromotedOngoing=true`, but the
system doesn't promote it: no `PROMOTED_ONGOING` flag and no chip.
- Only `api_rich_ongoing` is on. The system UI side (`ui_rich_ongoing`) isn't.
- `Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS` doesn't resolve (no per-app
  "Live updates" switch).

So Moto's build doesn't ship the chip yet. The code is ready for when it does, or for other
phones running Android 16 QPR1+.

## How

- `android/.../LiveCountdown.kt`:
  - `show(json)` builds the notification with the platform `Notification.Builder`: ongoing,
    a countdown chronometer to `until`, `timeoutAfter`, the +5/+10 min late actions, and the
    `android.requestPromotedOngoing` extra. `Builder.setRequestPromotedOngoing` is API 36.1
    and doesn't compile against SDK 36, so it sets the extra directly.
  - The small icon is the activity's emoji rendered to a bitmap. The status bar keeps only
    its alpha.
  - `schedule(jsonArray)` sets an exact alarm per future countdown and saves the list in prefs.
  - `LiveCountdownReceiver` fires those alarms, and on boot or app update re-arms them (it
    shows the ones already under way).
- `MainActivity`: the `donut/live` channel (`supported`, `canPromote`, `show`, `schedule`,
  `takeAction`, `openPromotionSettings`).
  - Action buttons open the activity with a `donut_action` extra. It is passed to Dart
    through `takeAction` (cold start) or an `action` call (`onNewIntent`), which feeds
    `ReminderService.action` as the plugin's buttons did.
- `ReminderService.apply`: when `_native`, running countdowns and pending live reminders go
  to `donut/live`; heads-ups and pins stay on the plugin. `Reminder.emoji` carries the
  activity emoji.
- Manifest: `POST_PROMOTED_NOTIFICATIONS`, plus the receiver.

## Why

- The plugin can't set the promotion request (noted earlier in reminders_per_platform.md).
  Native code is needed for the start-time alarm too, because the notification must be built
  natively at the moment it fires.
- The chronometer rather than `setShortCriticalText`: the system keeps it ticking with the
  app closed. Text would need a re-post every minute.
- Not done: faking a CallStyle notification to borrow the call chip. It would show a phone
  icon, count up, and make the system treat the entry as a phone call.
