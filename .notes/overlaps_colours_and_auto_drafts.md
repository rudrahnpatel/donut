# Overlapping entries, per-entry colours and auto-drafts

## What

Feedback from testing on a phone-sized screen:

- **Every drag draws a new entry.** That holds even when the drag starts on, or runs across,
  an existing entry. Moving and resizing only apply to the *selected* entry, so tap first.
- **New entries aren't auto-selected.** That way the next drag can't grab the previous
  entry's handle by accident.
- **Overlaps are allowed.** Where entries overlap, the ring is split radially between them
  (halves for two, thirds for three); where an entry is alone it uses the full width. Each
  entry is still drawn as **one continuous outline** that steps in to its sub-lane over the
  overlap (`ClockPainter._runPath`), not as separate pieces with gaps.
- **Each entry gets its own colour** from `entryPalette`, chosen to differ from the entries
  it touches or overlaps. Older entries without a stored colour get a stable hash colour.
- **Edits save instantly** outside plan mode; plan mode (pen icon) turns them into sketches
  until ✓ / ✕ (see edit_overlay_drafts.md). Superseded an interim "every edit is a draft"
  version.
- **No "Untitled".** An entry without a label or task is titled by its times.
- **The menu is Tasks | Label.** The emoji section is gone (activity emojis still show).
- **Entries in the agenda can be swiped left to reveal Delete** (`flutter_slidable`).

## How

- `lib/features/clock/overlap_layout.dart`:
  - `splitOverlaps(spans)` cuts at every start and end and gives each slice's blocks
    consecutive sub-lanes in a stable order (earlier start, then longer, then id).
  - `pieceAt(pieces, u, fraction)` hit-tests by minute *and* radial position.
  - The painter and the gesture machine both use it, so a press on the outer half of an
    overlap picks the entry drawn there.
- `clock_gesture_machine.dart`:
  - `_PressedBlock` + move → `_startCreate` unless the block is selected (then `_startMove`).
  - Neighbour clamping is gone; only the visible-lane caps (day dial) and the 24 h cap remain.
- Schema v2 adds a nullable `color` to `blocks` and `block_edits` (`onUpgrade` →
  `addColumn`). `BlockRepo.create(color:)`; every overlay write uses `EditState.draft`.
- `DayPage._colorFor` cycles the palette from the day's entry count, skipping colours
  already used by touching or overlapping entries. Colour precedence:
  entry colour → activity colour → `fallbackEntryColor(id)`.

```mermaid
flowchart LR
  Spans[visible entries] --> Split[splitOverlaps]
  Split --> Paint[ClockPainter<br/>sub-lane per piece]
  Split --> Hit[pieceAt<br/>minute + radial fraction]
  Hit --> Machine[ClockGestureMachine]
```

## Why

- The user wanted drawing to feel like sketching: "click and drag, draft saved, click and drag
  a new entry". The previous model (drag on a block = move it, auto-select new blocks,
  "Unsaved" vs "Draft") put edit gestures where new drawing was expected.
- Same-colour back-to-back entries (all unlabelled, or all the same task) were unreadable.
  So the entry's own colour wins over its activity's.
- Overlaps split radially rather than stacking or blocking, so both entries stay visible
  and tappable. Splitting only the overlapping part keeps the rest of each entry at full width.
