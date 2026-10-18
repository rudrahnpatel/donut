# Dev harness and two Impeller rendering pitfalls

## What

A debug-only harness (`lib/dev/dev_harness.dart`) runs the real app against an in-memory demo
database, optionally plays a synthetic gesture (`DONUT_SCENE=menu|tasks|label|drag|select|picker`)
and saves its own screenshot, then exits. With `xvfb-run` it renders fully off-screen, so it
never touches the desktop session or real data.

```sh
xvfb-run -a -s "-screen 0 1100x1000x24" env -u WAYLAND_DISPLAY GDK_BACKEND=x11 \
  DONUT_DEMO=1 DONUT_THEME=dark DONUT_LEVEL=hour DONUT_HOUR=16 DONUT_SCENE=label \
  DONUT_SCREENSHOT=/tmp/shot.png ./build/linux/x64/debug/bundle/donut
```

## How

- The harness finds the dial through the render tree (a `RenderCustomPaint` whose painter is
  a `ClockPainter` and whose centre is on screen) and dispatches `PointerDown/Move/Up` events
  through `GestureBinding.handlePointerEvent`.
- It waits for the dial to appear before playing a scene: the day plan loads asynchronously
  and the first frames on llvmpipe are slow.

## Why / pitfalls found

- **Thick stroked circles touching the layer edge** (the overflow lane track) painted the
  corners of their bounding square under Impeller's OpenGLES SDF backend. Ring tracks are
  drawn as even-odd annulus paths instead.
- **`Path.arcTo` with a sweep of exactly 2π** degenerates (start == end), so a fully covered
  ring vanished (the "past" dimming of a whole ring). Sweeps are clamped just below 2π.
- Synthetic drags must follow the arc; a straight screen line between two clock positions
  can run counter-clockwise, which the dial correctly reads as dragging backwards.
