# Notes index

- [dial_spec_day_and_hour.md](dial_spec_day_and_hour.md) — one `DialSpec` drives both the AM/PM day dial and the 60-minute hour dial (fixed clock hours, outer ring previews the next hour, rings slide during drags, inward hour glide, analog clock in the hub)
- [clock_gesture_machine.md](clock_gesture_machine.md) — pure state machine + eager recognizer for draw/resize/move/hold/hub/pinch on the dial
- [marking_menu_and_hour_picker.md](marking_menu_and_hour_picker.md) — hold-an-entry four-way menu (Tasks up, Label down, pins left/right; text opens as lists) and hold-the-hub AM/PM hour picker
- [edit_overlay_drafts.md](edit_overlay_drafts.md) — edits save instantly; opt-in plan mode keeps sketches in an overlay until ✓ saves or ✕ discards them; plan mode turns the app night-violet like an incognito window
- [floating_time_and_storage.md](floating_time_and_storage.md) — wall-clock minute storage, HLC timestamps, materialised recurring blocks
- [dev_harness_and_impeller.md](dev_harness_and_impeller.md) — off-screen demo/screenshot harness and two Impeller rendering bugs worked around
- [overlaps_colours_and_auto_drafts.md](overlaps_colours_and_auto_drafts.md) — every drag draws a new entry with its own colour; overlaps split the ring into side-by-side lanes, each entry one continuous shape; older entries recoloured at startup
- [reminders_per_platform.md](reminders_per_platform.md) — notifications when saved entries start: exact alarms on Android, an in-app 30 s check on Linux
- [android_clock_widget.md](android_clock_widget.md) — day-view and hour-view home-screen widgets: Kotlin-drawn dial bitmap fed by home_widget JSON, live AnalogClock hands on top, self-scheduled refresh
- [google_sync_architecture.md](google_sync_architecture.md) — Google sign-in per platform, per-device Drive files merged by HLC, two-way "Donut" calendar mirror and free/busy ghost arcs
- [pins.md](pins.md) — hold an entry and flick right/left to pin its end/start, or hold an empty spot to pin that moment (Reach by, Meeting at, Leave by, custom); own table, synced, reminds 10 min early
- [onboarding_tour.md](onboarding_tour.md) — first-run tour where the dial is the star: self-drawing showcase, ghost-finger gesture demos on a practice dial, sprinkle bursts, opt-in reminders; replay from Settings
- [app_icon.md](app_icon.md) — the donut-clock icon, generated for Android (adaptive, themed, notification), Linux (desktop entry) and Windows by tool/make_icons.py
- [running_late.md](running_late.md) — "running late": the entry under way runs longer, later ones move until a gap absorbs the delay; pins stay and missed ones are warned about; also from the countdown notification
