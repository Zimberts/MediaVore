import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/services/cache_warmup_service.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/next_episode_scanner.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';
import 'package:mediavore/features/search/data/services/quick_add_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRemoteDataSource remote;
  late MockMediaListLocalDataSource local;
  late MockMediaCache cache;
  late CacheWarmupService warmup;

  /// Holds every run at its first step until completed.
  late Completer<List<String>> listNames;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      MediaDetails(
        item: const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
        cast: const [],
      ),
    );
  });

  setUp(() {
    remote = MockMediaRemoteDataSource();
    local = MockMediaListLocalDataSource();
    cache = MockMediaCache();

    final details = MediaDetailsService(remoteDataSource: remote, cache: cache);
    final scanner = NextEpisodeScanner(details);
    final quickAdd = QuickAddService(
      remoteDataSource: remote,
      localDataSource: local,
      cache: cache,
      details: details,
      scanner: scanner,
    );
    warmup = CacheWarmupService(
      localDataSource: local,
      cache: cache,
      details: details,
      notifications: NotificationRefreshService(
        remoteDataSource: remote,
        localDataSource: local,
        cache: cache,
        details: details,
        scanner: scanner,
        quickAdd: quickAdd,
      ),
    );

    listNames = Completer<List<String>>();
    when(() => local.getAllListNames()).thenAnswer((_) => listNames.future);
    when(() => local.getAllSeenItems()).thenAnswer((_) async => []);
    when(() => local.getLikedItems()).thenAnswer((_) async => []);
    when(() => local.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => cache.cacheDetails(any())).thenAnswer((_) async {});
    when(
      () => cache.cleanup(
        keepKeys: any(named: 'keepKeys'),
        olderThan: any(named: 'olderThan'),
      ),
    ).thenAnswer((_) async {});
  });

  group('CacheWarmupService.run', () {
    test('should skip the run without a TMDB credential', () async {
      final noCredential = CacheWarmupService(
        localDataSource: warmup.localDataSource,
        cache: cache,
        details: warmup.details,
        notifications: warmup.notifications,
        hasCredential: () => false,
      );

      expect(await noCredential.run(), isFalse);
      verifyNever(() => local.getAllListNames());
      verifyNever(
        () => cache.cleanup(
          keepKeys: any(named: 'keepKeys'),
          olderThan: any(named: 'olderThan'),
        ),
      );
    });

    test('should complete a run and clean up unused entries', () async {
      listNames.complete([]);

      expect(await warmup.run(), isTrue);
      verify(
        () => cache.cleanup(
          keepKeys: <String>{},
          olderThan: const Duration(days: 60),
        ),
      ).called(1);
    });

    test('should let a concurrent caller join the live run', () async {
      final first = warmup.run();
      final second = warmup.run();
      listNames.complete([]);

      expect(await first, isTrue);
      expect(await second, isFalse);
      verify(() => local.getAllListNames()).called(1);
    });

    test('should report progress per title, then clear it', () async {
      final items = [
        for (var i = 0; i < 3; i++)
          MediaListItem(id: i, type: 'movie', title: 'M$i'),
      ];
      when(
        () => local.getListItems('watchlist'),
      ).thenAnswer((_) async => items);
      when(() => cache.getDetails(any(), MediaType.movie)).thenAnswer((
        invocation,
      ) async {
        final id = invocation.positionalArguments[0] as int;
        return MediaDetails(
          item: MediaItem(id: id, title: 'M$id', overview: '', releaseDate: ''),
          cast: const [],
        );
      });
      final seen = <CacheWarmupProgress?>[];
      warmup.progress.addListener(() => seen.add(warmup.progress.value));
      listNames.complete(['watchlist']);

      expect(await warmup.run(), isTrue);
      expect(seen, const [
        CacheWarmupProgress(0, 3),
        CacheWarmupProgress(1, 3),
        CacheWarmupProgress(2, 3),
        CacheWarmupProgress(3, 3),
        null,
      ]);
    });

    test('should stop between titles when cancelled mid-run', () async {
      final items = [
        for (var i = 0; i < 20; i++)
          MediaListItem(id: i, type: 'movie', title: 'M$i'),
      ];
      when(
        () => local.getListItems('watchlist'),
      ).thenAnswer((_) async => items);
      when(() => cache.getDetails(any(), MediaType.movie)).thenAnswer((
        invocation,
      ) async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        final id = invocation.positionalArguments[0] as int;
        return MediaDetails(
          item: MediaItem(id: id, title: 'M$id', overview: '', releaseDate: ''),
          cast: const [],
        );
      });
      warmup.progress.addListener(() {
        if (warmup.progress.value?.done == 1) warmup.cancel();
      });
      listNames.complete(['watchlist']);

      expect(await warmup.run(), isFalse);
      expect(warmup.progress.value, isNull);
      // Only the titles already in flight when cancelled are finished.
      verify(
        () => cache.getDetails(any(), MediaType.movie),
      ).called(lessThanOrEqualTo(CacheWarmupService.concurrency));
      verifyNever(
        () => cache.cleanup(
          keepKeys: any(named: 'keepKeys'),
          olderThan: any(named: 'olderThan'),
        ),
      );
    });

    test('should refresh a title found in several sources once', () async {
      const show = MediaItem(
        id: 5,
        title: 'Show',
        overview: '',
        releaseDate: '',
        mediaType: MediaType.tv,
        seasons: [
          TVSeason(id: 1, seasonNumber: 1, episodeCount: 2),
          TVSeason(id: 2, seasonNumber: 2, episodeCount: 2),
        ],
      );
      final recent = DateTime.now().subtract(const Duration(days: 1));
      when(() => local.getListItems('watchlist')).thenAnswer(
        (_) async => [MediaListItem(id: 5, type: 'tv', title: 'Show')],
      );
      when(() => local.getAllSeenItems()).thenAnswer(
        (_) async => [
          for (var e = 1; e <= 3; e++)
            SeenItemModel(
              tmdbId: 5,
              type: 'tv',
              title: 'Show',
              posterPath: '/p.jpg',
              seenDate: recent,
              seasonNumber: 2,
              episodeNumber: e,
            ),
        ],
      );
      when(() => local.getLikedItems()).thenAnswer(
        (_) async => [LikedItem(tmdbId: 5, type: 'tv', title: 'Show')],
      );
      when(
        () => cache.getDetails(5, MediaType.tv),
      ).thenAnswer((_) async => MediaDetails(item: show, cast: const []));
      when(() => cache.getSeason(5, any())).thenAnswer((_) async => null);
      when(() => cache.getItem(5, MediaType.tv)).thenAnswer((_) async => null);
      when(
        () => cache.cacheSeason(any(), any(), any()),
      ).thenAnswer((_) async {});
      when(() => remote.getSeasonsDetails(5, any())).thenAnswer(
        (_) async => {
          1: {'season_number': 1},
          2: {'season_number': 2},
        },
      );
      listNames.complete(['watchlist']);

      expect(await warmup.run(), isTrue);
      verify(() => cache.getDetails(5, MediaType.tv)).called(1);
      verify(() => remote.getSeasonsDetails(5, [1, 2])).called(1);
    });

    test('should refresh at most `concurrency` titles at a time', () async {
      final items = [
        for (var i = 0; i < 20; i++)
          MediaListItem(id: i, type: 'movie', title: 'M$i'),
      ];
      when(
        () => local.getListItems('watchlist'),
      ).thenAnswer((_) async => items);
      var inFlight = 0;
      var maxInFlight = 0;
      when(() => cache.getDetails(any(), MediaType.movie)).thenAnswer((
        invocation,
      ) async {
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        inFlight--;
        final id = invocation.positionalArguments[0] as int;
        return MediaDetails(
          item: MediaItem(id: id, title: 'M$id', overview: '', releaseDate: ''),
          cast: const [],
        );
      });
      listNames.complete(['watchlist']);

      expect(await warmup.run(), isTrue);
      expect(maxInFlight, CacheWarmupService.concurrency);
      verify(() => cache.getDetails(any(), MediaType.movie)).called(20);
    });

    test('should start afresh after waiting out a cancelled run', () async {
      final cancelled = warmup.run();
      warmup.cancel();
      final restarted = warmup.run();
      listNames.complete([]);

      expect(await cancelled, isFalse);
      expect(await restarted, isTrue);
      verify(() => local.getAllListNames()).called(2);
    });

    test('should refresh saved items and keep them in the cache', () async {
      const show = MediaItem(
        id: 5,
        title: 'Show',
        overview: '',
        releaseDate: '',
        mediaType: MediaType.tv,
        seasons: [TVSeason(id: 1, seasonNumber: 1, episodeCount: 2)],
      );
      when(() => local.getListItems('watchlist')).thenAnswer(
        (_) async => [MediaListItem(id: 5, type: 'tv', title: 'Show')],
      );
      when(
        () => cache.getDetails(5, MediaType.tv),
      ).thenAnswer((_) async => MediaDetails(item: show, cast: const []));
      when(
        () => cache.getSeason(5, 1),
      ).thenAnswer((_) async => {'episodes': <dynamic>[]});
      listNames.complete(['watchlist']);

      expect(await warmup.run(), isTrue);
      verify(() => cache.getSeason(5, 1)).called(1);
      verify(
        () => cache.cleanup(
          keepKeys: {'tv:5'},
          olderThan: const Duration(days: 60),
        ),
      ).called(1);
    });

    test(
      'should keep all seen items in cache even if older than 30 days with poster',
      () async {
        final oldSeen = SeenItemModel(
          tmdbId: 42,
          type: 'movie',
          title: 'Old Seen Movie',
          posterPath: '/poster.jpg',
          seenDate: DateTime.now().subtract(const Duration(days: 90)),
        );
        when(() => local.getAllSeenItems()).thenAnswer((_) async => [oldSeen]);
        const completeMovie = MediaItem(
          id: 42,
          title: 'Old Seen Movie',
          overview: '',
          releaseDate: '2020-01-01',
          originCountries: ['US'],
          voteCount: 100,
          originalLanguage: 'en',
        );
        when(() => cache.getDetails(42, MediaType.movie)).thenAnswer(
          (_) async => MediaDetails(item: completeMovie, cast: const []),
        );
        listNames.complete([]);

        expect(await warmup.run(), isTrue);
        verify(
          () => cache.cleanup(
            keepKeys: {'movie:42'},
            olderThan: const Duration(days: 60),
          ),
        ).called(1);
        verifyNever(() => remote.getMediaDetailsBundle(42));
      },
    );

    test(
      'should refetch incomplete cached details for older seen titles',
      () async {
        final oldSeen = SeenItemModel(
          tmdbId: 42,
          type: 'movie',
          title: 'Pre v1.3.0 Movie',
          posterPath: '/poster.jpg',
          seenDate: DateTime.now().subtract(const Duration(days: 90)),
        );
        when(() => local.getAllSeenItems()).thenAnswer((_) async => [oldSeen]);
        const incompleteMovie = MediaItem(
          id: 42,
          title: 'Pre v1.3.0 Movie',
          overview: '',
          releaseDate: '2020-01-01',
          // originCountries, voteCount, originalLanguage are null
        );
        const freshMovie = MediaItem(
          id: 42,
          title: 'Pre v1.3.0 Movie',
          overview: '',
          releaseDate: '2020-01-01',
          originCountries: ['FR'],
          voteCount: 50,
          originalLanguage: 'fr',
        );
        when(() => cache.getDetails(42, MediaType.movie)).thenAnswer(
          (_) async => MediaDetails(item: incompleteMovie, cast: const []),
        );
        when(
          () => remote.getMediaDetailsBundle(42),
        ).thenAnswer((_) async => bundleOf(freshMovie));
        listNames.complete([]);

        expect(await warmup.run(), isTrue);
        verify(() => remote.getMediaDetailsBundle(42)).called(1);
        verify(() => cache.cacheDetails(any())).called(1);
      },
    );
  });
}
