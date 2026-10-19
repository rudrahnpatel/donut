# App icon: the donut clock

## What

One design everywhere: a thick ring holding the day's plan as coloured arcs (pink, amber,
teal, violet, with a gap of free time on the track), and white hands at 10:10 with a red
pivot in the hole, on deep night (#201A2B).

- **Android:** an adaptive icon, with a monochrome layer for Android 13+ themed icons, and
  PNGs for launchers before Android 8. The notification icon is the white arcs and hands.
- **Linux:** a window icon from the bundle, plus `tool/install_linux_desktop.sh`, which
  adds a launcher entry with the SVG icon (what Wayland compositors such as niri show).
- **Windows:** `app_icon.ico`.
- **In the app:** the About section in Settings.

## How

`tool/make_icons.py` generates everything from a few constants (colours, ring radius and
width, arc angles, hand angles). It writes Android vector drawables for the adaptive
foreground, monochrome and notification icon, the master SVG, PNGs through
`rsvg-convert`, and the `.ico` through ImageMagick. Edit the script and rerun it; never
edit the generated files.

The adaptive foreground keeps everything inside the 66-unit safe circle (ring outer radius
29 of 108). The plain-circle master scales the mark ×1.42 to fill its circle.

## Why

- The app had Flutter's default icon. The mark is the app's own dial at its simplest: a
  ring with planned arcs and a clock in the middle. It reads as both "donut" and "clock",
  and stays legible at 48 px.
- **Vector drawables, not PNGs, on Android 8+:** crisp at every density and one source of
  truth. PNGs only cover older launchers.
- **On Wayland the window icon is ignored;** the compositor matches the app id
  (`dev.rudra.donut`) to a desktop entry. Hence the install script, which only touches
  `~/.local/share`.
