import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/time/day_minutes.dart';
import '../../data/repos/block_repo.dart';
import '../radial_menu/hour_picker_controller.dart';
import '../radial_menu/hour_picker_overlay.dart';
import '../radial_menu/marking_menu_controller.dart';
import '../radial_menu/marking_menu_overlay.dart';
import 'clock_geometry.dart';
import 'clock_gesture_machine.dart';
import 'clock_painter.dart';
import 'clock_recognizer.dart';
import 'spiral_math.dart';

/// Hooks for the hold-the-hub hour picker.
class HourPickerHooks {
  const HourPickerHooks({
    required this.base,
    required this.labelFor,
    required this.onPick,
  });

  /// Absolute minute of the first hour on the picker's inner ring.
  final int base;
  final String Function(int absStart) labelFor;
  final void Function(int absStart) onPick;
}

/// The interactive dial: draw blocks by dragging along the rings,
/// press-and-hold a block for the marking menu. Works for both the day dial
/// and the hour dial; [spec] decides which.
class ClockView extends StatefulWidget {
  const ClockView({
    super.key,
    required this.spec,
    required this.captions,
    required this.blocks,
    required this.isToday,
    required this.isPast,
    required this.snapStep,
    required this.use24h,
    required this.center,
    required this.onCreate,
    required this.onChange,
    required this.onSelect,
    required this.menuItems,
    required this.onMenuPick,
    this.onTapEmpty,
    this.onHubTap,
    this.onHubSwipe,
    this.hourPicker,
    this.onZoom,
    this.selectedId,
    this.ghosts = const [],
    this.pins = const [],
    this.menuItemColor,
  });

  final DialSpec spec;

  /// Ring captions for the dial actually shown (it may have slid).
  final (String, String) Function(DialSpec shown) captions;

  /// Blocks in day-relative minutes (may extend outside `[0, 1440)`).
  final List<PaintBlock> blocks;
  final String? selectedId;
  final bool isToday;
  final bool isPast;
  final int snapStep;
  final bool use24h;
  final List<(int, int)> ghosts;

  /// Pins ("Reach by 4:55"), day-relative.
  final List<PaintPin> pins;

  /// Shown in the hub when not dragging.
  final Widget Function(DialSpec shown) center;

  final void Function(int start, int end) onCreate;
  final void Function(String id, int start, int end) onChange;
  final void Function(String? id) onSelect;
  final List<MarkingItem> Function(String blockId) menuItems;
  final void Function(String blockId, MarkingItem item) onMenuPick;
  final Color? Function(MarkingItem item)? menuItemColor;

  /// A tap on an empty part of a ring. Defaults to deselecting.
  final void Function(double u)? onTapEmpty;

  /// Hub gestures; providing any of them makes the hub part of the dial.
  final VoidCallback? onHubTap;
  final void Function(int direction)? onHubSwipe;
  final HourPickerHooks? hourPicker;

