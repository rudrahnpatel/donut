# Notes index

- [dial_spec_day_and_hour.md](dial_spec_day_and_hour.md) — one `DialSpec` drives both the AM/PM day dial and the 60-minute hour dial (fixed clock hours, outer ring previews the next hour, rings slide during drags)
- [clock_gesture_machine.md](clock_gesture_machine.md) — pure state machine + eager recognizer for draw/resize/move/hold/hub/pinch on the dial
- [marking_menu_and_hour_picker.md](marking_menu_and_hour_picker.md) — hold-an-entry Tasks/Label menu and hold-the-hub AM/PM hour picker (both dials)
- [edit_overlay_drafts.md](edit_overlay_drafts.md) — edits save instantly; opt-in plan mode keeps sketches in an overlay until ✓ saves or ✕ discards them
- [floating_time_and_storage.md](floating_time_and_storage.md) — wall-clock minute storage, HLC timestamps, materialised recurring blocks
- [dev_harness_and_impeller.md](dev_harness_and_impeller.md) — off-screen demo/screenshot harness and two Impeller rendering bugs worked around
- [overlaps_colours_and_auto_drafts.md](overlaps_colours_and_auto_drafts.md) — every drag draws a new entry with its own colour; overlaps split the ring into side-by-side lanes, each entry one continuous shape
