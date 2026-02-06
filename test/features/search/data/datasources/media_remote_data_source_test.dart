import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MediaRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = MediaRemoteDataSource(dio: mockDio, apiToken: 'mock_token');
  });

  group('searchMedia', () {
    const tQuery = 'Inception';

    final tMediaResponse = {
      'results': [
        {
          'id': 27205,
          'title': 'Inception',
          'poster_path': '/path.jpg',
          'overview': '...',
          'poster_path': '/path.jpg',
          'overview': '...',
          'release_date': '2010-07-15',
          'media_type': 'movie',
        }
      ]
    };

    test('should return List<MediaItem> when the response is successful', () async {
      // 1. Mock search results
      // 1. Mock search results
      when(() => mockDio.get(
            'https://api.themoviedb.org/3/search/multi',
            'https://api.themoviedb.org/3/search/multi',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tMediaResponse,
          statusCode: 200,
        ),
      );

      // 2. Mock enrichment fetch
      when(() => mockDio.get(
            any(that: startsWith('https://api.themoviedb.org/3/movie/')),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tMediaResponse['results']![0],
          statusCode: 200,
        ),
      );

      // 2. Mock enrichment fetch
      when(() => mockDio.get(
            any(that: startsWith('https://api.themoviedb.org/3/movie/')),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tMediaResponse['results']![0],
          statusCode: 200,
        ),
      );

      final result = await dataSource.searchMedia(tQuery);

      expect(result.first.id, equals(27205));
    });

    test('should throw NetworkException on connection error', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ));

      final call = dataSource.searchMedia(tQuery);

      expect(() => call, throwsA(isA<NetworkException>()));
    });

    test('should throw ServerException on 429 Rate Limit', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'), options: any(named: 'options')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 429,
            ),
          ));

      final call = dataSource.searchMedia(tQuery);

      expect(() => call, throwsA(predicate((e) => e is ServerException && e.statusCode == 429)));
    });
  });

  group('getMediaItem', () {
    const tId = 27205;
    final tItemData = {
      'id': 27205,
      'title': 'Inception',
      'poster_path': '/path.jpg',
      'overview': '...',
      'release_date': '2010-07-15',
    };

    test('should return MediaItem when the response is successful', () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tItemData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getMediaItem(tId);

      expect(result.id, equals(tId));
      expect(result.title, 'Inception');
    });

    test('should throw ServerException on 404 Not Found', () async {
      when(() => mockDio.get(any(), options: any(named: 'options')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 404,
            ),
          ));

      final call = dataSource.getMediaItem(tId);

      expect(() => call, throwsA(predicate((e) => e is ServerException && e.statusCode == 404)));
    });
  });

  group('getSeasonDetails', () {
    test('should throw ServerException on failure', () async {
      when(() => mockDio.get(any(), options: any(named: 'options')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
            ),
          ));

      final call = dataSource.getSeasonDetails(1, 1);

      expect(() => call, throwsA(isA<ServerException>()));
    });
  });
}
