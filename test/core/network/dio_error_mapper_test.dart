import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/network/dio_error_mapper.dart';

void main() {
  group('mapDioException', () {
    test('should map timeout and connection errors to NetworkException', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        final err = DioException(requestOptions: RequestOptions(), type: type);
        final mapped = mapDioException(err, 'fetching data');
        expect(mapped, isA<NetworkException>());
        expect(mapped.message, 'Network error while fetching data');
        expect(mapped.cause, err);
      }
    });

    test('should map badResponse to ServerException with status code', () {
      final err = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 503),
      );
      final mapped = mapDioException(err, 'fetching data');
      expect(mapped, isA<ServerException>());
      expect((mapped as ServerException).statusCode, 503);
    });

    test('should map other DioException types to ServerException', () {
      final err = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.cancel,
      );
      final mapped = mapDioException(err, 'fetching data');
      expect(mapped, isA<ServerException>());
      expect((mapped as ServerException).statusCode, isNull);
    });
  });

  group('guardDioRequest', () {
    test('should return the result when request succeeds', () async {
      final result = await guardDioRequest('testing', () async => 42);
      expect(result, 42);
    });

    test('should map DioException using mapDioException', () async {
      await expectLater(
        guardDioRequest<void>(
          'testing',
          () => throw DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
          ),
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should rethrow AppException unchanged', () async {
      const exception = ServerException('custom', 418);
      await expectLater(
        guardDioRequest<void>('testing', () => throw exception),
        throwsA(same(exception)),
      );
    });

    test('should wrap unexpected errors in ParsingException', () async {
      await expectLater(
        guardDioRequest<void>('testing', () => throw const FormatException()),
        throwsA(isA<ParsingException>()),
      );
    });
  });
}
