import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
          'poster_path': '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
          'overview': 'Overview...',
          'release_date': '2010-07-15',
          'media_type': 'movie',
        },
        {
          'id': 1396,
          'name': 'Breaking Bad',
          'poster_path': '/ggm8ih04ly739Y69Ul9I678YWAX.jpg',
          'overview': '...',
          'first_air_date': '2008-01-20',
          'media_type': 'tv',
        }
      ]
    };

    test('should return List<MediaItem> when the response is successful', () async {
      // arrange
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tMediaResponse,
          statusCode: 200,
        ),
      );

      // act
      final result = await dataSource.searchMedia(tQuery);

      // assert
      expect(result.first.id, equals(tMediaResponse['results']?[0]['id']));
      verify(() => mockDio.get(
        any(),
        queryParameters: {
          'query': tQuery,
          'page': 1,
        },
        options: any(named: 'options'),
      )).called(1);
    });

    test('should throw an Exception when the response fails', () async {
      // arrange
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      // act
      final call = dataSource.searchMedia(tQuery);

      // assert
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
      // arrange
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

      // act
      final result = await dataSource.getMediaItem(tId);

      // assert
      expect(result.id, equals(tId));
      expect(result.title, 'Inception');
    });
  });

  group('getActorDetails', () {
    const tActorId = 1;
    final tActorDetails = {
      'id': 1,
      'name': 'Leonardo DiCaprio',
      'biography': 'Bio...',
      'birthday': '1974-11-11',
      'place_of_birth': 'Los Angeles, California, USA',
      'profile_path': '/leo.jpg',
    };

    test('should return ActorDetails when the response is successful', () async {
      // arrange
      when(() => mockDio.get(
        any(),
        options: any(named: 'options'),
      )).thenAnswer(
            (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tActorDetails,
          statusCode: 200,
        ),
      );

      // act
      final result = await dataSource.getActorDetails(tActorId);

      // assert
      expect(result.id, equals(tActorId));
      expect(result.name, equals('Leonardo DiCaprio'));
    });
  });

  group('getActorMovieCredits', () {
    const tActorId = 1;
    final tMovieCredits = {
      'cast': [
        {
          'id': 27205,
          'title': 'Inception',
          'poster_path': '/path.jpg',
          'overview': 'Overview...',
          'release_date': '2010-07-15',
        }
      ]
    };

    test('should return List<Movie> when the response is successful', () async {
      // arrange
      when(() => mockDio.get(
        any(),
        options: any(named: 'options'),
      )).thenAnswer(
            (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tMovieCredits,
          statusCode: 200,
        ),
      );

      // act
      final result = await dataSource.getActorMediaCredits(tActorId);

      // assert
      expect(result.length, 1);
      expect(result.first.title, equals('Inception'));
    });
  });
}
