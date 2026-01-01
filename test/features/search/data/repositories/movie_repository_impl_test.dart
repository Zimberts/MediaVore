import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/features/search/data/repositories/movie_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MovieRepositoryImpl repository;
  late MockMovieRemoteDataSource mockRemoteDataSource;
  late MockWatchlistLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockMovieRemoteDataSource();
    mockLocalDataSource = MockWatchlistLocalDataSource();
    repository = MovieRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  const tMovie = Movie(
    id: 1,
    title: 'Inception',
    posterPath: '/path.jpg',
    overview: 'Overview...',
    releaseDate: '2010-07-16',
  );

  final tCast = [
    const CastMember(name: 'Leonardo DiCaprio', character: 'Cobb', profilePath: '/leo.jpg'),
  ];

  const tDirector = CrewMember(name: 'Christopher Nolan', job: 'Director');

  group('searchMovies', () {
    const tQuery = 'Inception';
    final tMovies = [tMovie];

    test('should return list of movies from remote data source', () async {
      // arrange
      when(() => mockRemoteDataSource.searchMovies(tQuery))
          .thenAnswer((_) async => tMovies);

      // act
      final result = await repository.searchMovies(tQuery);

      // assert
      expect(result, equals(tMovies));
      verify(() => mockRemoteDataSource.searchMovies(tQuery)).called(1);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });
  });

  group('getMovieDetails', () {
    const tMovieId = 1;

    test('should return movie details with cast and director', () async {
      // arrange
      when(() => mockRemoteDataSource.getMovie(tMovieId))
          .thenAnswer((_) async => tMovie);
      when(() => mockRemoteDataSource.getMovieCredits(tMovieId))
          .thenAnswer((_) async => {
            'cast': [
              {'name': 'Leonardo DiCaprio', 'character': 'Cobb', 'profile_path': '/leo.jpg'}
            ],
            'crew': [
              {'name': 'Christopher Nolan', 'job': 'Director'}
            ]
          });

      // act
      final result = await repository.getMovieDetails(tMovieId);

      // assert
      expect(result.movie, equals(tMovie));
      expect(result.cast, equals(tCast));
      expect(result.director, equals(tDirector));
      verify(() => mockRemoteDataSource.getMovie(tMovieId)).called(1);
      verify(() => mockRemoteDataSource.getMovieCredits(tMovieId)).called(1);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('should return movie details with N/A director when no director found', () async {
      // arrange
      when(() => mockRemoteDataSource.getMovie(tMovieId))
          .thenAnswer((_) async => tMovie);
      when(() => mockRemoteDataSource.getMovieCredits(tMovieId))
          .thenAnswer((_) async => {
            'cast': [
              {'name': 'Leonardo DiCaprio', 'character': 'Cobb', 'profile_path': '/leo.jpg'}
            ],
            'crew': [
              {'name': 'Someone', 'job': 'Writer'}
            ]
          });

      // act
      final result = await repository.getMovieDetails(tMovieId);

      // assert
      expect(result.movie, equals(tMovie));
      expect(result.cast, equals(tCast));
      expect(result.director, CrewMember(name: 'N/A', job: 'Director'));
    });
  });

  group('addMovieToWatchlist', () {
    const tMovieId = 1;

    test('should call local data source to add movie', () async {
      // arrange
      when(() => mockLocalDataSource.addMovie(tMovieId))
          .thenAnswer((_) async => Future.value());

      // act
      await repository.addMovieToWatchlist(tMovieId);

      // assert
      verify(() => mockLocalDataSource.addMovie(tMovieId)).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });

  group('removeMovieFromWatchlist', () {
    const tMovieId = 1;

    test('should call local data source to remove movie', () async {
      // arrange
      when(() => mockLocalDataSource.removeMovie(tMovieId))
          .thenAnswer((_) async => Future.value());

      // act
      await repository.removeMovieFromWatchlist(tMovieId);

      // assert
      verify(() => mockLocalDataSource.removeMovie(tMovieId)).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });

  group('getWatchlistMovieIds', () {
    final tIds = [1, 2, 3];

    test('should return list of movie ids from local data source', () async {
      // arrange
      when(() => mockLocalDataSource.getWatchlistMovieIds())
          .thenAnswer((_) async => tIds);

      // act
      final result = await repository.getWatchlistMovieIds();

      // assert
      expect(result, equals(tIds));
      verify(() => mockLocalDataSource.getWatchlistMovieIds()).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });

  group('isMovieInWatchlist', () {
    const tMovieId = 1;
    final tIds = [1, 2, 3];

    test('should return true when movie is in watchlist', () async {
      // arrange
      when(() => mockLocalDataSource.getWatchlistMovieIds())
          .thenAnswer((_) async => tIds);

      // act
      final result = await repository.isMovieInWatchlist(tMovieId);

      // assert
      expect(result, true);
      verify(() => mockLocalDataSource.getWatchlistMovieIds()).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should return false when movie is not in watchlist', () async {
      // arrange
      when(() => mockLocalDataSource.getWatchlistMovieIds())
          .thenAnswer((_) async => [2, 3]);

      // act
      final result = await repository.isMovieInWatchlist(tMovieId);

      // assert
      expect(result, false);
      verify(() => mockLocalDataSource.getWatchlistMovieIds()).called(1);
      verifyNoMoreInteractions(mockLocalDataSource);
    });
  });
}