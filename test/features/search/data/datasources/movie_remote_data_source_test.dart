import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/features/search/data/datasources/movie_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/fixture_reader.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MovieRemoteDataSource dataSource;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerTestFallbacks();
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = MovieRemoteDataSource(client: mockHttpClient);
    dotenv.testLoad(fileInput: 'TMDB_API_TOKEN=mock_token');
  });

  group('searchMovies', () {
    const tQuery = 'Inception';
    final tMovieList = [
      const Movie(
        id: 1,
        title: 'Inception',
        posterPath: '/path.jpg',
        overview: 'Overview...',
        releaseDate: '2010-07-16',
      ),
    ];

    test('should return List<Movie> when the response code is 200', () async {
      // arrange
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(fixture('movie_search_results.json'), 200));

      // act
      final result = await dataSource.searchMovies(tQuery);

      // assert
      expect(result, equals(tMovieList));
      verify(() => mockHttpClient.get(
        Uri.parse('https://api.themoviedb.org/3/search/movie?query=$tQuery'),
        headers: {
          'Authorization': 'Bearer mock_token',
          'Content-Type': 'application/json',
        },
      )).called(1);
    });

    test('should throw an Exception when the response code is not 200', () async {
      // arrange
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Something went wrong', 404));

      // act
      final call = dataSource.searchMovies(tQuery);

      // assert
      expect(() => call, throwsA(const TypeMatcher<Exception>()));
    });
  });

  group('getMovie', () {
    const tMovieId = 1;
    const tMovie = Movie(
      id: 1,
      title: 'Inception',
      posterPath: '/path.jpg',
      overview: 'Overview...',
      releaseDate: '2010-07-16',
    );

    test('should return Movie when the response code is 200', () async {
      // arrange
      final jsonString = json.encode(tMovie.toJson());
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonString, 200));

      // act
      final result = await dataSource.getMovie(tMovieId);

      // assert
      expect(result, equals(tMovie));
      verify(() => mockHttpClient.get(
        Uri.parse('https://api.themoviedb.org/3/movie/$tMovieId'),
        headers: {
          'Authorization': 'Bearer mock_token',
          'Content-Type': 'application/json',
        },
      )).called(1);
    });

    test('should throw an Exception when the response code is not 200', () async {
      // arrange
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Something went wrong', 404));

      // act
      final call = dataSource.getMovie(tMovieId);

      // assert
      expect(() => call, throwsA(const TypeMatcher<Exception>()));
    });
  });

  group('getMovieCredits', () {
    const tMovieId = 1;
    final tCredits = {'cast': [], 'crew': []};

    test('should return Map<String, dynamic> when the response code is 200', () async {
      // arrange
      final jsonString = json.encode(tCredits);
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonString, 200));

      // act
      final result = await dataSource.getMovieCredits(tMovieId);

      // assert
      expect(result, equals(tCredits));
      verify(() => mockHttpClient.get(
        Uri.parse('https://api.themoviedb.org/3/movie/$tMovieId/credits'),
        headers: {
          'Authorization': 'Bearer mock_token',
          'Content-Type': 'application/json',
        },
      )).called(1);
    });

    test('should throw an Exception when the response code is not 200', () async {
      // arrange
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Something went wrong', 404));

      // act
      final call = dataSource.getMovieCredits(tMovieId);

      // assert
      expect(() => call, throwsA(const TypeMatcher<Exception>()));
    });
  });
}