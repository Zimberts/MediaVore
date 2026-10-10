import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  late String tempPath;
  int dbCounter = 0;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_cache';
    if (!Directory(tempPath).existsSync()) {
      Directory(tempPath).createSync(recursive: true);
    }
  });

  Future<Isar> openIsar() async {
    dbCounter++;
    return await Isar.open(
      [CachedMediaSchema, CachedActorProfileSchema, CachedSeasonSchema],
      directory: tempPath,
      name: 'test_cache_db_$dbCounter',
    );
  }

  const tMediaItem = MediaItem(
    id: 1,
    title: 'Inception',
    posterPath: '/path.jpg',
    overview: 'Overview...',
    releaseDate: '2010-07-16',
    mediaType: MediaType.movie,
  );

  final tMediaDetails = MediaDetails(
    item: tMediaItem,
    cast: [
      const CastMember(
        id: 10,
        name: 'Leo',
        character: 'Cobb',
        profilePath: '/leo.jpg',
      ),
    ],
    director: const CrewMember(name: 'Nolan', job: 'Director'),
  );

  group('MediaCache persistence', () {
    test('should persist and load MediaItem', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.init();

      await cache.cacheItem(tMediaItem);

      // Verification
      final result = await cache.getItem(1, MediaType.movie);
      expect(result, equals(tMediaItem));

      // Reload check
      final newCache = MediaCache(isar);
      await newCache.init();
      expect(await newCache.getItem(1, MediaType.movie), equals(tMediaItem));

      await isar.close(deleteFromDisk: true);
    });

    test('should persist and load MediaDetails', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.init();

      await cache.cacheDetails(tMediaDetails);

      final result = await cache.getDetails(1, MediaType.movie);
      expect(result?.item, equals(tMediaItem));
      expect(result?.cast.first.name, 'Leo');

      await isar.close(deleteFromDisk: true);
    });

    test('should persist and load Actor Profile', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.init();

      await cache.cacheActorProfile(10, '/leo.jpg');
      expect(await cache.getActorProfile(10), '/leo.jpg');

      await isar.close(deleteFromDisk: true);
    });

    test('should persist and load Season Data', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.init();

      final tSeasonData = {
        'episodes': [
          {'id': 1},
        ],
      };
      await cache.cacheSeason(1, 1, tSeasonData);
      expect(await cache.getSeason(1, 1), equals(tSeasonData));

      await isar.close(deleteFromDisk: true);
    });
  });

  group('MediaCache management', () {
    test(
      'getCacheSize should return a value greater than 0 after caching',
      () async {
        final isar = await openIsar();
        final cache = MediaCache(isar);
        await cache.init();

        final initialSize = await cache.getCacheSize();
        await cache.cacheItem(tMediaItem);
        final finalSize = await cache.getCacheSize();

        expect(finalSize, greaterThan(initialSize));
        await isar.close(deleteFromDisk: true);
      },
    );

    test('clearAll should remove everything from DB and memory', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.init();

      await cache.cacheItem(tMediaItem);
      await cache.cacheActorProfile(10, '/path');
      await cache.cacheSeason(1, 1, {});

      await cache.clearAll();

      expect(await cache.getItem(1, MediaType.movie), isNull);
      expect(await cache.getActorProfile(10), isNull);
      expect(await cache.getSeason(1, 1), isNull);

      final mediaCount = await isar.cachedMedias.count();
      expect(mediaCount, 0);
      await isar.close(deleteFromDisk: true);
    });
  });

  group('MediaCache cleanup', () {
    test('should cleanup old items not in keepKeys', () async {
      final isar = await openIsar();
      final oldThreshold = DateTime.now().subtract(const Duration(days: 70));

      await isar.writeTxn(() async {
        await isar.cachedMedias.put(
          CachedMedia(
            tmdbId: 1,
            type: 'movie',
            mediaItemJson: jsonEncode(tMediaItem.toJson()),
            updatedAt: oldThreshold,
          ),
        );
        await isar.cachedMedias.put(
          CachedMedia(
            tmdbId: 2,
            type: 'movie',
            mediaItemJson: jsonEncode(tMediaItem.toJson()),
            updatedAt: oldThreshold,
          ),
        );
      });

      final cache = MediaCache(isar);
      await cache.init();

      await cache.cleanup(
        keepKeys: {'movie:1'},
        olderThan: const Duration(days: 60),
      );

      expect(await cache.getItem(1, MediaType.movie), isNotNull);
      expect(await cache.getItem(2, MediaType.movie), isNull);
      await isar.close(deleteFromDisk: true);
    });

    test('should not cleanup recent items even if not in keepKeys', () async {
      final isar = await openIsar();
      final recent = DateTime.now().subtract(const Duration(days: 10));

      await isar.writeTxn(() async {
        await isar.cachedMedias.put(
          CachedMedia(
            tmdbId: 3,
            type: 'movie',
            mediaItemJson: jsonEncode(tMediaItem.toJson()),
            updatedAt: recent,
          ),
        );
      });

      final cache = MediaCache(isar);
      await cache.init();

      await cache.cleanup(keepKeys: {}, olderThan: const Duration(days: 60));

      expect(await cache.getItem(3, MediaType.movie), isNotNull);
      await isar.close(deleteFromDisk: true);
    });

    test('should cleanup seasons correctly', () async {
      final isar = await openIsar();
      final oldThreshold = DateTime.now().subtract(const Duration(days: 70));
      await isar.writeTxn(() async {
        await isar.cachedSeasons.put(
          CachedSeason(
            tvId: 100,
            seasonNumber: 1,
            json: '{}',
            updatedAt: oldThreshold,
          ),
        );
      });

      final cache = MediaCache(isar);
      await cache.init();

      await cache.cleanup(keepKeys: {}, olderThan: const Duration(days: 60));

      expect(await cache.getSeason(100, 1), isNull);
      await isar.close(deleteFromDisk: true);
    });

    test(
      'should not empty cache if item is in keepKeys even if very old',
      () async {
        final isar = await openIsar();
        final veryOld = DateTime.now().subtract(const Duration(days: 365));
        await isar.writeTxn(() async {
          await isar.cachedMedias.put(
            CachedMedia(
              tmdbId: 99,
              type: 'movie',
              mediaItemJson: jsonEncode(tMediaItem.toJson()),
              updatedAt: veryOld,
            ),
          );
        });

        final cache = MediaCache(isar);
        await cache.init();

        await cache.cleanup(
          keepKeys: {'movie:99'},
          olderThan: const Duration(days: 30),
        );

        expect(await cache.getItem(99, MediaType.movie), isNotNull);
        await isar.close(deleteFromDisk: true);
      },
    );
  });

  group('MediaCache lazy loading', () {
    test('should read entries from Isar on demand without init', () async {
      final isar = await openIsar();
      await isar.writeTxn(() async {
        await isar.cachedMedias.put(
          CachedMedia(
            tmdbId: 1,
            type: 'movie',
            mediaItemJson: jsonEncode(tMediaItem.toJson()),
            mediaDetailsJson: jsonEncode(tMediaDetails.toJson()),
            updatedAt: DateTime.now(),
          ),
        );
        await isar.cachedSeasons.put(
          CachedSeason(
            tvId: 5,
            seasonNumber: 2,
            json: '{"episodes":[]}',
            updatedAt: DateTime.now(),
          ),
        );
      });

      final cache = MediaCache(isar);

      expect(await cache.getItem(1, MediaType.movie), equals(tMediaItem));
      expect((await cache.getDetails(1, MediaType.movie))?.cast.first.id, 10);
      expect(await cache.getSeason(5, 2), equals({'episodes': []}));
      expect(await cache.getItem(1, MediaType.tv), isNull);
      await isar.close(deleteFromDisk: true);
    });

    test('getItems should return results aligned with the keys', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      const tv = MediaItem(
        id: 2,
        title: 'Show',
        overview: '',
        releaseDate: '',
        mediaType: MediaType.tv,
      );
      await cache.cacheItems([tMediaItem, tv]);

      // Fresh instance: everything comes from Isar in one batch.
      final reloaded = MediaCache(isar);
      final result = await reloaded.getItems([
        (2, MediaType.tv),
        (3, MediaType.movie),
        (1, MediaType.movie),
      ]);

      expect(result, [tv, null, tMediaItem]);
      await isar.close(deleteFromDisk: true);
    });

    test('should delete corrupted rows instead of skipping them', () async {
      final isar = await openIsar();
      await isar.writeTxn(() async {
        await isar.cachedMedias.put(
          CachedMedia(
            tmdbId: 7,
            type: 'movie',
            mediaItemJson: '{not json',
            updatedAt: DateTime.now(),
          ),
        );
      });

      final cache = MediaCache(isar);

      expect(await cache.getItem(7, MediaType.movie), isNull);
      expect(await isar.cachedMedias.count(), 0);
      await isar.close(deleteFromDisk: true);
    });

    test('getCacheUpdateDate should return the stored date', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.cacheItem(tMediaItem);

      final date = await cache.getCacheUpdateDate(1, MediaType.movie);

      expect(date, isNotNull);
      expect(await cache.getCacheUpdateDate(1, MediaType.tv), isNull);
      await isar.close(deleteFromDisk: true);
    });
  });

  group('MediaCache upserts', () {
    test('should keep a single row per media across writes', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);

      await cache.cacheItem(tMediaItem);
      await cache.cacheDetails(tMediaDetails);
      await cache.cacheItems([tMediaItem, tMediaItem]);

      expect(await isar.cachedMedias.count(), 1);
      await isar.close(deleteFromDisk: true);
    });

    test('cacheItems should preserve already cached details JSON', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.cacheDetails(tMediaDetails);

      await cache.cacheItems([tMediaItem]);

      final reloaded = MediaCache(isar);
      final details = await reloaded.getDetails(1, MediaType.movie);
      expect(details?.cast.first.name, 'Leo');
      await isar.close(deleteFromDisk: true);
    });

    test('should upsert actor profiles by actorId', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);

      await cache.cacheDetails(tMediaDetails);
      await cache.cacheActorProfile(10, '/new.jpg');

      expect(await isar.cachedActorProfiles.count(), 1);
      expect(await MediaCache(isar).getActorProfile(10), '/new.jpg');
      await isar.close(deleteFromDisk: true);
    });

    test('should upsert seasons by (tvId, seasonNumber)', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);

      await cache.cacheSeason(1, 1, {'v': 1});
      await cache.cacheSeason(1, 1, {'v': 2});

      expect(await isar.cachedSeasons.count(), 1);
      expect(await MediaCache(isar).getSeason(1, 1), {'v': 2});
      await isar.close(deleteFromDisk: true);
    });
  });

  group('LruMap', () {
    test('should evict the least recently used entry', () {
      final lru = LruMap<int, String>(2)
        ..put(1, 'a')
        ..put(2, 'b');

      lru.get(1); // 2 becomes the eldest
      lru.put(3, 'c');

      expect(lru.containsKey(1), isTrue);
      expect(lru.containsKey(2), isFalse);
      expect(lru.containsKey(3), isTrue);
      expect(lru.length, 2);
    });

    test('remember should not overwrite a newer value', () {
      final lru = LruMap<int, String>(2)..put(1, 'new');

      expect(lru.remember(1, 'stale'), 'new');
      expect(lru.remember(2, 'b'), 'b');
    });
  });
}
