import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/movie_details/data/datasources/watchlist_local_data_source.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late WatchlistLocalDataSource dataSource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    dataSource = WatchlistLocalDataSource(mockSharedPreferences);
  });

  group('addMovie', () {
    const tMovieId = 1;

    test('should add movie to watchlist when not already present', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(['2', '3']);
      when(() => mockSharedPreferences.setStringList('watchlist', ['2', '3', '1']))
          .thenAnswer((_) async => true);

      // act
      await dataSource.addMovie(tMovieId);

      // assert
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
      verify(() => mockSharedPreferences.setStringList('watchlist', ['2', '3', '1'])).called(1);
    });

    test('should not add movie to watchlist when already present', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(['1', '2', '3']);

      // act
      await dataSource.addMovie(tMovieId);

      // assert
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
      verifyNever(() => mockSharedPreferences.setStringList(any(), any()));
    });

    test('should add movie to empty watchlist', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(null);
      when(() => mockSharedPreferences.setStringList('watchlist', ['1']))
          .thenAnswer((_) async => true);

      // act
      await dataSource.addMovie(tMovieId);

      // assert
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
      verify(() => mockSharedPreferences.setStringList('watchlist', ['1'])).called(1);
    });
  });

  group('removeMovie', () {
    const tMovieId = 1;

    test('should remove movie from watchlist', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(['1', '2', '3']);
      when(() => mockSharedPreferences.setStringList('watchlist', ['2', '3']))
          .thenAnswer((_) async => true);

      // act
      await dataSource.removeMovie(tMovieId);

      // assert
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
      verify(() => mockSharedPreferences.setStringList('watchlist', ['2', '3'])).called(1);
    });

    test('should do nothing when movie not in watchlist', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(['2', '3']);
      when(() => mockSharedPreferences.setStringList('watchlist', ['2', '3']))
          .thenAnswer((_) async => true);

      // act
      await dataSource.removeMovie(tMovieId);

      // assert
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
      verify(() => mockSharedPreferences.setStringList('watchlist', ['2', '3'])).called(1);
    });
  });

  group('getWatchlistMovieIds', () {
    test('should return list of movie ids from watchlist', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(['1', '2', '3']);

      // act
      final result = await dataSource.getWatchlistMovieIds();

      // assert
      expect(result, [1, 2, 3]);
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
    });

    test('should return empty list when watchlist is null', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(null);

      // act
      final result = await dataSource.getWatchlistMovieIds();

      // assert
      expect(result, []);
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
    });
  });
}