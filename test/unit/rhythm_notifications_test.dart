/// Rhythm-aware notification hours (GE-6): the pure picker that turns an
/// on-device open-hour histogram into warm anchor hours — personal when
/// there's signal, gentle defaults when there isn't, always well-separated.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';

List<int> hist(Map<int, int> peaks) {
  final h = List<int>.filled(24, 0);
  peaks.forEach((hour, count) => h[hour] = count);
  return h;
}

void main() {
  test('too little signal falls back to the gentle defaults', () {
    expect(preferredNotificationHours(hist({8: 2}), 1), const [19]);
    expect(preferredNotificationHours(hist({8: 2}), 2), const [10, 19]);
    expect(preferredNotificationHours(List.filled(24, 0), 1), const [19]);
  });

  test('a wrong-length histogram is handled safely (defaults)', () {
    expect(preferredNotificationHours(const [1, 2, 3], 1), const [19]);
  });

  test('with signal, cap 1 picks the busiest hour', () {
    expect(preferredNotificationHours(hist({7: 5, 21: 3, 13: 1}), 1), const [
      7,
    ]);
  });

  test('cap 2 picks two well-separated peaks, sorted', () {
    final h = hist({8: 6, 20: 5, 9: 1});
    expect(preferredNotificationHours(h, 2), const [8, 20]);
  });

  test('cap 2 avoids bunching: a near second peak is rejected for a far '
      'default anchor', () {
    // Busiest 14:00, next-busiest 15:00 (too close) → pair with a far anchor.
    final h = hist({14: 9, 15: 8});
    final pair = preferredNotificationHours(h, 2);
    expect(pair.length, 2);
    expect(pair.contains(14), isTrue);
    expect((pair[0] - pair[1]).abs() >= 4, isTrue);
  });

  test('cap is clamped to 1..2 (never spammy)', () {
    expect(preferredNotificationHours(hist({7: 5, 20: 5}), 9).length, 2);
    expect(preferredNotificationHours(hist({7: 5}), 0).length, 1);
  });

  test('ties resolve to the earlier hour (stable)', () {
    expect(preferredNotificationHours(hist({6: 4, 18: 4}), 1), const [6]);
  });
}
