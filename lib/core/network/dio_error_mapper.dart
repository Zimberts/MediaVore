import 'package:dio/dio.dart';
import 'package:mediavore/core/error/exceptions.dart';

/// Maps a [DioException] to the matching [AppException].
///
/// Timeouts and connection failures become [NetworkException]; HTTP error
/// responses become [ServerException] with the status code; anything else
/// (cancel, bad certificate, unknown) becomes [ServerException] without one.
AppException mapDioException(DioException e, String action) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkException('Network error while $action', e);
    case DioExceptionType.badResponse:
      return ServerException(
        'Server error while $action',
        e.response?.statusCode,
        e,
      );
    default:
      return ServerException('Request failed while $action', null, e);
  }
}

/// Runs [request] and normalizes failures into [AppException]s.
///
/// [DioException]s go through [mapDioException]; [AppException]s are
/// rethrown unchanged; any other error becomes a [ParsingException].
Future<T> guardDioRequest<T>(
  String action,
  Future<T> Function() request,
) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw mapDioException(e, action);
  } on AppException {
    rethrow;
  } catch (e) {
    throw ParsingException('Failed to parse response while $action', e);
  }
}
