import 'dart:ui';

import 'clock_geometry.dart';
import 'overlap_layout.dart';
import 'spiral_math.dart';

export 'overlap_layout.dart' show ClockSpan;

enum BlockEdge { start, end }

enum HapticKind { tick, limit, hold }

/// Everything the gesture machine tells the outside world.
sealed class ClockEvent {
  const ClockEvent();
}

/// Live shape of the block being created/resized/moved; [id] is null while
/// creating. Sent whenever the snapped value changes.
class PreviewEvent extends ClockEvent {
  const PreviewEvent(this.id, this.start, this.end);
  final String? id;
  final int start;
  final int end;
}

class ClearPreviewEvent extends ClockEvent {
  const ClearPreviewEvent();
}

class CreateEvent extends ClockEvent {
  const CreateEvent(this.start, this.end);
  final int start;
  final int end;
}

class ChangeEvent extends ClockEvent {
  const ChangeEvent(this.id, this.start, this.end);
  final String id;
  final int start;
  final int end;
}

class SelectEvent extends ClockEvent {
  const SelectEvent(this.id);
  final String id;
}

/// A quick tap on an empty part of a ring, at minute [u].
class TapEmptyEvent extends ClockEvent {
  const TapEmptyEvent(this.u);
  final double u;
}

/// Opens the marking menu for block [id] at [position]. With [mouseMode]
/// the menu stays open after release and is driven by hover and click.
class MenuOpenEvent extends ClockEvent {
  const MenuOpenEvent(this.id, this.position, {this.mouseMode = false});
  final String id;
  final Offset position;
  final bool mouseMode;
}

/// Opens the hour picker from the hub.
class HubHoldEvent extends ClockEvent {
  const HubHoldEvent(this.position, {this.mouseMode = false});
  final Offset position;
  final bool mouseMode;
}

class HubTapEvent extends ClockEvent {
  const HubTapEvent();
}

/// A horizontal flick across the hub: +1 = forward, -1 = back.
class HubSwipeEvent extends ClockEvent {
  const HubSwipeEvent(this.direction);
  final int direction;
}

/// Pointer moves and release while a menu or picker is open.
class MenuMoveEvent extends ClockEvent {
  const MenuMoveEvent(this.position);
  final Offset position;
}

class MenuReleaseEvent extends ClockEvent {
  const MenuReleaseEvent(this.position);
  final Offset position;
}

class MenuCancelEvent extends ClockEvent {
  const MenuCancelEvent();
}

class HapticEvent extends ClockEvent {
  const HapticEvent(this.kind);
  final HapticKind kind;
}

/// Pure state machine for one pointer on the dial.
///
/// ```text
/// idle ─down─▶ pressedEmpty ─move>slop─▶ creating ─up─▶ CreateEvent
///          │                └─up──────▶ TapEmptyEvent
///          ├─▶ pressedBlock ─move>slop─▶ creating (or moving, if selected)
///          │                ├─hold────▶ menu ─up─▶ MenuReleaseEvent
///          │                └─up──────▶ SelectEvent
///          ├─▶ pressedHandle ─move>slop─▶ resizing ─up─▶ ChangeEvent
///          └─▶ pressedHub ─hold─▶ menu (hour picker)
///                         ├─move>slop─▶ hubSwipe ─up─▶ HubSwipeEvent
///                         └─up──────▶ HubTapEvent
/// ```
///
/// Every drag draws a new entry, even across existing ones (overlaps are
/// allowed and drawn side by side). Only the selected entry can be moved
/// (drag its body) or resized (drag a handle).
///
/// It owns no timers: the host calls [holdElapsed] when its hold timer fires.
class ClockGestureMachine {
  ClockGestureMachine({required this.emit});

  final void Function(ClockEvent) emit;

  // Inputs refreshed by the host before each gesture.
  ClockGeometry? geometry;
  String? selectedId;
  int snapStep = 15;

  /// Whether presses on the hub belong to the dial.
  bool claimHub = true;

