import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/media_details/data/datasources/watchlist_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/watchlist_item.dart';
import 'dart:io';

void main() {
  late WatchlistLocalDataSource dataSource;
  late Isar isar;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp';
    if (!Directory(tempPath).existsSync()) {
      Directory(tempPath).createSync(recursive: true);
    }
  });

  setUp(() async {
    isar = await Isar.open(
      [WatchlistItemSchema],
      directory: tempPath,
      name: 'test_db',
    );
    dataSource = WatchlistLocalDataSource(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('WatchlistLocalDataSource (Integration)', () {
    const tId = 1;
    const tType = 'movie';

    test('should add and retrieve item from watchlist', () async {
      // act
      await dataSource.addToWatchlist(tId, tType);
      final entries = await dataSource.getWatchlistEntries();

      // assert
      expect(entries, contains('$tId:$tType'));
    });

    test('should remove item from watchlist', () async {
      // arrange
      await dataSource.addToWatchlist(tId, tType);
      await dataSource.addToWatchlist(2, 'tv');

      // act
      await dataSource.removeFromWatchlist(tId, tType);
      final entries = await dataSource.getWatchlistEntries();

      // assert
      expect(entries, isNot(contains('$tId:$tType')));
      expect(entries, contains('2:tv'));
    });

    test('should return all entries correctly', () async {
      // arrange
      await dataSource.addToWatchlist(1, 'movie');
      await dataSource.addToWatchlist(2, 'tv');

      // act
      final entries = await dataSource.getWatchlistEntries();

      // assert
      expect(entries.length, 2);
      expect(entries, containsAll(['1:movie', '2:tv']));
    });

    test('should handle adding duplicate entries (replace/idempotent)', () async {
      // act
      await dataSource.addToWatchlist(tId, tType);
      await dataSource.addToWatchlist(tId, tType);
      final entries = await dataSource.getWatchlistEntries();

      // assert
      expect(entries.length, 1);
      expect(entries, ['$tId:$tType']);
    });
  });
}
