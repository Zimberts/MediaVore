import 'package:dio/dio.dart';
import 'package:mediavore/core/network/retry_interceptor.dart';

const Duration tmdbConnectTimeout = Duration(seconds: 10);
const Duration tmdbReceiveTimeout = Duration(seconds: 20);
const Duration tmdbSendTimeout = Duration(seconds: 10);

/// Builds the app-wide [Dio] with bounded timeouts and transient-error retry.
Dio createTmdbDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: tmdbConnectTimeout,
      receiveTimeout: tmdbReceiveTimeout,
      sendTimeout: tmdbSendTimeout,
    ),
  );
  dio.interceptors.add(RetryInterceptor(dio: dio));
  return dio;
}
