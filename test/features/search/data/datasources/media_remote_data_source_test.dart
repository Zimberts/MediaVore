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

  group('searchMedia', () {
    const tQuery = 'Inception';
    
    final tMediaResponse = {
      'results': [
        {
          'id': 27205,
          'title': 'Inception',
          'poster_path': '/path.jpg',
          'overview': '...',
          'release_date': '2010-07-15',
          'media_type': 'movie',
        }
      ]
    };

    test('should return List<MediaItem> when the response is successful', () async {
      // 1. Mock search results
      when(() => mockDio.get(
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

      final result = await dataSource.searchMedia(tQuery);

      expect(result.first.id, equals(27205));
    });

    test('should throw an Exception when the response fails', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final call = dataSource.searchMedia(tQuery);

      expect(() => call, throwsA(anything));
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
  });

  group('getSeasonDetails', () {
    test('should return map of season details', () async {
      final tData = {'id': 1, 'name': 'Season 1', 'episodes': []};
      
      when(() => mockDio.get(
        'https://api.themoviedb.org/3/tv/1/season/1',
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: tData,
        statusCode: 200,
      ));

      final result = await dataSource.getSeasonDetails(1, 1);

      expect(result['name'], 'Season 1');
    });
  });

  group('getActorDetails', () {
    test('should return ActorDetails when successful', () async {
      final tActorDetails = {'id': 1, 'name': 'Leo', 'biography': '...', 'birthday': '1974', 'place_of_birth': 'LA', 'profile_path': '/path'};
      
      when(() => mockDio.get(any(that: contains('person/1')), options: any(named: 'options')))
          .thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), data: tActorDetails, statusCode: 200));

      final result = await dataSource.getActorDetails(1);
      expect(result.id, 1);
      expect(result.name, 'Leo');
    });
  });

  group('getMediaCredits', () {
    test('should return credit details', () async {
      final tData = {'cast': [], 'crew': []};
      
      when(() => mockDio.get(
        'https://api.themoviedb.org/3/movie/1/credits',
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: tData,
        statusCode: 200,
      ));

      final result = await dataSource.getMediaCredits(1, type: MediaType.movie);

      expect(result, equals(tData));
    });
  });
}
