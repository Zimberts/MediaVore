import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
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
        LikedItemSchema,
        NotifiedItemModelSchema,
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
      final firstDate = DateTime(2023, 10, 1);
      final secondDate = DateTime(2023, 10, 2);

      await dataSource.markAsSeen(SeenItemModel(
        tmdbId: 1, type: 'movie', title: 'Dune', seenDate: firstDate,
      ));
      await dataSource.markAsSeen(SeenItemModel(
        tmdbId: 1, type: 'movie', title: 'Dune', seenDate: secondDate,
      ));

      final seenItems = await dataSource.getAllSeenItems();

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

    test('should update poster path for all entries of a specific item', () async {
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 1, type: 'movie', title: 'A', seenDate: DateTime.now()));
      await dataSource.markAsSeen(SeenItemModel(tmdbId: 1, type: 'movie', title: 'A', seenDate: DateTime.now()));

      await dataSource.updatePosterPath(1, 'movie', '/new_path.jpg');

      final items = await dataSource.getAllSeenItems();
      expect(items[0].posterPath, '/new_path.jpg');
      expect(items[1].posterPath, '/new_path.jpg');
    });
  });

  group('MediaListLocalDataSource - Lists', () {
    test('should create, list and delete user lists', () async {
      await dataSource.createList('Custom List');

      var lists = await dataSource.getAllListNames();
      expect(lists, contains('Custom List'));
      expect(lists, contains('watchlist')); // Watchlist always exists

      await dataSource.deleteList('Custom List');
      lists = await dataSource.getAllListNames();
      expect(lists, isNot(contains('Custom List')));
    });

    test('should add to list and update position', () async {
      await dataSource.addToList(id: 1, type: 'movie', listName: 'watchlist', title: 'A');
      await dataSource.addToList(id: 2, type: 'movie', listName: 'watchlist', title: 'B');

      final items = await dataSource.getListItems('watchlist');
      expect(items[0].title, 'A');
      expect(items[0].position, 0);
      expect(items[1].title, 'B');
      expect(items[1].position, 1);
    });

    test('should update list order', () async {
      await dataSource.addToList(id: 1, type: 'movie', listName: 'watchlist', title: 'A');
      await dataSource.addToList(id: 2, type: 'movie', listName: 'watchlist', title: 'B');

      await dataSource.updateListOrder('watchlist', ['2:movie', '1:movie']);

      final items = await dataSource.getListItems('watchlist');
      expect(items[0].id, 2);
      expect(items[1].id, 1);
    });
  });

  group('MediaListLocalDataSource - Likes', () {
    test('should toggle like status', () async {
      expect(await dataSource.isLiked(1, 'movie'), isFalse);

      await dataSource.toggleLike(tmdbId: 1, type: 'movie', title: 'Dune');
      expect(await dataSource.isLiked(1, 'movie'), isTrue);

      await dataSource.toggleLike(tmdbId: 1, type: 'movie', title: 'Dune');
      expect(await dataSource.isLiked(1, 'movie'), isFalse);
    });

    test('should retrieve all liked items', () async {
      await dataSource.toggleLike(tmdbId: 1, type: 'movie', title: 'A');
      await dataSource.toggleLike(tmdbId: 2, type: 'movie', title: 'B');

      final liked = await dataSource.getLikedItems();
      expect(liked.length, 2);
    });
  });

  group('MediaListLocalDataSource - Notifications', () {
    test('should toggle notification', () async {
      expect(await dataSource.isNotified(1, 'movie'), isFalse);

      await dataSource.toggleNotification(tmdbId: 1, type: 'movie', title: 'A');
      expect(await dataSource.isNotified(1, 'movie'), isTrue);

      await dataSource.toggleNotification(tmdbId: 1, type: 'movie', title: 'A');
      expect(await dataSource.isNotified(1, 'movie'), isFalse);
    });

    test('should update notification date', () async {
      final initialDate = DateTime(2023, 10, 1);
      final newDate = DateTime(2023, 10, 2);

      await dataSource.toggleNotification(tmdbId: 1, type: 'movie', title: 'A', releaseDate: initialDate);
      await dataSource.updateNotificationDate(1, 'movie', newDate);

      final notified = await dataSource.getNotifiedItems();
      expect(notified.first.releaseDate, newDate);
    });

    test('autoNotify should update release date if item already exists', () async {
       final initialDate = DateTime(2023, 10, 1);
       final newDate = DateTime(2023, 10, 2);

       await dataSource.toggleNotification(tmdbId: 1, type: 'movie', title: 'A', releaseDate: initialDate);
       // Call again with autoNotify=true
       await dataSource.toggleNotification(tmdbId: 1, type: 'movie', title: 'A', releaseDate: newDate, autoNotify: true);

       final notified = await dataSource.getNotifiedItems();
       expect(notified.first.releaseDate, newDate);
       expect(notified.length, 1); // Should not have been deleted
    });
  });
}
