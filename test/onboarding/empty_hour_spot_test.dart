import 'package:donut/features/onboarding/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the zoom hint taps 4:30 PM when it is free', () {
    expect(emptyHourSpot(const []), 16 * 60 + 30);
  });

  test('it steers clear of an entry covering that spot', () {
    // The case from the phone: a practice entry from 2:15 to 5:45 PM.
    final spot = emptyHourSpot(const [(14 * 60 + 15, 17 * 60 + 45)]);
    expect(spot, 10 * 60 + 30);
  });

  test('a spot right next to an entry is skipped too', () {
    final spot = emptyHourSpot(const [(16 * 60 + 35, 17 * 60)]);
    expect(spot, isNot(16 * 60 + 30));
  });
}