  /// Pinch or mouse wheel: [zoomIn] towards minute [focusU] (null when the
  /// gesture was over the hub).
  final void Function(bool zoomIn, double? focusU)? onZoom;

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView>
    with SingleTickerProviderStateMixin {
  late final ClockGestureMachine _machine = ClockGestureMachine(emit: _onEvent);
  final _overlay = OverlayPortalController();

  PreviewEvent? _preview;
  Offset? _pointer;
  Timer? _holdTimer;
  Timer? _nowTimer;
  DateTime _lastWheel = DateTime(0);

  /// Laps the hour dial has slid to follow a drag; reset when [spec] changes.
  int _slide = 0;

  /// Glides entries between rings when the shown hour moves by one.
  late final AnimationController _laps = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  double _lapFrom = 0;

  double get _lapOffset =>
      _lapFrom * (1 - Curves.easeOutCubic.transform(_laps.value));

  /// Starts the inward (or outward) glide if the hour dial moved by exactly
  /// one hour; bigger jumps just switch.
  void _animateLaps(DialSpec from, DialSpec to) {
    if (!to.isHour || from.turn != to.turn) return;
    final laps = (to.origin - from.origin) / to.turn;
    if (laps.abs() != 1) return;
    _lapFrom = laps;
    _laps.forward(from: 0);
  }

  MarkingMenuController? _menu;
  HourPickerController? _picker;
  String? _menuBlockId;
  bool _menuMouse = false;
  Offset _menuPointer = Offset.zero;
  final _menuClock = Stopwatch();
  Timer? _menuTicker;

  DialSpec get _spec =>
      widget.spec.slides ? widget.spec.shifted(_slide) : widget.spec;

  bool get _claimsHub =>
      widget.onHubTap != null ||
      widget.onHubSwipe != null ||
      widget.hourPicker != null;

  @override
  void initState() {
    super.initState();
    _nowTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (widget.isToday && mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(ClockView old) {
    super.didUpdateWidget(old);
    final before = old.spec.slides ? old.spec.shifted(_slide) : old.spec;
    // Only a real change of hour (or zoom level) resets the slide.
    final moved = (old.spec.origin - widget.spec.origin).abs() >= 60;
    if (old.spec.turn != widget.spec.turn || moved) _slide = 0;
    _animateLaps(before, _spec);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _nowTimer?.cancel();
    _menuTicker?.cancel();
    _laps.dispose();
    super.dispose();
  }

  // ── machine events ─────────────────────────────────────────────────────

  void _onEvent(ClockEvent e) {
    switch (e) {
      case PreviewEvent():
        _follow(e);
        setState(() => _preview = e);
      case ClearPreviewEvent():
        setState(() => _preview = null);
      case CreateEvent():
        widget.onCreate(e.start, e.end);
      case ChangeEvent():
        widget.onChange(e.id, e.start, e.end);
      case SelectEvent():
        widget.onSelect(e.id);
      case TapEmptyEvent():
        (widget.onTapEmpty ?? (_) => widget.onSelect(null))(e.u);
      case HubTapEvent():
        widget.onHubTap?.call();
      case HubSwipeEvent():
        HapticFeedback.selectionClick();
        widget.onHubSwipe?.call(e.direction);
      case HubHoldEvent():
        _openPicker(mouse: e.mouseMode);
      case MenuOpenEvent():
        _openMenu(e.id, _toGlobal(e.position), mouse: e.mouseMode);
      case MenuMoveEvent():
        _overlayPointer(_toGlobal(e.position));
      case MenuReleaseEvent():
        _pick(_toGlobal(e.position));
      case MenuCancelEvent():
        _closeOverlay();
      case HapticEvent():
        switch (e.kind) {
          case HapticKind.tick:
            HapticFeedback.selectionClick();
          case HapticKind.limit:
            HapticFeedback.heavyImpact();
          case HapticKind.hold:
            HapticFeedback.mediumImpact();
        }
    }
  }

  /// Slides the hour dial so the edge being dragged stays on the rings.
  void _follow(PreviewEvent e) {
    if (!widget.spec.slides) return;
    final prev = _preview;
    final int lead;
    if (prev == null || (e.end != prev.end && e.start == prev.start)) {
      lead = e.end;
    } else if (e.start != prev.start && e.end == prev.end) {
      lead = e.start;
    } else {
      lead = e.start >= prev.start ? e.end : e.start;
    }
    var slide = _slide;
    var spec = widget.spec.shifted(slide);
    while (lead > spec.end) {
      slide++;
      spec = widget.spec.shifted(slide);
    }
    while (lead < spec.origin) {
      slide--;
      spec = widget.spec.shifted(slide);
    }
    if (slide != _slide) {
      HapticFeedback.mediumImpact();
      final before = _spec;
      _slide = slide;
      _animateLaps(before, _spec);
    }
  }

  /// The dial's own square. Pointer positions are local to it, and it sits
  /// centred inside a larger box, so conversions must go through it.
  final _dialKey = GlobalKey();

  RenderBox get _dialBox =>
      _dialKey.currentContext!.findRenderObject()! as RenderBox;

  Offset _toGlobal(Offset local) => _dialBox.localToGlobal(local);

  // ── overlays (marking menu / hour picker) ──────────────────────────────

  Rect _screenBounds() {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final pad = MediaQuery.paddingOf(context);
    final b = Offset.zero & overlay.size;
    return Rect.fromLTRB(
      b.left + pad.left,
      b.top + pad.top,
      b.right - pad.right,
      b.bottom - pad.bottom,
    );
  }

  void _openMenu(String blockId, Offset global, {required bool mouse}) {
    _menuBlockId = blockId;
    _menuMouse = mouse;
    _menuPointer = global;
    _menu = MarkingMenuController(
      origin: global,
      rootItems: widget.menuItems(blockId),
      bounds: _screenBounds(),
      onHighlight: HapticFeedback.selectionClick,
      // Tasks up, labels down.
      split: true,
    );
    _menuClock
      ..reset()
      ..start();
    // Dwell-to-open needs time to pass even when the finger is still.
    _menuTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final m = _menu;
      if (m == null) return;
      final before = m.levels.length;
      m.tick(_menuPointer, _menuClock.elapsed);
      if (m.levels.length != before) setState(() {});
    });
    widget.onSelect(blockId);
    _overlay.show();
    setState(() {});
  }

  void _openPicker({required bool mouse}) {
    final hooks = widget.hourPicker;
    if (hooks == null) return;
    final box = _dialBox;
    final side = box.size.shortestSide;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final inner = (side * 0.2).clamp(58.0, 80.0);
    _menuMouse = mouse;
    _picker = HourPickerController(
      center: center,
      base: hooks.base,
      innerRadius: inner,
      outerRadius: inner + 48,
      onChange: HapticFeedback.selectionClick,
    );
    _overlay.show();
    setState(() {});
  }

  void _overlayPointer(Offset global) {
    _menuPointer = global;
    _menu?.pointer(global, _menuClock.elapsed);
    _picker?.pointer(global);
    setState(() {});
  }

  void _pick(Offset global) {
    final picker = _picker;
    if (picker != null) {
      picker.pointer(global);
      final abs = picker.picked;
      _closeOverlay();
      if (abs != null) widget.hourPicker?.onPick(abs);
      return;
    }
    final m = _menu, id = _menuBlockId;
    final item = m?.release(global);
    _closeOverlay();
    if (item != null && id != null) widget.onMenuPick(id, item);
  }

  void _closeOverlay() {
    _menuTicker?.cancel();
    _menuTicker = null;
    _menuClock.stop();
    _menu = null;
    _picker = null;
    _menuBlockId = null;
    _overlay.hide();
    if (mounted) setState(() {});
  }

  // ── pointer plumbing ───────────────────────────────────────────────────

  void _onDown(PointerDownEvent e) {
    _pointer = e.localPosition;
    _machine.down(
      e.localPosition,
      mouse: e.kind == PointerDeviceKind.mouse,
      secondary: e.buttons & kSecondaryButton != 0,
    );
    _holdTimer?.cancel();
    if (_machine.wantsHoldTimer) {
      _holdTimer = Timer(
        ClockGestureMachine.holdDuration,
        _machine.holdElapsed,
      );
    }
  }

  void _onMove(PointerMoveEvent e) {
    _pointer = e.localPosition;
    _machine.move(e.localPosition);
    if (!_machine.wantsHoldTimer) _holdTimer?.cancel();
  }

  void _onUp(PointerUpEvent e) {
    _holdTimer?.cancel();
    _machine.up();
    _pointer = null;
  }

  void _onCancel() {
    _holdTimer?.cancel();
    _machine.cancel();
    _pointer = null;
  }

  double? _focusAt(Offset local) {
    final g = _machine.geometry;
    final ring = g?.ringAt(local);
    return ring == null ? null : g!.minuteAt(local, ring);
  }

  void _onPinchEnd(double scale, Offset focal) {
    if (widget.onZoom == null) return;
    if (scale > 1.2) widget.onZoom!(true, _focusAt(focal));
    if (scale < 0.83) widget.onZoom!(false, _focusAt(focal));
  }

  void _onWheel(PointerSignalEvent e) {
    if (e is! PointerScrollEvent || widget.onZoom == null) return;
    final now = DateTime.now();
    if (now.difference(_lastWheel) < const Duration(milliseconds: 350)) return;
    _lastWheel = now;
    widget.onZoom!(e.scrollDelta.dy < 0, _focusAt(e.localPosition));
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spec = _spec;
    _machine
      ..spans = [for (final b in widget.blocks) ClockSpan(b.id, b.start, b.end)]
      ..selectedId = widget.selectedId
      ..snapStep = widget.snapStep
      ..claimHub = _claimsHub;

    final now = DateTime.now();
    final nowU = widget.isToday
        ? now.hour * 60 + now.minute + now.second / 60
        : null;

    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: (_) {
        final picker = _picker, menu = _menu;
        if (picker != null) {
          return Positioned.fill(
            child: HourPickerLayer(
              controller: picker,
              mouseMode: _menuMouse,
              labelFor: widget.hourPicker!.labelFor,
              onPointer: _overlayPointer,
              onPick: _pick,
              onCancel: _closeOverlay,
            ),
          );
        }
        if (menu == null) return const SizedBox.shrink();
        return Positioned.fill(
          child: MarkingMenuLayer(
            controller: menu,
            mouseMode: _menuMouse,
            itemColor: widget.menuItemColor,
            onPointer: _overlayPointer,
            onPick: _pick,
            onCancel: _closeOverlay,
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          final size = Size.square(side);
          final geometry = ClockGeometry(size, spec);
          _machine.geometry = geometry;

          final preview = _preview;
          PaintBlock? previewBlock;
          if (preview != null) {
            final original = widget.blocks
                .where((b) => b.id == preview.id)
                .firstOrNull;
            previewBlock = PaintBlock(
              id: preview.id ?? '_new',
              start: preview.start,
              end: preview.end,
              color: original?.color ?? scheme.primary,
              emoji: original?.emoji,
              status: original?.status ?? BlockStatus.pending,
            );
          }

          return Center(
            child: SizedBox.fromSize(
              key: _dialKey,
              size: size,
              child: Listener(
                onPointerSignal: _onWheel,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    RawGestureDetector(
                      behavior: HitTestBehavior.opaque,
                      gestures: {
                        ClockPointerRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              ClockPointerRecognizer
                            >(
                              () => ClockPointerRecognizer(debugOwner: this),
                              (r) => r
                                ..hitTest = _machine.hitTest
                                ..onDown = _onDown
                                ..onMove = _onMove
                                ..onUp = _onUp
                                ..onCancel = _onCancel
                                ..onPinchStart = _onCancel
                                ..onPinchEnd = _onPinchEnd,
                            ),
                      },
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _laps,
                          builder: (context, _) => CustomPaint(
                            size: size,
                            painter: ClockPainter(
                              spec: spec,
                              captions: widget.captions(spec),
                              blocks: widget.blocks,
                              scheme: scheme,
                              preview: previewBlock,
                              selectedId: widget.selectedId,
                              nowU: nowU,
                              dimAll: widget.isPast,
                              ghosts: widget.ghosts,
                              pins: widget.pins,
                              lapOffset: _lapOffset,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Hub: the day/hour, or the live readout while dragging.
                    Positioned.fromRect(
                      rect: Rect.fromCircle(
                        center: geometry.center,
                        radius: geometry.innerR0 * 0.56,
                      ),
                      child: IgnorePointer(
                        child: FittedBox(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: preview == null
                                ? KeyedSubtree(
                                    key: ValueKey(spec),
                                    child: widget.center(spec),
                                  )
                                : _Readout(
                                    key: const ValueKey('readout'),
                                    start: preview.start,
                                    end: preview.end,
                                    use24h: widget.use24h,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    // A bubble above the finger: on phones the hand hides the
                    // hub when dragging along the top of the dial.
                    if (preview != null && _pointer != null)
                      _FingerBubble(
                        at: _pointer!,
                        text:
                            '${formatClock(preview.start, use24h: widget.use24h)} – '
                            '${formatClock(preview.end, use24h: widget.use24h)}',
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    super.key,
    required this.start,
    required this.end,
    required this.use24h,
  });

  final int start;
  final int end;
  final bool use24h;

  String _fmt(int u) {
    final t = formatClock(u, use24h: use24h);
    if (u >= minutesPerDay) return '$t ⁺¹';
    if (u < 0) return '$t ⁻¹';
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _fmt(start),
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Icon(
          Icons.arrow_downward_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        Text(
          _fmt(end),
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: ShapeDecoration(
            color: scheme.primaryContainer,
            shape: const StadiumBorder(),
          ),
          child: Text(
            formatDuration(end - start),
            style: t.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ),
      ],
    );
  }
}

class _FingerBubble extends StatelessWidget {
  const _FingerBubble({required this.at, required this.text});

  final Offset at;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: at.dx,
      top: at.dy - 64,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: scheme.inverseSurface,
              shape: const StadiumBorder(),
              shadows: const [
                BoxShadow(blurRadius: 8, color: Color(0x33000000)),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onInverseSurface,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
