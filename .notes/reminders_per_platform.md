# Reminders per platform

## What

A notification when a saved entry starts, optionally a few minutes early (Settings →
Reminders, lead time). Sketches in plan mode never remind. Android schedules them with the
system so they fire while the app is closed. Linux (and later Windows) fires them from
inside the running app.

## How

- `lib/features/reminders/reminder_service.dart`:
  - `planReminders(saved, activities, nowMin, leadMin, use24h, horizonMin = 2880)` is a pure
    function. It turns saved entries starting within the next 48 h into `Reminder`s with
    stable 31-bit ids (FNV hash of the entry id). It is unit-tested in
    `test/reminders/plan_reminders_test.dart`.
  - `ReminderService.apply(reminders)` replaces the whole schedule:
    - **Android:** `cancelAll` + `zonedSchedule(exactAllowWhileIdle)` per reminder.
      `timezone` + `flutter_timezone` provide the local zone.
    - **Desktop:** keeps the list and checks it every 30 s. `_fireDue` shows anything
      whose time fell between the previous check and now, comparing wall-clock minutes,
      so a laptop waking from suspend still fires what it missed during the last interval.
- `lib/features/reminders/reminder_providers.dart`:
  - `remindersPlanProvider` recomputes from saved entries (today + tomorrow), activities
    and settings.
  - `startReminders` (called from the app shell) re-applies the schedule only when the
    list actually changes, not every minute.
- Android setup:
  - Permissions: `POST_NOTIFICATIONS` (asked for when you turn reminders on),
    `USE_EXACT_ALARM` (allowed for a sideloaded calendar-like app, no user prompt) and
    `RECEIVE_BOOT_COMPLETED`, plus the plugin's boot and schedule receivers, so alarms come
    back after a reboot.
  - Core library desugaring is enabled in `build.gradle.kts`.
  - The status-bar icon is `ic_stat_donut`.

```mermaid
flowchart LR
  DB[(saved blocks<br/>today+tomorrow)] --> Plan[remindersPlanProvider<br/>planReminders]
  Settings --> Plan
  Plan -->|changed| Apply[ReminderService.apply]
  Apply -->|Android| Alarm[zonedSchedule<br/>exact alarms]
  Apply -->|Linux/Windows| Tick[30 s ticker<br/>_fireDue]
```

## Why

- Re-planning the whole 48 h window on every change avoids tracking individual alarms:
  `cancelAll` + reschedule is cheap for a day's worth of entries, and stable ids mean a
  notification already showing is replaced rather than duplicated.
- The 48 h horizon fits Android's alarm limits. If the app isn't opened for two days,
  reminders run out. This is acceptable for a planner you open daily; the widget update
  doesn't re-arm them.
- Linux has no system scheduler that `flutter_local_notifications` can use, so the app does
  it. The original plan had close-to-tray (`tray_manager`) to keep it running; that is not
  built yet, so Linux reminders fire only while the window is open.
- Google Calendar's own reminders are switched off on mirrored events
  (`useDefault: false`) so you aren't notified twice.

**Not yet verified on a device:** both platforms build and the planner is unit-tested, but
no notification has been seen firing on the phone yet.
