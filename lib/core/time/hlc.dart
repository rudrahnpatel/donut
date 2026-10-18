/// Hybrid logical clock timestamps for last-writer-wins merging.
///
/// Packed as `<15-digit millis>-<5-hex counter>-<node>` so plain string
/// comparison orders them, with the node id breaking exact ties. Wall clocks
/// on different devices disagree; the counter keeps causality intact when a
/// device receives a timestamp from "the future".
library;

import 'dart:math' as math;

class Hlc implements Comparable<Hlc> {
  const Hlc(this.millis, this.counter, this.node);

  factory Hlc.parse(String s) {
    final a = s.indexOf('-');
    final b = s.indexOf('-', a + 1);
    return Hlc(
      int.parse(s.substring(0, a)),
      int.parse(s.substring(a + 1, b), radix: 16),
      s.substring(b + 1),
    );
  }

  final int millis;
  final int counter;
  final String node;

  String pack() =>
      '${millis.toString().padLeft(15, '0')}-${counter.toRadixString(16).padLeft(5, '0')}-$node';

  @override
  int compareTo(Hlc other) => pack().compareTo(other.pack());

  @override
  String toString() => pack();
}

class HlcClock {
  HlcClock(this.node, {int Function()? wallMillis})
    : _wall = wallMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  final String node;
  final int Function() _wall;
  int _millis = 0;
  int _counter = 0;

  /// A fresh timestamp for a local event.
  String now() {
    final t = _wall();
    if (t > _millis) {
      _millis = t;
      _counter = 0;
    } else {
      _counter++;
    }
    return Hlc(_millis, _counter, node).pack();
  }

  /// Advances past a timestamp seen from another device.
  void receive(String packed) {
    final r = Hlc.parse(packed);
    final t = _wall();
    final m = math.max(math.max(_millis, r.millis), t);
    if (m == _millis && m == r.millis) {
      _counter = math.max(_counter, r.counter) + 1;
    } else if (m == _millis) {
      _counter++;
    } else if (m == r.millis) {
      _counter = r.counter + 1;
    } else {
      _counter = 0;
    }
    _millis = m;
  }
}
