import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/features/search/data/datasources/movie_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/fixture_reader.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MovieRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = MovieRemoteDataSource(dio: mockDio, apiToken: 'mock_token');
  });

  group('searchMovies', () {
    const tQuery = 'Inception';
    final tMovieList = [
      Movie.fromJson(const {
        'id': 27205,
        'title': 'Inception',
        'poster_path': '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
        'overview':
            'Cobb, a skilled thief who commits corporate espionage by infiltrating the subconscious of his targets is offered a chance to regain his old life as payment for a task considered to be impossible: "inception", the implantation of another person\'s idea into a target\'s subconscious.',
        'release_date': '2010-07-15',
      }),
    ];

    test('should return List<Movie> when the response is successful', () async {
      // arrange
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: json.decode(fixture('movie_search_results.json')),
          statusCode: 200,
        ),
      );

      // act
      final result = await dataSource.searchMovies(tQuery);

      // assert
      expect(result.first.id, equals(tMovieList.first.id));
    });

    test('should throw an Exception when the response is not successful', () async {
      // arrange
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(Exception('Failed to load movies'));

      // act
      final call = dataSource.searchMovies(tQuery);

      // assert
      expect(() => call, throwsA(const TypeMatcher<Exception>()));
    });
  });

  group('getMovie', () {
    const tMovieId = 27205;
    final tMovie = Movie.fromJson(const {
      'id': 27205,
      'title': 'Inception',
      'poster_path': '/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
      'overview':
          'Cobb, a skilled thief who commits corporate espionage by infiltrating the subconscious of his targets is offered a chance to regain his old life as payment for a task considered to be impossible: "inception", the implantation of another person\'s idea into a target\'s subconscious.',
      'release_date': '2010-07-15',
    });


    test('should return Movie when the response is successful', () async {
      // arrange
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: tMovie.toJson(),
          statusCode: 200,
        ),
      );

      // act
      final result = await dataSource.getMovie(tMovieId);

      // assert
      expect(result, equals(tMovie));
    });

    test('should throw an Exception when the response is not successful', () async {
      // arrange
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenThrow(Exception('Failed to load movie'));

      // act
      final call = dataSource.getMovie(tMovieId);

      // assert
      expect(() => call, throwsA(const TypeMatcher<Exception>()));
    });
  });
}