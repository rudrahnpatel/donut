import 'package:donut/data/repos/pin_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Work 10:00–12:30 on the hour dial (5-minute snap).
  int work(double held) =>
      pinSpotInEntry(start: 600, end: 750, held: held, step: 5);

  test('in the middle of an entry the pin goes where you held', () {
    expect(work(661), 660);
    expect(work(683), 685);
  });

  test('near either end it snaps to that edge', () {
    expect(work(745), 750, reason: '12:25 → Reach by 12:30');
    expect(work(741), 750);
    expect(work(604), 600, reason: '10:04 → Leave by 10:00');
  });

  test('a short entry snaps to whichever edge is nearer', () {
    // home to stn 4:10–4:15.
    expect(pinSpotInEntry(start: 970, end: 975, held: 971, step: 5), 970);
    expect(pinSpotInEntry(start: 970, end: 975, held: 974, step: 5), 975);
  });

  test('the edge zone grows with the entry but stays a few minutes', () {
    // Train 4:15–4:55: edges within 5 min.
    expect(pinSpotInEntry(start: 975, end: 1015, held: 1009, step: 5), 1010);
    expect(pinSpotInEntry(start: 975, end: 1015, held: 1011, step: 5), 1015);
    // Day dial, 15-minute snap: the zone is at least one step.
    expect(pinSpotInEntry(start: 600, end: 750, held: 614, step: 15), 600);
    expect(pinSpotInEntry(start: 600, end: 750, held: 676, step: 15), 675);
  });
}
