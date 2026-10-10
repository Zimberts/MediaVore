import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/network/retry_interceptor.dart';
import 'package:mediavore/core/network/tmdb_dio.dart';

/// Replays a scripted sequence of responses (status code, headers) or
/// connection errors, recording each request.
class _ScriptedAdapter implements HttpClientAdapter {
  final List<Object> script; // int status | DioExceptionType
  final Map<String, List<String>> headers;
  int calls = 0;

  _ScriptedAdapter(this.script, {this.headers = const {}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final step = script[calls < script.length ? calls : script.length - 1];
    calls++;
    if (step is DioExceptionType) {
      throw DioException(requestOptions: options, type: step);
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      step as int,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<Duration> sleeps;

  Dio buildDio(_ScriptedAdapter adapter, {int maxRetries = 3}) {
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        maxRetries: maxRetries,
        sleep: (d) async => sleeps.add(d),
      ),
    );
    return dio;
  }

  setUp(() => sleeps = []);

  group('RetryInterceptor', () {
    test('should retry 429 then return the successful response', () async {
      final adapter = _ScriptedAdapter([429, 429, 200]);
      final response = await buildDio(adapter).get('https://x.test/a');

      expect(response.statusCode, 200);
      expect(adapter.calls, 3);
      expect(sleeps, [
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 1000),
      ]);
    });

    test('should honour Retry-After seconds, capped at maxDelay', () async {
      final adapter = _ScriptedAdapter(
        [429, 200],
        headers: {
          'retry-after': ['2'],
        },
      );
      await buildDio(adapter).get('https://x.test/a');
      expect(sleeps, [const Duration(seconds: 2)]);

      sleeps.clear();
      final capped = _ScriptedAdapter(
        [429, 200],
        headers: {
          'retry-after': ['120'],
        },
      );
      await buildDio(capped).get('https://x.test/a');
      expect(sleeps, [const Duration(seconds: 10)]);
    });

    test('should give up after maxRetries and surface the error', () async {
      final adapter = _ScriptedAdapter([503]);
      await expectLater(
        buildDio(adapter).get('https://x.test/a'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            503,
          ),
        ),
      );
      expect(adapter.calls, 4); // 1 + 3 retries
      expect(sleeps.length, 3);
    });

    test('should retry connection errors', () async {
      final adapter = _ScriptedAdapter([DioExceptionType.connectionError, 200]);
      final response = await buildDio(adapter).get('https://x.test/a');
      expect(response.statusCode, 200);
      expect(adapter.calls, 2);
    });

    test('should not retry non-transient statuses', () async {
      final adapter = _ScriptedAdapter([404]);
      await expectLater(
        buildDio(adapter).get('https://x.test/a'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
      expect(sleeps, isEmpty);
    });

    test('should not retry non-idempotent methods', () async {
      final adapter = _ScriptedAdapter([503]);
      await expectLater(
        buildDio(adapter).post('https://x.test/a'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    });
  });

  group('createTmdbDio', () {
    test('should set bounded timeouts and install the retry interceptor', () {
      final dio = createTmdbDio();
      expect(dio.options.connectTimeout, tmdbConnectTimeout);
      expect(dio.options.receiveTimeout, tmdbReceiveTimeout);
      expect(dio.options.sendTimeout, tmdbSendTimeout);
      expect(dio.interceptors.whereType<RetryInterceptor>(), hasLength(1));
    });
  });
}
