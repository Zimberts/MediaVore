import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/cache/cache_warmup_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  Future<CacheWarmupPolicy> policyAt(
    DateTime now, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    return CacheWarmupPolicy.withClock(
      await SharedPreferences.getInstance(),
      () => now,
    );
  }

  tearDown(() => CacheWarmupPolicy.isBackgroundIsolate = false);

  group('CacheWarmupPolicy', () {
    test('should run when it never ran', () async {
      expect((await policyAt(t0)).shouldRunAutomatically(), isTrue);
    });

    test('should be throttled for 24h after completion', () async {
      final policy = await policyAt(t0);
      await policy.markCompleted();
      final last = {CacheWarmupPolicy.lastRunKey: t0.millisecondsSinceEpoch};

      final before = await policyAt(
        t0.add(const Duration(hours: 23, minutes: 59)),
        prefs: last,
      );
      final after = await policyAt(
        t0.add(const Duration(hours: 24)),
        prefs: last,
      );
      final clockBack = await policyAt(
        t0.subtract(const Duration(minutes: 1)),
        prefs: last,
      );

      expect(before.shouldRunAutomatically(), isFalse);
      expect(after.shouldRunAutomatically(), isTrue);
      expect(clockBack.shouldRunAutomatically(), isTrue);
    });

    test('should never run in the background isolate', () async {
      CacheWarmupPolicy.isBackgroundIsolate = true;
      expect((await policyAt(t0)).shouldRunAutomatically(), isFalse);
    });
  });
}
