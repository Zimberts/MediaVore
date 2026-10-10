import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decides whether the automatic cache warm-up may run on repository creation.
///
/// The warm-up is skipped inside the WorkManager isolate (the daily sync does
/// its own targeted refresh) and throttled to once per [minInterval].
/// Explicit user requests (`fillCache`, `clearCache(complete: false)`) bypass
/// this policy.
@lazySingleton
class CacheWarmupPolicy {
  static const String lastRunKey = 'cacheWarmupLastRunMs';
  static const Duration minInterval = Duration(hours: 24);

  /// Set by the background task entry point before DI is initialized.
  /// Isolate-local by construction.
  static bool isBackgroundIsolate = false;

  final SharedPreferences prefs;
  final DateTime Function() _now;

  CacheWarmupPolicy(this.prefs) : _now = DateTime.now;

  @visibleForTesting
  CacheWarmupPolicy.withClock(this.prefs, DateTime Function() now) : _now = now;

  bool shouldRunAutomatically() {
    if (isBackgroundIsolate) return false;
    final lastMs = prefs.getInt(lastRunKey);
    if (lastMs == null) return true;
    final elapsed = _now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastMs),
    );
    // A negative elapsed time means the clock moved back: run again.
    return elapsed.isNegative || elapsed >= minInterval;
  }

  Future<void> markCompleted() =>
      prefs.setInt(lastRunKey, _now().millisecondsSinceEpoch);
}
