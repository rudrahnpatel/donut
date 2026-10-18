import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Claims a pointer the moment it lands on the dial's rings (or hub).
///
/// A raw `Listener` would not take part in the gesture arena, so an
/// enclosing `PageView` would swipe days while you draw a block. This
/// recognizer accepts eagerly for presses its [hitTest] claims and simply
/// declines everything else, leaving those to the parent. A second finger
/// while one is down turns the gesture into a pinch.
class ClockPointerRecognizer extends OneSequenceGestureRecognizer {
  ClockPointerRecognizer({super.debugOwner})
    : super(
        allowedButtonsFilter: (b) =>
            b == kPrimaryButton || b == kSecondaryButton,
      );

  bool Function(Offset local)? hitTest;
  void Function(PointerDownEvent e)? onDown;
  void Function(PointerMoveEvent e)? onMove;
  void Function(PointerUpEvent e)? onUp;
  VoidCallback? onCancel;

  VoidCallback? onPinchStart;

  /// Called when a pinch ends with the final scale (current / starting
  /// finger distance) and the midpoint between the fingers.
  void Function(double scale, Offset focal)? onPinchEnd;

  int? _active;
  int? _second;
  final _positions = <int, Offset>{};
  double _startDistance = 1;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!super.isPointerAllowed(event)) return false;
    if (_active == null) return hitTest?.call(event.localPosition) ?? false;
    return _second == null && event.kind == PointerDeviceKind.touch;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _positions[event.pointer] = event.localPosition;
    resolve(GestureDisposition.accepted);
    if (_active == null) {
      _active = event.pointer;
      onDown?.call(event);
    } else {
      _second = event.pointer;
      _startDistance = (_positions[_active!]! - event.localPosition).distance
          .clamp(1, double.infinity);
      onPinchStart?.call();
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _active && event.pointer != _second) return;
    if (event is PointerMoveEvent) {
      _positions[event.pointer] = event.localPosition;
      if (_second == null) onMove?.call(event);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_second != null) {
        final a = _positions[_active!]!, b = _positions[_second!]!;
        onPinchEnd?.call(
          (a - b).distance / _startDistance,
          Offset.lerp(a, b, 0.5)!,
        );
        _finishAll();
      } else {
        _active = null;
        if (event is PointerUpEvent) {
          onUp?.call(event);
        } else {
          onCancel?.call();
        }
        _positions.remove(event.pointer);
        stopTrackingPointer(event.pointer);
      }
    }
  }

  void _finishAll() {
    for (final p in [_active, _second]) {
      if (p != null) stopTrackingPointer(p);
    }
    _active = null;
    _second = null;
    _positions.clear();
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _active) {
      _active = null;
      onCancel?.call();
    }
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'clock';
}
