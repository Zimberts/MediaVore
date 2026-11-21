import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/network/rate_limit_interceptor.dart';

void main() {
  late DateTime now;
  late List<Duration> sleeps;

  RateLimitInterceptor limiter({int max = 3}) => RateLimitInterceptor(
    maxRequests: max,
    now: () => now,
    sleep: (d) async {
      sleeps.add(d);
      now = now.add(d);
    },
  );

  setUp(() {
    now = DateTime(2026, 1, 1);
    sleeps = [];
  });

  test('should let a burst of maxRequests through without waiting', () async {
    final l = limiter();
    await Future.wait([l.acquire(), l.acquire(), l.acquire()]);
    expect(sleeps, isEmpty);
  });

  test('should hold the next request until the window has passed', () async {
    final l = limiter();
    await Future.wait([l.acquire(), l.acquire(), l.acquire()]);
    now = now.add(const Duration(milliseconds: 300));

    await l.acquire();

    expect(sleeps, [const Duration(milliseconds: 700)]);
  });

  test('should never start more than maxRequests in any window', () async {
    final l = limiter(max: 4);
    final starts = <DateTime>[];
    await Future.wait(
      List.generate(20, (_) => l.acquire().then((_) => starts.add(now))),
    );

    expect(starts, hasLength(20));
    for (var i = 4; i < starts.length; i++) {
      expect(
        starts[i].difference(starts[i - 4]),
        greaterThanOrEqualTo(const Duration(seconds: 1)),
      );
    }
    // 20 requests at 4/s: the last one starts 4 s after the first.
    expect(starts.last.difference(starts.first), const Duration(seconds: 4));
  });

  test('should not wait when requests are already spaced out', () async {
    final l = limiter(max: 2);
    for (var i = 0; i < 5; i++) {
      await l.acquire();
      now = now.add(const Duration(milliseconds: 600));
    }
    expect(sleeps, isEmpty);
  });
}
