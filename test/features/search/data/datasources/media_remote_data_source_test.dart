import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
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

  group('searchMedia with Filters', () {
    const tQuery = 'Inception';
    final tResponse = {
      'results': [
        {
          'id': 1,
          'title': 'T',
          'media_type': 'movie',
          'overview': 'O',
          'release_date': '2023',
        },
      ],
    };

    test('should include filter parameters in the query', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tResponse,
          statusCode: 200,
        ),
      );

      await dataSource.searchMedia(
        tQuery,
        genreIds: [28, 12],
        releaseYear: 2022,
        minRating: 8.0,
        type: MediaType.movie,
      );

      final captured =
          verify(
                () => mockDio.get(
                  'https://api.themoviedb.org/3/search/movie',
                  queryParameters: captureAny(named: 'queryParameters'),
                  options: any(named: 'options'),
                ),
              ).captured.first
              as Map<String, dynamic>;

      expect(captured['query'], tQuery);
      expect(captured['with_genres'], '28,12');
      expect(captured['primary_release_year'], 2022);
      expect(captured['vote_average.gte'], 8.0);
    });
  });

  group('discoverMedia', () {
    final tResponse = {
      'results': [
        {'id': 1, 'title': 'T', 'overview': 'O', 'release_date': '2023'},
      ],
    };

    test('should call correct discover endpoint based on type', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tResponse,
          statusCode: 200,
        ),
      );

      await dataSource.discoverMedia(type: MediaType.tv, genreIds: [18]);

      verify(
        () => mockDio.get(
          'https://api.themoviedb.org/3/discover/tv',
          queryParameters: any(
            named: 'queryParameters',
            that: containsPair('with_genres', '18'),
          ),
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('Enrichment Endpoints', () {
    final tMediaListResponse = {
      'results': [
        {'id': 1, 'title': 'T', 'overview': 'O', 'release_date': '2023'},
      ],
    };

    test('getSimilarMedia should return List<MediaItem>', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tMediaListResponse,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getSimilarMedia(1, MediaType.movie);

      expect(result, isA<List<MediaItem>>());
      verify(
        () => mockDio.get(
          'https://api.themoviedb.org/3/movie/1/similar',
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('getWatchProviders should return results map', () async {
      final tProviders = {
        'results': {
          'US': {'flatrate': []},
        },
      };
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tProviders,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getWatchProviders(1, MediaType.movie);

      expect(result['US'], isNotNull);
    });

    test('getVideos should return list of video maps', () async {
      final tVideos = {
        'results': [
          {'key': 'xyz', 'type': 'Trailer'},
        ],
      };
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tVideos,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getVideos(1, MediaType.movie);

      expect(result.first['key'], 'xyz');
    });
  });
}
