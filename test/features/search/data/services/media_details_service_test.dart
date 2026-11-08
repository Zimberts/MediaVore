import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRemoteDataSource remote;
  late MockMediaCache cache;
  late MediaDetailsService service;

  const movie = MediaItem(
    id: 1,
    title: 'Movie',
    overview: '',
    releaseDate: '2020-01-01',
    runtime: 120,
    genres: ['Drama'],
  );
  const show = MediaItem(
    id: 2,
    title: 'Show',
    overview: '',
    releaseDate: '2020-01-01',
    mediaType: MediaType.tv,
    genres: ['Comedy'],
  );

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(MediaDetails(item: movie, cast: const []));
  });

  setUp(() {
    remote = MockMediaRemoteDataSource();
    cache = MockMediaCache();
    service = MediaDetailsService(remoteDataSource: remote, cache: cache);

    when(() => cache.getDetails(any(), any())).thenAnswer((_) async => null);
    when(() => cache.cacheDetails(any())).thenAnswer((_) async {});
    when(() => cache.cacheSeason(any(), any(), any())).thenAnswer((_) async {});
    when(() => cache.getItem(any(), any())).thenAnswer((_) async => null);
    when(
      () => cache.getSeasonUpdateDate(any(), any()),
    ).thenAnswer((_) async => null);
    when(
      () => remote.getMediaCredits(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => {'cast': [], 'crew': []});
    when(
      () => remote.getSimilarMedia(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => remote.getRecommendedMedia(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => remote.getWatchProviders(any(), any()),
    ).thenAnswer((_) async => {});
    when(() => remote.getVideos(any(), any())).thenAnswer((_) async => []);
  });

  group('getMediaDetails', () {
    test('should share one fetch between concurrent callers', () async {
      final item = Completer<MediaItem>();
      when(
        () => remote.getMediaItem(1, type: MediaType.movie),
      ).thenAnswer((_) => item.future);

      final first = service.getMediaDetails(1);
      final second = service.getMediaDetails(1);
      item.complete(movie);

      expect((await first).item, movie);
      expect((await second).item, movie);
      verify(() => remote.getMediaItem(1, type: MediaType.movie)).called(1);
      verify(() => cache.cacheDetails(any())).called(1);
    });

    test('should fetch again once the previous request settled', () async {
      when(
        () => remote.getMediaItem(1, type: MediaType.movie),
      ).thenAnswer((_) async => movie);

      await service.getMediaDetails(1);
      await service.getMediaDetails(1);

      verify(() => remote.getMediaItem(1, type: MediaType.movie)).called(2);
    });
  });

  group('getSeasonDetails', () {
    test('should return the cached season without a network call', () async {
      when(
        () => cache.getSeason(2, 1),
      ).thenAnswer((_) async => {'episodes': <dynamic>[]});

      expect(await service.getSeasonDetails(2, 1), {'episodes': <dynamic>[]});
      verifyNever(() => remote.getSeasonDetails(any(), any()));
    });

    test('should rethrow a network error when nothing is cached', () async {
      when(() => cache.getSeason(2, 1)).thenAnswer((_) async => null);
      when(() => remote.getSeasonDetails(2, 1)).thenThrow(Exception('offline'));

      expect(() => service.getSeasonDetails(2, 1), throwsException);
    });

    test(
      'should fall back to a season cached meanwhile on network error',
      () async {
        var reads = 0;
        when(
          () => cache.getSeason(2, 1),
        ).thenAnswer((_) async => reads++ == 0 ? null : {'episodes': 'late'});
        when(
          () => remote.getSeasonDetails(2, 1),
        ).thenThrow(Exception('offline'));

        expect(await service.getSeasonDetails(2, 1), {'episodes': 'late'});
      },
    );
  });

  group('getSeasonDetails (ongoing series TTL)', () {
    const staleData = {
      'episodes': [
        {'episode_number': 1},
      ],
    };
    const freshData = {
      'episodes': [
        {'episode_number': 1},
        {'episode_number': 2},
      ],
    };

    MediaItem tv(String status) => MediaItem(
      id: 2,
      title: 'Show',
      overview: '',
      releaseDate: '2020-01-01',
      mediaType: MediaType.tv,
      status: status,
    );

    void stubCachedSeason({required String status, required Duration age}) {
      when(() => cache.getSeason(2, 1)).thenAnswer((_) async => staleData);
      when(
        () => cache.getItem(2, MediaType.tv),
      ).thenAnswer((_) async => tv(status));
      when(
        () => cache.getSeasonUpdateDate(2, 1),
      ).thenAnswer((_) async => DateTime.now().subtract(age));
    }

    test('should re-fetch a day-old season of a returning series', () async {
      stubCachedSeason(
        status: 'Returning Series',
        age: const Duration(days: 2),
      );
      when(
        () => remote.getSeasonDetails(2, 1),
      ).thenAnswer((_) async => freshData);

      expect(await service.getSeasonDetails(2, 1), freshData);
      verify(() => cache.cacheSeason(2, 1, freshData)).called(1);
    });

    test(
      'should use a recent season of a returning series from cache',
      () async {
        stubCachedSeason(
          status: 'Returning Series',
          age: const Duration(hours: 2),
        );

        expect(await service.getSeasonDetails(2, 1), staleData);
        verifyNever(() => remote.getSeasonDetails(any(), any()));
      },
    );

    test('should never expire seasons of an ended series', () async {
      stubCachedSeason(status: 'Ended', age: const Duration(days: 90));

      expect(await service.getSeasonDetails(2, 1), staleData);
      verifyNever(() => remote.getSeasonDetails(any(), any()));
    });

    test('should fall back to the stale copy when the network fails', () async {
      stubCachedSeason(
        status: 'Returning Series',
        age: const Duration(days: 2),
      );
      when(() => remote.getSeasonDetails(2, 1)).thenThrow(Exception('offline'));

      expect(await service.getSeasonDetails(2, 1), staleData);
    });
  });

  group('seasonDetailsForRefresh', () {
    test('should read through the cache when not forced', () async {
      when(
        () => cache.getSeason(2, 1),
      ).thenAnswer((_) async => {'episodes': 'cached'});

      final data = await service.seasonDetailsForRefresh(
        2,
        1,
        forceRemote: false,
      );

      expect(data, {'episodes': 'cached'});
      verifyNever(() => remote.getSeasonDetails(any(), any()));
    });

    test('should fetch and cache the season when forced', () async {
      when(
        () => remote.getSeasonDetails(2, 1),
      ).thenAnswer((_) async => {'episodes': 'fresh'});

      final data = await service.seasonDetailsForRefresh(
        2,
        1,
        forceRemote: true,
      );

      expect(data, {'episodes': 'fresh'});
      verifyNever(() => cache.getSeason(any(), any()));
      verify(() => cache.cacheSeason(2, 1, {'episodes': 'fresh'})).called(1);
    });
  });

  // Episode lists are `List<dynamic>`, as decoded TMDB JSON is.
  group('resolveRuntimeAndGenres', () {
    test('should not look anything up when both values are known', () async {
      final result = await service.resolveRuntimeAndGenres(
        tmdbId: 1,
        type: MediaType.movie,
        runtime: 90,
        genres: const ['Horror'],
      );

      expect(result.runtime, 90);
      expect(result.genres, ['Horror']);
      verifyNever(() => remote.getMediaItem(any(), type: any(named: 'type')));
    });

    test('should take runtime and genres from the movie details', () async {
      when(
        () => remote.getMediaItem(1, type: MediaType.movie),
      ).thenAnswer((_) async => movie);

      final result = await service.resolveRuntimeAndGenres(
        tmdbId: 1,
        type: MediaType.movie,
      );

      expect(result.runtime, 120);
      expect(result.genres, ['Drama']);
    });

    test('should take the episode runtime for a TV episode', () async {
      when(
        () => remote.getMediaItem(2, type: MediaType.tv),
      ).thenAnswer((_) async => show);
      when(() => cache.getSeason(2, 1)).thenAnswer(
        (_) async => {
          'episodes': <dynamic>[
            {'episode_number': 1, 'runtime': 25},
            {'episode_number': 2, 'runtime': 31},
          ],
        },
      );

      final result = await service.resolveRuntimeAndGenres(
        tmdbId: 2,
        type: MediaType.tv,
        seasonNumber: 1,
        episodeNumber: 2,
      );

      expect(result.runtime, 31);
      expect(result.genres, ['Comedy']);
    });

    test('should keep the given values when the lookup fails', () async {
      when(
        () => remote.getMediaItem(1, type: MediaType.movie),
      ).thenThrow(Exception('offline'));

      final result = await service.resolveRuntimeAndGenres(
        tmdbId: 1,
        type: MediaType.movie,
        genres: const ['Kept'],
      );

      expect(result.runtime, isNull);
      expect(result.genres, ['Kept']);
    });

    test('should use the injected lookups instead of the defaults', () async {
      final result = await service.resolveRuntimeAndGenres(
        tmdbId: 2,
        type: MediaType.tv,
        seasonNumber: 1,
        episodeNumber: 1,
        fetchDetails: (_, _) async => MediaDetails(item: show, cast: const []),
        fetchSeason: (_, _) async => {
          'episodes': <dynamic>[
            {'episode_number': 1, 'runtime': 22},
          ],
        },
      );

      expect(result.runtime, 22);
      expect(result.genres, ['Comedy']);
      verifyNever(() => remote.getMediaItem(any(), type: any(named: 'type')));
      verifyNever(() => cache.getSeason(any(), any()));
    });
  });
}