  List<ClockSpan> _spans = const [];
  List<LanePiece> _pieces = const [];

  List<ClockSpan> get spans => _spans;
  set spans(List<ClockSpan> value) {
    _spans = value;
    _pieces = splitOverlaps(value);
  }

  static const double touchSlop = 18;
  static const double mouseSlop = 4;
  static const double handleHitRadius = 24;
  static const double swipeDistance = 48;
  static const Duration holdDuration = Duration(milliseconds: 300);

  _State _state = const _Idle();
  Offset _downPos = Offset.zero;
  Offset _lastPos = Offset.zero;
  double _slop = touchSlop;

  bool get isIdle => _state is _Idle;
  bool get isInMenu => _state is _Menu;
  bool get isDragging => _state is _Dragging;
  bool get wantsHoldTimer => _state is _PressedBlock || _state is _PressedHub;

  /// Whether a press at [p] belongs to the dial. Presses elsewhere are left
  /// for other gestures (e.g. swiping between days).
  bool hitTest(Offset p) {
    final g = geometry;
    if (g == null) return false;
    if (_handleAt(p) != null || g.ringAt(p) != null) return true;
    return claimHub && g.isInHub(p);
  }

  void down(Offset p, {bool mouse = false, bool secondary = false}) {
    final g = geometry;
    if (g == null) return;
    _downPos = p;
    _lastPos = p;
    _slop = mouse ? mouseSlop : touchSlop;

    if (claimHub && g.isInHub(p)) {
      if (secondary) {
        emit(HubHoldEvent(p, mouseMode: true));
        _state = const _Idle();
      } else {
        _state = const _PressedHub();
      }
      return;
    }
    if (!secondary) {
      final handle = _handleAt(p);
      if (handle != null) {
        _state = _PressedHandle(handle.$1, handle.$2);
        return;
      }
    }
    final ring = g.ringAt(p);
    if (ring == null) {
      _state = const _Idle();
      return;
    }
    final u = g.minuteAt(p, ring);
    final (r0, r1) = g.laneBounds(ring);
    final fraction = (g.distanceFromCenter(p) - r0) / (r1 - r0);
    final span = _spanAt(u, fraction);
    if (secondary) {
      if (span != null) emit(MenuOpenEvent(span.id, p, mouseMode: true));
      _state = const _Idle();
      return;
    }
    _state = span != null
        ? _PressedBlock(span, u, g.angleOf(p))
        : _PressedEmpty(u, g.angleOf(p));
  }

  void move(Offset p) {
    final g = geometry;
    if (g == null) return;
    _lastPos = p;
    final s = _state;
    switch (s) {
      case _Idle() || _HubSwipe():
        return;
      case _Menu():
        emit(MenuMoveEvent(p));
        return;
      case _PressedHub():
        if (_pastSlop(p)) _state = const _HubSwipe();
        return;
      case _PressedEmpty():
        if (!_pastSlop(p)) return;
        _state = _startCreate(s.u, s.theta);
      case _PressedHandle():
        if (!_pastSlop(p)) return;
        _state = _startResize(s, g.angleOf(_downPos));
      case _PressedBlock():
        if (!_pastSlop(p)) return;
        _state = s.span.id == selectedId
            ? _startMove(s)
            : _startCreate(s.u, s.theta);
      case _Dragging():
        break;
    }
    final d = _state as _Dragging;
    if (!g.isNearCenter(p)) d.tracker.update(g.angleOf(p));
    _updateDrag(d);
  }

