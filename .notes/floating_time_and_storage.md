# Floating local time and storage

## What

Blocks are stored as an absolute minute index in local wall-clock time
(`epochDay * 1440 + minuteOfDay`) plus a duration, not as UTC instants. Recurring blocks are
generated as ordinary rows a rolling 14 days ahead. Records carry a hybrid logical clock (HLC)
for last-writer-wins merging.

## How

- `lib/core/time/day_minutes.dart`: `Day`, `absMinuteOf`, `localDateTimeOf`, formatting.
- `lib/core/time/hlc.dart`: `<15-digit ms>-<5-hex counter>-<node>` strings that sort
  correctly as plain text; `receive()` advances past timestamps from other devices.
- `lib/data/db/schema.dart` (Drift): `blocks`, `block_edits`, `activities`, `todos`,
  `templates`, `series`, `remote_links`, synced `settings`, device-local `local_kv`.
- `lib/data/repos/plan_tools_repo.dart`: series instance id = UUIDv5(series id + day), so
  regenerating on any device never duplicates; occupied slots are skipped.

## Why

- "Gym at 7:00" should stay at 7:00 across DST changes and travel; a spill past midnight is
  just `start + duration > day end`, with no special cases.
- Materialising recurrences keeps Google Calendar sync to single events, avoiding the
  hardest part of 2-way calendar sync (recurring masters and exceptions).
- HLCs tolerate device clock skew where raw `updatedAt` timestamps would not.
