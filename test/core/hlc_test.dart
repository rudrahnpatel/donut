import 'package:donut/core/time/hlc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'timestamps from one clock strictly increase, even if wall time stalls',
    () {
      final c = HlcClock('a', wallMillis: () => 1000);
      final a = c.now(), b = c.now(), d = c.now();
      expect(a.compareTo(b), lessThan(0));
      expect(b.compareTo(d), lessThan(0));
    },
  );

  test('receiving a future stamp moves the local clock past it', () {
    final slow = HlcClock('slow', wallMillis: () => 1000);
    final fast = HlcClock('fast', wallMillis: () => 9000);
    final remote = fast.now();
    slow.receive(remote);
    expect(slow.now().compareTo(remote), greaterThan(0));
  });

  test('pack/parse round-trips and sorts lexicographically', () {
    const h = Hlc(1734567890123, 42, 'dev-1');
    expect(Hlc.parse(h.pack()).pack(), h.pack());
    const later = Hlc(1734567890124, 0, 'dev-0');
    expect(h.pack().compareTo(later.pack()), lessThan(0));
  });
}