  void up() {
    final s = _state;
    _state = const _Idle();
    switch (s) {
      case _Idle() || _PressedHandle():
        return;
      case _PressedHub():
        emit(const HubTapEvent());
      case _HubSwipe():
        final d = _lastPos - _downPos;
        if (d.dx.abs() > swipeDistance && d.dx.abs() > d.dy.abs() * 1.5) {
          emit(HubSwipeEvent(d.dx < 0 ? 1 : -1));
        }
      case _PressedEmpty():
        emit(TapEmptyEvent(s.u));
      case _PressedBlock():
        emit(SelectEvent(s.span.id));
      case _Menu():
        emit(MenuReleaseEvent(_lastPos));
      case _Creating():
        emit(const ClearPreviewEvent());
        if (s.value != s.anchor) {
          emit(
            CreateEvent(
              s.anchor < s.value ? s.anchor : s.value,
              s.anchor < s.value ? s.value : s.anchor,
            ),
          );
        }
      case _Resizing():
        emit(const ClearPreviewEvent());
        final (start, end) = s.result;
        if (start != s.span.start || end != s.span.end) {
          emit(ChangeEvent(s.span.id, start, end));
        }
      case _Moving():
        emit(const ClearPreviewEvent());
        if (s.value != s.span.start) {
          emit(ChangeEvent(s.span.id, s.value, s.value + s.duration));
        }
    }
  }

  void cancel() {
    final s = _state;
    _state = const _Idle();
    if (s is _Menu) emit(const MenuCancelEvent());
    if (s is _Dragging) emit(const ClearPreviewEvent());
  }

  /// Called by the host's hold timer. Opens the block menu, or the hour
  /// picker on the hub, if the finger is still resting.
  void holdElapsed() {
    final s = _state;
    if (s is _PressedBlock) {
      _state = const _Menu();
      emit(const HapticEvent(HapticKind.hold));
      emit(MenuOpenEvent(s.span.id, _downPos));
    } else if (s is _PressedHub) {
      _state = const _Menu();
      emit(const HapticEvent(HapticKind.hold));
      emit(HubHoldEvent(_downPos));
    }
  }

  // ── internals ──────────────────────────────────────────────────────────

  bool _pastSlop(Offset p) => (p - _downPos).distance > _slop;

  /// The block under minute [u] at [fraction] of the ring's width; where
  /// blocks overlap, the sub-lane decides.
  ClockSpan? _spanAt(double u, double fraction) {
    final piece = pieceAt(_pieces, u, fraction);
    return piece == null ? null : _byId(piece.id);
  }

  ClockSpan? _byId(String? id) {
    if (id == null) return null;
    for (final s in _spans) {
      if (s.id == id) return s;
    }
    return null;
  }

  (ClockSpan, BlockEdge)? _handleAt(Offset p) {
    final g = geometry;
    final sel = _byId(selectedId);
    if (g == null || sel == null) return null;
    final ds = (g.pointForMinute(sel.start.toDouble()) - p).distance;
    final de = (g.pointForEnd(sel.end.toDouble()) - p).distance;
    if (ds > handleHitRadius && de > handleHitRadius) return null;
    return (sel, de <= ds ? BlockEdge.end : BlockEdge.start);
  }

  /// Limits a drag to what the dial can show. A sliding (hour) dial moves
  /// with the drag, so only the 24-hour block cap applies there.
  (int, int) _visibleCaps(int lo, int hi) {
    final spec = geometry!.spec;
    if (spec.slides) return (lo, hi);
    return (
      lo < spec.minVisible ? spec.minVisible : lo,
      hi > spec.maxVisible ? spec.maxVisible : hi,
    );
  }

  _Creating _startCreate(double u, double theta) {
    final anchor = snapMinutes(u, snapStep);
    final (lo, hi) = _visibleCaps(anchor - 1440, anchor + 1440);
    return _Creating(
      SpiralTracker(startU: u, theta: theta, turn: geometry!.spec.turn),
      anchor: anchor,
      lo: lo,
      hi: hi,
    );
  }

  _Resizing _startResize(_PressedHandle s, double theta) {
    final span = s.span;
    final moving = s.edge == BlockEdge.end ? span.end : span.start;
    final (lo, hi) = s.edge == BlockEdge.end
        ? _visibleCaps(span.start + snapStep, span.start + 1440)
        : _visibleCaps(span.end - 1440, span.end - snapStep);
    return _Resizing(
      SpiralTracker(
        startU: moving.toDouble(),
        theta: theta,
        turn: geometry!.spec.turn,
      ),
      span: span,
      edge: s.edge,
      lo: lo,
      hi: hi,
    );
  }

