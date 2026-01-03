import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/media_details/data/datasources/watchlist_local_data_source.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late WatchlistLocalDataSource dataSource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    dataSource = WatchlistLocalDataSource(mockSharedPreferences);
  });

  group('addToWatchlist', () {
    const tId = 1;
    const tType = 'movie';
    const tEntry = '1:movie';

    test('should add item to watchlist when not already present', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(['2:movie', '3:tv']);
      when(() => mockSharedPreferences.setStringList('watchlist', ['2:movie', '3:tv', tEntry]))
          .thenAnswer((_) async => true);

      // act
      await dataSource.addToWatchlist(tId, tType);

      // assert
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
      verify(() => mockSharedPreferences.setStringList('watchlist', ['2:movie', '3:tv', tEntry])).called(1);
    });

    test('should not add item to watchlist when already present', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn([tEntry, '2:movie']);

      // act
      await dataSource.addToWatchlist(tId, tType);

      // assert
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
      verifyNever(() => mockSharedPreferences.setStringList(any(), any()));
    });
  });

  group('removeFromWatchlist', () {
    const tId = 1;
    const tType = 'movie';

    test('should remove item from watchlist', () async {
      // arrange
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(['1:movie', '2:movie', '3:tv']);
      when(() => mockSharedPreferences.setStringList('watchlist', ['2:movie', '3:tv']))
          .thenAnswer((_) async => true);

      // act
      await dataSource.removeFromWatchlist(tId, tType);

      // assert
      verify(() => mockSharedPreferences.getStringList('watchlist')).called(1);
      verify(() => mockSharedPreferences.setStringList('watchlist', ['2:movie', '3:tv'])).called(1);
    });
  });

  group('getWatchlistEntries', () {
    test('should return list of strings from watchlist', () async {
      // arrange
      final tEntries = ['1:movie', '2:tv'];
      when(() => mockSharedPreferences.getStringList('watchlist'))
          .thenReturn(tEntries);

      // act
      final result = await dataSource.getWatchlistEntries();

      // assert
      expect(result, tEntries);
    });
  });
}
