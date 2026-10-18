# Marking menu and hour picker

## What

- **Marking menu** (hold a block): Tasks | Label. Tasks → activities → that activity's open
  to-dos; Label → recently used labels + "New label…". (An Emojis section existed first and
  was removed at the user's request; activity emojis still show on entries.) Release on an item to apply it; release at the origin to cancel; release in a
  sub-fan's centre to pick the item that opened it (e.g. an activity without a to-do).
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
- Labels came from the user's travel example ("home to stn"), which neither an emoji nor a
  reusable activity expresses. Labels are stored in the block's `note`.
- The hour picker answers "how do I jump to 4 PM quickly" with the same gesture vocabulary as
  the menu instead of a separate control; two rings resolve AM/PM ambiguity without a toggle.
