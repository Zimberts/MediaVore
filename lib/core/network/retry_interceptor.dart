import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Retries idempotent requests on transient failures with exponential backoff.
///
/// Retried: HTTP 429 (TMDB rate limit), 502/503/504, connection errors and
/// connect/receive timeouts. A `Retry-After` header (seconds) takes precedence
/// over the computed backoff. Delays are capped at [maxDelay].
class RetryInterceptor extends Interceptor {
  static const String attemptKey = 'retry_attempt';
  static const Set<int> retryableStatusCodes = {429, 502, 503, 504};
  static const Set<String> _idempotentMethods = {'GET', 'HEAD'};

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final Future<void> Function(Duration) _sleep;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    Future<void> Function(Duration)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[attemptKey] as int?) ?? 0;

    if (attempt >= maxRetries || !shouldRetry(err)) {
      return handler.next(err);
    }

    final delay = retryDelay(err, attempt);
    debugPrint(
      '[Retry] ${options.method} ${options.uri.path} '
      '(${err.response?.statusCode ?? err.type.name}) '
      'attempt ${attempt + 1}/$maxRetries in ${delay.inMilliseconds}ms',
    );
    await _sleep(delay);

    options.extra[attemptKey] = attempt + 1;
    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Whether [err] is a transient failure on an idempotent request.
  bool shouldRetry(DioException err) {
    if (!_idempotentMethods.contains(err.requestOptions.method.toUpperCase())) {
      return false;
    }
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        return retryableStatusCodes.contains(err.response?.statusCode);
      default:
        return false;
    }
  }

  /// `Retry-After` (seconds) if present, else `baseDelay * 2^attempt`;
  /// both capped at [maxDelay].
  Duration retryDelay(DioException err, int attempt) {
    final header = err.response?.headers.value('retry-after');
    final seconds = header == null ? null : int.tryParse(header.trim());
    final delay = seconds != null && seconds >= 0
        ? Duration(seconds: seconds)
        : baseDelay * math.pow(2, attempt).toInt();
    return delay > maxDelay ? maxDelay : delay;
  }
}
