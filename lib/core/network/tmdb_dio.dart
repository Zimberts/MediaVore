import 'package:dio/dio.dart';
import 'package:mediavore/core/network/rate_limit_interceptor.dart';
import 'package:mediavore/core/network/retry_interceptor.dart';

const Duration tmdbConnectTimeout = Duration(seconds: 10);
const Duration tmdbReceiveTimeout = Duration(seconds: 20);
const Duration tmdbSendTimeout = Duration(seconds: 10);

/// Builds the app-wide [Dio] with bounded timeouts, a request rate below
/// TMDB's limit and transient-error retry.
Dio createTmdbDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: tmdbConnectTimeout,
      receiveTimeout: tmdbReceiveTimeout,
      sendTimeout: tmdbSendTimeout,
    ),
  );
  dio.interceptors
    ..add(RateLimitInterceptor())
    ..add(RetryInterceptor(dio: dio));
  return dio;
}