  _Moving _startMove(_PressedBlock s) {
    final span = s.span;
    final dur = span.end - span.start;
    var (lo, hi) = _visibleCaps(span.start - 1440, span.end + 1440);
    hi -= dur;
    return _Moving(
      SpiralTracker(startU: s.u, theta: s.theta, turn: geometry!.spec.turn),
      span: span,
      grabU: s.u,
      lo: lo,
      hi: hi,
    );
  }

  void _updateDrag(_Dragging d) {
    final int next;
    final bool clamped;
    switch (d) {
      case _Creating() || _Resizing():
        final raw = d.tracker.u;
        clamped = raw < d.lo || raw > d.hi;
        next = _clampInt(
          snapMinutes(_clamp(raw, d.lo, d.hi), snapStep),
          d.lo,
          d.hi,
        );
      case _Moving():
        final raw = d.span.start + (d.tracker.u - d.grabU);
        clamped = raw < d.lo || raw > d.hi;
        final offset = snapMinutes(d.tracker.u - d.grabU, snapStep);
        next = _clampInt(d.span.start + offset, d.lo, d.hi);
    }
    if (clamped && !d.wasClamped) emit(const HapticEvent(HapticKind.limit));
    d.wasClamped = clamped;
    if (next == d.value) return;
    d.value = next;
    if (!clamped) emit(const HapticEvent(HapticKind.tick));
    switch (d) {
      case _Creating():
        final a = d.anchor, v = d.value;
        emit(PreviewEvent(null, a < v ? a : v, a < v ? v : a));
      case _Resizing():
        final (s, e) = d.result;
        emit(PreviewEvent(d.span.id, s, e));
      case _Moving():
        emit(PreviewEvent(d.span.id, d.value, d.value + d.duration));
    }
  }

  static double _clamp(double v, int lo, int hi) =>
      v < lo ? lo.toDouble() : (v > hi ? hi.toDouble() : v);

  static int _clampInt(int v, int lo, int hi) =>
      v < lo ? lo : (v > hi ? hi : v);
}

// ── states ───────────────────────────────────────────────────────────────

sealed class _State {
  const _State();
}

class _Idle extends _State {
  const _Idle();
}

class _PressedHub extends _State {
  const _PressedHub();
}

class _HubSwipe extends _State {
  const _HubSwipe();
}

class _PressedEmpty extends _State {
  const _PressedEmpty(this.u, this.theta);
  final double u;
  final double theta;
}

class _PressedHandle extends _State {
  const _PressedHandle(this.span, this.edge);
  final ClockSpan span;
  final BlockEdge edge;
}

class _PressedBlock extends _State {
  const _PressedBlock(this.span, this.u, this.theta);
  final ClockSpan span;
  final double u;
  final double theta;
}

class _Menu extends _State {
  const _Menu();
}

sealed class _Dragging extends _State {
  _Dragging(
    this.tracker, {
    required this.lo,
    required this.hi,
    required this.value,
  });
  final SpiralTracker tracker;
  final int lo;
  final int hi;
  int value;
  bool wasClamped = false;
}

class _Creating extends _Dragging {
  _Creating(
    super.tracker, {
    required this.anchor,
    required super.lo,
    required super.hi,
  }) : super(value: anchor);
  final int anchor;
}

class _Resizing extends _Dragging {
  _Resizing(
    super.tracker, {
    required this.span,
    required this.edge,
    required super.lo,
    required super.hi,
  }) : super(value: edge == BlockEdge.end ? span.end : span.start);
  final ClockSpan span;
  final BlockEdge edge;

  (int, int) get result =>
      edge == BlockEdge.end ? (span.start, value) : (value, span.end);
}

class _Moving extends _Dragging {
  _Moving(
    super.tracker, {
    required this.span,
    required this.grabU,
    required super.lo,
    required super.hi,
  }) : super(value: span.start);
  final ClockSpan span;
  final double grabU;
  int get duration => span.end - span.start;
}
