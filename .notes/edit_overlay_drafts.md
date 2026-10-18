# Draft / Save / X on an edit overlay

## What

**Normal editing saves instantly** (`BlockRepo.createSaved` / `updateSaved` / `deleteSaved`,
with an Undo snackbar for deletes). **Plan mode** is for quick "what if" thinking: while it
is on, each edit writes the block's full proposed state to `block_edits` as a **sketch**
(dashed, never synced, no reminders), and the UI shows saved blocks with the overlay
applied. ✓ in the plan banner commits every sketch (`saveAll`), ✕ throws them all away
(`discardAll`, with Undo).

History: the first version had a per-day Draft / Save / X bar, then every edit became a
draft with Save / X; the user found confirming every edit annoying, so edits now save
instantly and the sketch layer is opt-in.

## How

- `lib/data/repos/block_repo.dart`: `create` / `update` / `delete` upsert one overlay row per
  block (`baseHlc` remembers the saved row's HLC when editing began; null for new blocks).
  `loadDay` merges saved rows and overlay rows into `PlanBlock`s with a status
  (`saved` / `pending` / `draft` / `conflict`).
- Plan mode is `planningProvider` (`lib/features/day/plan_mode.dart`): the user's toggle OR
  any sketch existing. So sketches left by a killed app, or added by a template / "copy
  yesterday", keep the banner up until ✓ or ✕; nothing is silently lost or silently saved.
- A row "touches" a day if its proposed interval or its saved interval overlaps the day
  (`save(day)` / `discard(day)` remain for per-day use).
- Save writes a fresh HLC per block and marks a hand-edited series instance `detached` so the
  recurrence generator leaves it alone.
- `conflict` = the saved row's HLC moved on (sync) after the edit began; Save currently keeps
  the local edit. A keep-mine / keep-theirs prompt belongs with Calendar sync.

## Why

- Writing on every edit means nothing is lost if the app is killed mid-plan; "unsaved" and
  "draft" differ only by a flag.
- A per-day JSON snapshot was the first idea; it breaks for blocks spanning two days with
  edits on both, and makes sync conflicts coarse. Per-block rows avoid both.
- Templates and "copy yesterday" apply through the same overlay, so they arrive as unsaved
  changes the user can review.
