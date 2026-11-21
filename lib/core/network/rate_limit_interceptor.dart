import 'dart:collection';

import 'package:dio/dio.dart';

/// Holds requests so that at most [maxRequests] start within any [window].
///
/// TMDB allows about 50 requests per second per IP and answers 429 above;
/// the app stays below with [tmdbMaxRequestsPerSecond]. Requests are released
/// in arrival order. Retries (`RetryInterceptor` re-fetches through the same
/// Dio) count too.
class RateLimitInterceptor extends Interceptor {
  /// Requests per second allowed towards TMDB (20 % under its limit).
  static const int tmdbMaxRequestsPerSecond = 40;

  final int maxRequests;
  final Duration window;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _sleep;

  /// Start times of the last [maxRequests] requests, oldest first.
  final Queue<DateTime> _starts = Queue();

  /// Tail of the FIFO of waiting requests.
  Future<void> _tail = Future.value();

  RateLimitInterceptor({
    this.maxRequests = tmdbMaxRequestsPerSecond,
    this.window = const Duration(seconds: 1),
    DateTime Function()? now,
    Future<void> Function(Duration)? sleep,
  }) : assert(maxRequests > 0),
       _now = now ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await acquire();
    handler.next(options);
  }

  /// Completes when one more request may start, and records it.
  Future<void> acquire() {
    final turn = _tail.then((_) => _waitForSlot());
    _tail = turn;
    return turn;
  }

  Future<void> _waitForSlot() async {
    if (_starts.length >= maxRequests) {
      final wait = _starts.first.add(window).difference(_now());
      if (wait > Duration.zero) await _sleep(wait);
      _starts.removeFirst();
    }
    _starts.addLast(_now());
  }
}
