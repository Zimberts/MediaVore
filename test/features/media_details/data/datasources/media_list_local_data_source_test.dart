import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'dart:io';

void main() {
  late MediaListLocalDataSource dataSource;
  late Isar isar;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_media_list';
    if (!Directory(tempPath).existsSync()) {
      Directory(tempPath).createSync(recursive: true);
    }
  });

  setUp(() async {
    isar = await Isar.open(
      [MediaListItemSchema, UserListSchema, SeenItemModelSchema],
      directory: tempPath,
      name: 'test_media_list_db',
    );
    dataSource = MediaListLocalDataSource(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('MediaListLocalDataSource - Seen Items', () {
    final tSeenItem = SeenItemModel(
      tmdbId: 1,
      type: 'movie',
      title: 'Dune',
      seenDate: DateTime(2023, 10, 1),
    );

    test('should mark an item as seen and retrieve it', () async {
      await dataSource.markAsSeen(tSeenItem);
      
      final seenItems = await dataSource.getAllSeenItems();
      expect(seenItems.length, 1);
      expect(seenItems.first.title, 'Dune');
    });

    test('should allow multiple seen entries for the same item (Multi-viewing)', () async {
      // arrange
      final firstDate = DateTime(2023, 10, 1);
      final secondDate = DateTime(2023, 10, 2);
      
      // act
      await dataSource.markAsSeen(SeenItemModel(
        tmdbId: 1, type: 'movie', title: 'Dune', seenDate: firstDate,
      ));
      await dataSource.markAsSeen(SeenItemModel(
        tmdbId: 1, type: 'movie', title: 'Dune', seenDate: secondDate,
      ));
      
      final seenItems = await dataSource.getAllSeenItems();

      // assert
      expect(seenItems.length, 2);
      expect(seenItems[0].seenDate, secondDate); // Sorted DESC
      expect(seenItems[1].seenDate, firstDate);
    });

    test('should remove all seen items for a specific TMDB ID and type', () async {
      await dataSource.markAsSeen(tSeenItem);
      await dataSource.markAsSeen(SeenItemModel(
        tmdbId: 1, type: 'movie', title: 'Dune', seenDate: DateTime.now(),
      ));
      
      await dataSource.removeFromSeen(1, 'movie');
      
      final seenItems = await dataSource.getAllSeenItems();
      expect(seenItems, isEmpty);
    });

    test('should sort seen items by date, season, and episode descending', () async {
      final item1 = SeenItemModel(tmdbId: 1, type: 'tv', title: 'A', seenDate: DateTime(2023, 1, 1), seasonNumber: 1, episodeNumber: 1);
      final item2 = SeenItemModel(tmdbId: 2, type: 'tv', title: 'B', seenDate: DateTime(2023, 1, 1), seasonNumber: 1, episodeNumber: 2);
      final item3 = SeenItemModel(tmdbId: 3, type: 'tv', title: 'C', seenDate: DateTime(2023, 1, 2), seasonNumber: 1, episodeNumber: 3);

      await dataSource.markAsSeen(item1);
      await dataSource.markAsSeen(item2);
      await dataSource.markAsSeen(item3);

      final items = await dataSource.getAllSeenItems();
      
      expect(items.length, 3);
      expect(items[0].seenDate, DateTime(2023, 1, 2)); // Most recent date
      expect(items[1].episodeNumber, 2); // Same date, higher episode
      expect(items[2].episodeNumber, 1);
    });

    test('should delete a specific entry by its local Isar ID', () async {
      await dataSource.markAsSeen(tSeenItem);
      var items = await dataSource.getAllSeenItems();
      final idToDelete = items.first.isarId!;

      await dataSource.deleteSeenEntry(idToDelete);
      
      items = await dataSource.getAllSeenItems();
      expect(items, isEmpty);
    });
  });

  group('MediaListLocalDataSource - Lists', () {
    test('should add an item to a list and retrieve it', () async {
      await dataSource.addToList(
        id: 1,
        type: 'movie',
        listName: 'watchlist',
        title: 'Inception',
      );

      final items = await dataSource.getListItems('watchlist');
      expect(items.length, 1);
      expect(items.first.title, 'Inception');
    });

    test('should remove an item from a list', () async {
      await dataSource.addToList(id: 1, type: 'movie', listName: 'watchlist', title: 'Inception');
      await dataSource.removeFromList(1, 'movie', 'watchlist');

      final items = await dataSource.getListItems('watchlist');
      expect(items, isEmpty);
    });
  });
}
