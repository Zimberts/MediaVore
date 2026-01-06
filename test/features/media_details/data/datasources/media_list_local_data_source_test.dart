import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
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
      [
        MediaListItemSchema, 
        UserListSchema, 
        SeenItemModelSchema,
        CachedMediaSchema,
        CachedActorProfileSchema,
        CachedSeasonSchema,
      ],
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

  group('MediaListLocalDataSource - Import & Export', () {
    test('getExportData should return filtered results by date range', () async {
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 1, type: 'movie', title: 'Old', seenDate: DateTime(2022)));
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 2, type: 'movie', title: 'Target', seenDate: DateTime(2023, 6)));
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 3, type: 'movie', title: 'New', seenDate: DateTime(2024)));

      final results = await dataSource.getExportData(
        start: DateTime(2023, 1),
        end: DateTime(2023, 12, 31),
      );

      expect(results.length, 1);
      expect(results.first.title, 'Target');
    });

    test('getExportData should return filtered results by tmdbId', () async {
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 1, type: 'movie', title: 'A', seenDate: DateTime(2023)));
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 2, type: 'movie', title: 'B', seenDate: DateTime(2023)));

      final results = await dataSource.getExportData(tmdbId: 1);

      expect(results.length, 1);
      expect(results.first.title, 'A');
    });

    test('importSeenItems - Mode REPLACE should clear existing and add new', () async {
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 1, type: 'movie', title: 'Existing', seenDate: DateTime(2023)));
      
      final newItems = [
        SeenItemModel(tmdbId: 2, type: 'movie', title: 'Imported', seenDate: DateTime(2024)),
      ];

      await dataSource.importSeenItems(newItems, mode: ImportMode.replace);

      final items = await dataSource.getAllSeenItems();
      expect(items.length, 1);
      expect(items.first.title, 'Imported');
    });

    test('importSeenItems - Mode MERGE should not add duplicates', () async {
      final date = DateTime(2023, 10, 1);
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 1, type: 'movie', title: 'A', seenDate: date));
      
      final itemsToImport = [
        SeenItemModel(tmdbId: 1, type: 'movie', title: 'A', seenDate: date), // Exact duplicate
        SeenItemModel(tmdbId: 2, type: 'movie', title: 'B', seenDate: date), // New item
      ];

      await dataSource.importSeenItems(itemsToImport, mode: ImportMode.merge);

      final items = await dataSource.getAllSeenItems();
      expect(items.length, 2); // 'A' was merged, 'B' was added
    });
  });

  group('MediaListLocalDataSource - Seen DB Size', () {
    test('getSeenDbSize should only include seen history and ignore lists or cache', () async {
      // 1. Initial size (may not be 0 due to file metadata, but should be small)
      final initialSize = await dataSource.getSeenDbSize();
      
      // 2. Add seen item
      await dataSource.markAsSeen(SeenItemModel(
        tmdbId: 1, type: 'movie', title: 'Seen', seenDate: DateTime.now(),
      ));
      final sizeAfterSeen = await dataSource.getSeenDbSize();
      expect(sizeAfterSeen, greaterThan(initialSize));

      // 3. Add list item
      await dataSource.addToList(id: 1, type: 'movie', listName: 'L', title: 'List');
      final sizeAfterList = await dataSource.getSeenDbSize();
      // Should remain exactly the same as only seenItemModels are counted
      expect(sizeAfterList, equals(sizeAfterSeen));

      // 4. Add user list
      await isar.writeTxn(() => isar.userLists.put(UserList(name: 'My New List')));
      final sizeAfterUserList = await dataSource.getSeenDbSize();
      expect(sizeAfterUserList, equals(sizeAfterSeen));

      // 5. Add cached item
      await isar.writeTxn(() async {
        await isar.cachedMedias.put(CachedMedia(
          tmdbId: 1, 
          type: 'movie', 
          updatedAt: DateTime.now(),
          mediaItemJson: '{"huge":"json_data_to_increase_actual_file_size"}',
        ));
      });
      final sizeAfterCache = await dataSource.getSeenDbSize();
      // Should still remain the same
      expect(sizeAfterCache, equals(sizeAfterSeen));
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
