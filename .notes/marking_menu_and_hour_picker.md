# Marking menu and hour picker

## What

- **Marking menu** (hold a block): Tasks | Label. Tasks → activities → that activity's open
  to-dos; Label → recently used labels + "New label…". (An Emojis section existed first and
  was removed at the user's request; activity emojis still show on entries.) Release on an item to apply it; release at the origin to cancel; release in a
  sub-fan's centre to pick the item that opened it (e.g. an activity without a to-do).
  The first level is **split** four ways (faint lines mark the quarters): Tasks up, Label
  down, and pins to the right (the entry's end) and left (its start); see `pins.md`.
  Tasks' fan opens upward. Labels, to-dos and pin types open as a **list**.
- **Lists.** Text items open as a column of equal-width rows instead of a fan. The rows
  hang below the item (Label, or a pin item without room beside it), stack upward from an
  upward item, or sit beside a sideways item. Rows are picked by the row level with the
  finger once it is 20 dp from the item; the first row is nearest, so a straight flick
  picks it. A card sits behind the rows so they read over the agenda.
- **Hour picker** (hold the hub, on the day dial or the hour dial): two rings of hour
  numerals for the day being shown — inner ring AM, outer ring PM, like the day dial. Slide to
  an hour and release to jump there. (A first version rolled from "now" into tomorrow; the
  user asked for it to stay within the current day.)

## How

- `marking_menu_controller.dart` is pure: levels of items laid out on fans, selected by
  angle sector (not hit box) beyond 40 dp; a sub-fan opens when the pointer reaches the item
  or rests on it for 200 ms, centred on that item so the same flick direction keeps working;
  moving back towards the parent collapses it. Items flagged `isText` (to-dos, labels) are
  wide pills, so their fan grows its radius and spacing from an estimated pill width.
- `_listLayout` builds list levels (`MarkingLevel.rows`, `rowWidth`). It is used when any
  child `isText` or the parent item has `asList`. It clamps the column into the screen by
  its real width; `_nearestRow` picks by y. List rows don't open further levels.
- `MarkingMenuController(split: true)` lays the root items around the full circle starting
  straight up (`_splitLayout`) instead of fanning them towards the roomiest direction
  (`_pickBaseAngle`). Picking is still `_nearest` by angle; with two items 180° apart, the
  nearest is simply whichever half the finger is in. Sub-fans keep opening in their item's
  direction, so both halves extend away from each other.
- Quick-slot ranking (`quickRankingProvider`) recomputes at most once per day so slot
  positions don't move under the user's muscle memory.
- `hour_picker_controller.dart` is pure: angle → clock position, distance → ring, and
  `startFor(ring, position)` → absolute start minute. `DialMode.forHour` turns the hour that
  contains "now" into the live hour.
- Both overlays render through one `OverlayPortal` in `ClockView`; touch mode keeps the
  pointer on the dial and forwards moves, mouse mode (right-click) lets the overlay take hover,
  click and Esc.

## Why

- Hold-drag-release marking menus are learned as gestures; after a while selection happens
  without looking, which suits frequent labelling.
- The split root came from the user ("upper half task, bottom half labels"). Side by side,
  the two root items sat ~85° apart and both pointed the same way, so a flick had to be
  aimed. Halves make the first choice a plain up/down flick that is hard to miss. Near
  the bottom of the screen the label fan slides up to stay visible, which is cramped but
  still usable; on a phone the dial sits in the upper part of the screen, leaving room
  below.
- Lists replaced text fans after the user saw labels fanned out from a low press on the
  phone: wide pills forced a ~250 dp radius, spilled off both edges and over the agenda,
  and the on-screen clamp only checked pill centres ("i knew it would become cluttered").
  A list is compact, reads top-down, and is clamped by its real width.
- Labels came from the user's travel example ("home to stn"), which neither an emoji nor a
  reusable activity expresses. Labels are stored in the block's `note`.
- The hour picker answers "how do I jump to 4 PM quickly" with the same gesture vocabulary as
  the menu instead of a separate control; two rings resolve AM/PM ambiguity without a toggle.
