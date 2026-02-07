import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
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
      final result = cache.getItem(1, MediaType.movie);
      expect(result, equals(tMediaItem));

      // Reload check
      final newCache = MediaCache(isar);
      await newCache.init();
      expect(newCache.getItem(1, MediaType.movie), equals(tMediaItem));

      await isar.close(deleteFromDisk: true);
    });

    test('should persist and load MediaDetails', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.init();

      await cache.cacheDetails(tMediaDetails);

      final result = cache.getDetails(1, MediaType.movie);
      expect(result?.item, equals(tMediaItem));
      expect(result?.cast.first.name, 'Leo');

      await isar.close(deleteFromDisk: true);
    });

    test('should persist and load Actor Profile', () async {
      final isar = await openIsar();
      final cache = MediaCache(isar);
      await cache.init();

      await cache.cacheActorProfile(10, '/leo.jpg');
      expect(cache.getActorProfile(10), '/leo.jpg');

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
      expect(cache.getSeason(1, 1), equals(tSeasonData));

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

      expect(cache.getItem(1, MediaType.movie), isNull);
      expect(cache.getActorProfile(10), isNull);
      expect(cache.getSeason(1, 1), isNull);

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

      expect(cache.getItem(1, MediaType.movie), isNotNull);
      expect(cache.getItem(2, MediaType.movie), isNull);
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

      expect(cache.getItem(3, MediaType.movie), isNotNull);
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

      expect(cache.getSeason(100, 1), isNull);
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

        expect(cache.getItem(99, MediaType.movie), isNotNull);
        await isar.close(deleteFromDisk: true);
      },
    );
  });
}
