import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MediaRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = MediaRemoteDataSource(
      dio: mockDio,
      credentials: FakeTmdbCredentialStore('mock_token'),
      locale: FakeLocaleService(),
    );
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
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
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
          queryParameters: any(named: 'queryParameters'),
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
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
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
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
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

  group('TMDB authentication', () {
    Future<(Map<String, dynamic>?, Options?)> captureRequest(
      String credential,
    ) async {
      final ds = MediaRemoteDataSource(
        dio: mockDio,
        credentials: FakeTmdbCredentialStore(credential),
        locale: FakeLocaleService(),
      );
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'results': []},
          statusCode: 200,
        ),
      );
      await ds.getSimilarMedia(1, MediaType.movie);
      final captured = verify(
        () => mockDio.get(
          any(),
          queryParameters: captureAny(named: 'queryParameters'),
          options: captureAny(named: 'options'),
        ),
      ).captured;
      return (captured[0] as Map<String, dynamic>?, captured[1] as Options?);
    }

    test('should send a v4 token as Bearer header, not in the URL', () async {
      final (params, options) = await captureRequest('Bearer eyJ.token.sig');

      expect(params?.containsKey('api_key') ?? false, isFalse);
      expect(options?.headers?['Authorization'], 'Bearer eyJ.token.sig');
    });

    test('should send a v3 key as api_key query parameter', () async {
      const v3 = '0123456789abcdef0123456789abcdef';
      final (params, options) = await captureRequest(v3);

      expect(params?['api_key'], v3);
      expect(options?.headers?['Authorization'], isNull);
    });

    test('should throw ConfigurationException when no credential', () {
      final ds = MediaRemoteDataSource(
        dio: mockDio,
        credentials: FakeTmdbCredentialStore(),
        locale: FakeLocaleService(),
      );

      expect(
        () => ds.getSimilarMedia(1, MediaType.movie),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });

  group('Error mapping', () {
    DioException dioError(DioExceptionType type, {int? statusCode}) =>
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: type,
          response: statusCode == null
              ? null
              : Response(
                  requestOptions: RequestOptions(path: ''),
                  statusCode: statusCode,
                ),
        );

    void stubGetError(Object error) {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(error);
    }

    // Every endpoint, so a missing mapping in any of them is caught.
    final endpoints = <String, Future<Object?> Function(MediaRemoteDataSource)>{
      'searchMedia': (d) => d.searchMedia('q'),
      'getMediaItem': (d) => d.getMediaItem(1),
      'getSeasonDetails': (d) => d.getSeasonDetails(1, 1),
      'getMediaCredits': (d) => d.getMediaCredits(1),
      'getActorDetails': (d) => d.getActorDetails(1),
      'discover': (d) => d.discover(mediaType: 'movie'),
      'getActorMediaCredits': (d) => d.getActorMediaCredits(1),
      'getSimilarMedia': (d) => d.getSimilarMedia(1, MediaType.movie),
      'getCollectionParts': (d) => d.getCollectionParts(1),
      'getRecommendedMedia': (d) => d.getRecommendedMedia(1, MediaType.movie),
      'getWatchProviders': (d) => d.getWatchProviders(1, MediaType.movie),
      'getVideos': (d) => d.getVideos(1, MediaType.movie),
    };

    for (final entry in endpoints.entries) {
      group(entry.key, () {
        for (final type in [
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        ]) {
          test('should throw NetworkException on $type', () async {
            stubGetError(dioError(type));
            await expectLater(
              entry.value(dataSource),
              throwsA(isA<NetworkException>()),
            );
          });
        }

        test(
          'should throw ServerException with status code on bad response',
          () async {
            stubGetError(
              dioError(DioExceptionType.badResponse, statusCode: 404),
            );
            await expectLater(
              entry.value(dataSource),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.statusCode,
                  'statusCode',
                  404,
                ),
              ),
            );
          },
        );

        test(
          'should throw ServerException without status code on cancel',
          () async {
            stubGetError(dioError(DioExceptionType.cancel));
            await expectLater(
              entry.value(dataSource),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.statusCode,
                  'statusCode',
                  null,
                ),
              ),
            );
          },
        );

        test('should throw ParsingException on malformed payload', () async {
          when(
            () => mockDio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              options: any(named: 'options'),
            ),
          ).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: ''),
              data: 'not json',
              statusCode: 200,
            ),
          );
          await expectLater(
            entry.value(dataSource),
            throwsA(isA<ParsingException>()),
          );
        });

        test(
          'should throw ConfigurationException when credential is missing',
          () async {
            final unconfigured = MediaRemoteDataSource(
              dio: mockDio,
              credentials: FakeTmdbCredentialStore(),
              locale: FakeLocaleService(),
            );
            await expectLater(
              entry.value(unconfigured),
              throwsA(isA<ConfigurationException>()),
            );
          },
        );
      });
    }
  });

  group('app language', () {
    late MediaRemoteDataSource frenchDataSource;

    void stubGet(Map<String, dynamic> Function(Map<String, dynamic>) data) {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((inv) async {
        final params = Map<String, dynamic>.from(
          inv.namedArguments[#queryParameters] as Map,
        );
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: data(params),
          statusCode: 200,
        );
      });
    }

    List<Map<String, dynamic>> capturedParams() => verify(
      () => mockDio.get(
        any(),
        queryParameters: captureAny(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).captured.map((p) => Map<String, dynamic>.from(p as Map)).toList();

    setUp(() {
      frenchDataSource = MediaRemoteDataSource(
        dio: mockDio,
        credentials: FakeTmdbCredentialStore('mock_token'),
        locale: FakeLocaleService('fr-FR'),
      );
    });

    test('should send the app language on every request', () async {
      stubGet((_) => {'id': 1, 'title': 'T', 'overview': 'O'});

      await frenchDataSource.getMediaItem(1);
      await frenchDataSource.getSeasonDetails(1, 1);

      final params = capturedParams();
      expect(params, hasLength(2));
      for (final p in params) {
        expect(p['language'], 'fr-FR');
      }
    });

    test('should map the original-language filter for discover', () async {
      stubGet((_) => {'results': []});

      await frenchDataSource.discoverMedia(originalLanguage: 'ja');

      final params = capturedParams().single;
      expect(params['with_original_language'], 'ja');
      expect(params['language'], 'fr-FR');
    });

    test('should filter search results by original language', () async {
      stubGet(
        (_) => {
          'results': [
            {'id': 1, 'title': 'A', 'original_language': 'ja'},
            {'id': 2, 'title': 'B', 'original_language': 'en'},
          ],
        },
      );

      final result = await frenchDataSource.searchMedia(
        'q',
        originalLanguage: 'ja',
        type: MediaType.movie,
      );

      expect(result.map((m) => m.id), [1]);
      expect(capturedParams().single['language'], 'fr-FR');
    });

    test('should fall back to the English overview when missing', () async {
      stubGet(
        (params) => {
          'id': 1,
          'title': 'Titre',
          'overview': params['language'] == 'en-US' ? 'English overview' : '',
        },
      );

      final item = await frenchDataSource.getMediaItem(1);

      expect(item.title, 'Titre');
      expect(item.overview, 'English overview');
      expect(capturedParams().map((p) => p['language']), ['fr-FR', 'en-US']);
    });

    test('should not refetch the overview in English', () async {
      stubGet((_) => {'id': 1, 'title': 'T', 'overview': ''});

      await dataSource.getMediaItem(1);

      expect(capturedParams(), hasLength(1));
    });
  });
}
