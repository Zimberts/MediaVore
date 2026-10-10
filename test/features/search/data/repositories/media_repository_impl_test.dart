import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MediaRepositoryImpl repository;
  late MockMediaRemoteDataSource mockRemoteDataSource;
  late MockMediaListLocalDataSource mockLocalDataSource;
  late MockMediaCache mockCache;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(<MediaItem>[]);
    registerFallbackValue(<(int, MediaType)>[]);
    registerFallbackValue(
      SeenItemModel(
        tmdbId: 1,
        type: 'movie',
        title: 'T',
        seenDate: DateTime(2000),
      ),
    );
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
    registerFallbackValue(
      MediaDetails(
        item: const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
        cast: const [],
      ),
    );
    registerFallbackValue(Duration.zero);
    registerFallbackValue(ImportMode.append);
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(
      QuickAddItemModel(tmdbId: 1, type: 'tv', insertedAt: DateTime(2000)),
    );
  });

  setUp(() async {
    mockRemoteDataSource = MockMediaRemoteDataSource();
    mockLocalDataSource = MockMediaListLocalDataSource();
    mockCache = MockMediaCache();

    // Mock cache and data source setup
    when(() => mockCache.init()).thenAnswer((_) async {});
    when(
      () => mockCache.cleanup(
        keepKeys: any(named: 'keepKeys'),
        olderThan: any(named: 'olderThan'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockCache.cacheItem(any())).thenAnswer((_) async {});
    when(() => mockCache.cacheDetails(any())).thenAnswer((_) async {});
    when(
      () => mockCache.cacheActorProfile(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockCache.clearAll()).thenAnswer((_) async {});
    when(() => mockCache.getCacheSize()).thenAnswer((_) async => 1024);
    when(
      () => mockCache.cacheSeason(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockCache.getItem(any(), any())).thenAnswer((_) async => null);
    when(() => mockCache.cacheItems(any())).thenAnswer((_) async {});
    when(() => mockCache.getItems(any())).thenAnswer(
      (inv) async => List<MediaItem?>.filled(
        (inv.positionalArguments.first as List).length,
        null,
      ),
    );
    when(
      () => mockCache.getDetails(any(), any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockCache.getSeason(any(), any()),
    ).thenAnswer((_) async => null);

    when(
      () => mockLocalDataSource.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockLocalDataSource.getListItems(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockLocalDataSource.getAllSeenItems(),
    ).thenAnswer((_) async => []);
    when(() => mockLocalDataSource.getLikedItems()).thenAnswer((_) async => []);
    when(
      () => mockLocalDataSource.getNotifiedItems(),
    ).thenAnswer((_) async => []);
    when(
      () => mockLocalDataSource.isNotified(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockLocalDataSource.toggleNotification(
        tmdbId: any(named: 'tmdbId'),
        type: any(named: 'type'),
        title: any(named: 'title'),
        posterPath: any(named: 'posterPath'),
        releaseDate: any(named: 'releaseDate'),
        seasonNumber: any(named: 'seasonNumber'),
        episodeNumber: any(named: 'episodeNumber'),
        autoNotify: any(named: 'autoNotify'),
      ),
    ).thenAnswer((_) async => Future.value());

    repository = MediaRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      cache: mockCache,
    );

    // Wait for the background initialization to complete
    await repository.getAllListNames();

    clearInteractions(mockRemoteDataSource);
    clearInteractions(mockLocalDataSource);
    clearInteractions(mockCache);
  });

  const tMediaItem = MediaItem(
    id: 1,
    title: 'Inception',
    posterPath: '/path.jpg',
    overview: 'Overview...',
    releaseDate: '2010-07-16',
    mediaType: MediaType.movie,
  );

  group('searchMedia with Filters', () {
    const tQuery = 'Batman';
    final tMediaItems = [tMediaItem];

    test(
      'should return list of media items and pass filters to remote data source',
      () async {
        when(
          () => mockRemoteDataSource.searchMedia(
            tQuery,
            page: 1,
            genreIds: [28],
            releaseYear: 2022,
            minRating: 7.0,
            type: MediaType.movie,
          ),
        ).thenAnswer((_) async => tMediaItems);

        final result = await repository.searchMedia(
          tQuery,
          genreIds: [28],
          releaseYear: 2022,
          minRating: 7.0,
          type: MediaType.movie,
        );

        expect(result, equals(tMediaItems));
        verify(
          () => mockRemoteDataSource.searchMedia(
            tQuery,
            page: 1,
            genreIds: [28],
            releaseYear: 2022,
            minRating: 7.0,
            type: MediaType.movie,
          ),
        ).called(1);
      },
    );
  });

  group('discoverMedia', () {
    final tMediaItems = [tMediaItem];

    test('should return list of media items from discovery endpoint', () async {
      when(
        () => mockRemoteDataSource.discoverMedia(
          page: 1,
          type: MediaType.movie,
          genreIds: [28],
        ),
      ).thenAnswer((_) async => tMediaItems);

      final result = await repository.discoverMedia(
        genreIds: [28],
        type: MediaType.movie,
      );

      expect(result, equals(tMediaItems));
      verify(
        () => mockRemoteDataSource.discoverMedia(
          page: 1,
          type: MediaType.movie,
          genreIds: [28],
        ),
      ).called(1);
    });
  });

  group('searchMedia / discoverMedia error propagation', () {
    test('should rethrow ConfigurationException from searchMedia', () async {
      when(
        () => mockRemoteDataSource.searchMedia(any(), page: any(named: 'page')),
      ).thenThrow(const ConfigurationException('missing key'));

      await expectLater(
        repository.searchMedia('Batman'),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('should rethrow NetworkException from discoverMedia', () async {
      when(
        () => mockRemoteDataSource.discoverMedia(
          page: any(named: 'page'),
          type: any(named: 'type'),
        ),
      ).thenThrow(const NetworkException('offline'));

      await expectLater(
        repository.discoverMedia(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should rethrow ServerException (401) from discoverMedia', () async {
      when(
        () => mockRemoteDataSource.discoverMedia(
          page: any(named: 'page'),
          type: any(named: 'type'),
        ),
      ).thenThrow(const ServerException('unauthorized', 401));

      await expectLater(
        repository.discoverMedia(),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'code', 401),
        ),
      );
    });

    test('should still return results when caching fails', () async {
      when(
        () => mockRemoteDataSource.searchMedia(any(), page: any(named: 'page')),
      ).thenAnswer((_) async => [tMediaItem]);
      when(() => mockCache.cacheItem(any())).thenThrow(Exception('disk full'));

      final result = await repository.searchMedia('Inception');

      expect(result, equals([tMediaItem]));
    });
  });

  group('getMediaDetails Enrichment', () {
    const tId = 1;

    test(
      'should fetch and cache media details including similar, recommended, providers, and videos',
      () async {
        when(
          () =>
              mockRemoteDataSource.getMediaItem(tId, type: any(named: 'type')),
        ).thenAnswer((_) async => tMediaItem);
        when(
          () => mockRemoteDataSource.getMediaCredits(
            tId,
            type: any(named: 'type'),
          ),
        ).thenAnswer(
          (_) async => {
            'cast': [
              {
                'id': 1,
                'name': 'Leonardo DiCaprio',
                'character': 'Cobb',
                'profile_path': '/leo.jpg',
              },
            ],
            'crew': [
              {'name': 'Christopher Nolan', 'job': 'Director'},
            ],
          },
        );
        when(
          () => mockRemoteDataSource.getSimilarMedia(tId, any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockRemoteDataSource.getRecommendedMedia(tId, any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockRemoteDataSource.getWatchProviders(tId, any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockRemoteDataSource.getVideos(tId, any()),
        ).thenAnswer((_) async => []);

        final result = await repository.getMediaDetails(tId);

        expect(result.item, equals(tMediaItem));
        expect(result.similar, isNotNull);
        expect(result.recommendations, isNotNull);
        expect(result.watchProviders, isNotNull);
        expect(result.videos, isNotNull);

        verify(
          () => mockRemoteDataSource.getSimilarMedia(tId, any()),
        ).called(1);
        verify(
          () => mockRemoteDataSource.getRecommendedMedia(tId, any()),
        ).called(1);
        verify(
          () => mockRemoteDataSource.getWatchProviders(tId, any()),
        ).called(1);
        verify(() => mockRemoteDataSource.getVideos(tId, any())).called(1);
        verify(() => mockCache.cacheDetails(any())).called(1);
      },
    );
  });

  group('markAsSeen', () {
    final tSeenItem = SeenItem(
      tmdbId: 1,
      type: MediaType.movie,
      title: 'Inception',
      seenDate: DateTime.now(),
    );

    test(
      'should mark as seen and remove from watchlist if it is a movie',
      () async {
        when(
          () => mockLocalDataSource.markAsSeen(any()),
        ).thenAnswer((_) async => Future.value());
        when(
          () => mockLocalDataSource.removeFromList(any(), any(), any()),
        ).thenAnswer((_) async => Future.value());
        when(() => mockCache.getItem(any(), any())).thenAnswer((_) async => tMediaItem);

        await repository.markAsSeen(tSeenItem);

        verify(() => mockLocalDataSource.markAsSeen(any())).called(1);
        verify(
          () => mockLocalDataSource.removeFromList(
            tSeenItem.tmdbId,
            'movie',
            'watchlist',
          ),
        ).called(1);
      },
    );

    test(
      'should NOT remove from watchlist if it is a TV show (episode seen)',
      () async {
        final tSeenTVItem = SeenItem(
          tmdbId: 1,
          type: MediaType.tv,
          title: 'Breaking Bad',
          seenDate: DateTime.now(),
          seasonNumber: 1,
          episodeNumber: 1,
        );
        when(
          () => mockLocalDataSource.markAsSeen(any()),
        ).thenAnswer((_) async => Future.value());
        when(() => mockCache.getItem(any(), any())).thenAnswer((_) async => null);
        when(
          () => mockRemoteDataSource.getMediaItem(any(), type: MediaType.tv),
        ).thenAnswer((_) async => tMediaItem.copyWith(mediaType: MediaType.tv));

        await repository.markAsSeen(tSeenTVItem);

        verify(() => mockLocalDataSource.markAsSeen(any())).called(1);
        verifyNever(
          () => mockLocalDataSource.removeFromList(any(), any(), 'watchlist'),
        );
      },
    );
  });

  group('Additional Enrichment Methods', () {
    test('getSimilarMedia should call remote and cache items', () async {
      when(
        () => mockRemoteDataSource.getSimilarMedia(1, MediaType.movie),
      ).thenAnswer((_) async => [tMediaItem]);

      final result = await repository.getSimilarMedia(1, MediaType.movie);

      expect(result, contains(tMediaItem));
      verify(() => mockCache.cacheItems([tMediaItem])).called(1);
    });

    test('getWatchProviders should return map from remote', () async {
      final tProviders = {
        'US': {'flatrate': []},
      };
      when(
        () => mockRemoteDataSource.getWatchProviders(1, MediaType.movie),
      ).thenAnswer((_) async => tProviders);

      final result = await repository.getWatchProviders(1, MediaType.movie);

      expect(result, equals(tProviders));
    });

    test('getVideos should return list from remote', () async {
      final tVideos = [
        {'key': 'xyz'},
      ];
      when(
        () => mockRemoteDataSource.getVideos(1, MediaType.movie),
      ).thenAnswer((_) async => tVideos);

      final result = await repository.getVideos(1, MediaType.movie);

      expect(result, equals(tVideos));
    });
  });

  group('refreshNotificationForSeries (latest streak)', () {
    MediaItem tvItem({String? status, required List<TVSeason> seasons}) {
      return MediaItem(
        id: 1,
        title: 'Show',
        overview: '',
        releaseDate: '2020-01-01',
        mediaType: MediaType.tv,
        status: status,
        seasons: seasons,
      );
    }

    Map<String, dynamic> season(List<Map<String, dynamic>> episodes) => {
      'episodes': episodes,
    };

    Map<String, dynamic> ep(int n, {String? airDate, int? runtime}) => {
      'episode_number': n,
      'air_date': airDate,
      'runtime': runtime,
    };

    SeenItemModel seen(int season, int episode, DateTime date) => SeenItemModel(
      tmdbId: 1,
      type: 'tv',
      title: 'Show',
      seenDate: date,
      seasonNumber: season,
      episodeNumber: episode,
    );

    void stubNotified({DateTime? lastRefreshedAt}) {
      when(() => mockLocalDataSource.getNotifiedItem(1, 'tv')).thenAnswer(
        (_) async => NotifiedItemModel(
          tmdbId: 1,
          type: 'tv',
          title: 'Show',
          releaseDate: DateTime(2024, 1, 1),
          seasonNumber: 4,
          episodeNumber: 5,
          lastRefreshedAt: lastRefreshedAt,
        ),
      );
      when(
        () => mockLocalDataSource.isNotified(1, 'tv'),
      ).thenAnswer((_) async => true);
      when(
        () => mockLocalDataSource.setNotificationEpisode(
          any(),
          any(),
          seasonNumber: any(named: 'seasonNumber'),
          episodeNumber: any(named: 'episodeNumber'),
          releaseDate: any(named: 'releaseDate'),
          runtime: any(named: 'runtime'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.markNotificationAsReturning(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.markNotifiedRefreshed(any(), any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockCache.getSeason(any(), any())).thenAnswer((_) async => null);
    }

    test('should point to the next episode after the latest streak', () async {
      stubNotified();
      when(
        () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
      ).thenAnswer(
        (_) async => tvItem(
          status: 'Returning Series',
          seasons: const [TVSeason(id: 4, seasonNumber: 4, episodeCount: 6)],
        ),
      );
      when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
      when(
        () => mockLocalDataSource.getSeenStatus(1, 'tv'),
      ).thenAnswer((_) async => [seen(4, 5, DateTime(2024, 5, 1))]);
      when(() => mockRemoteDataSource.getSeasonDetails(1, 4)).thenAnswer(
        (_) async => season([
          ep(5, airDate: '2024-05-01'),
          ep(6, airDate: '2024-06-08', runtime: 42),
        ]),
      );

      await repository.refreshNotificationForSeries(
        1,
        MediaType.tv,
        force: true,
      );

      final captured = verify(
        () => mockLocalDataSource.setNotificationEpisode(
          1,
          'tv',
          seasonNumber: captureAny(named: 'seasonNumber'),
          episodeNumber: captureAny(named: 'episodeNumber'),
          releaseDate: captureAny(named: 'releaseDate'),
          runtime: captureAny(named: 'runtime'),
        ),
      ).captured;
      expect(captured[0], 4);
      expect(captured[1], 6);
      expect(captured[2], DateTime(2024, 6, 8));
      expect(captured[3], 42);
    });

    test('should not look at seasons before the latest streak', () async {
      stubNotified();
      when(
        () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
      ).thenAnswer(
        (_) async => tvItem(
          seasons: const [
            TVSeason(id: 1, seasonNumber: 1, episodeCount: 2),
            TVSeason(id: 4, seasonNumber: 4, episodeCount: 6),
          ],
        ),
      );
      when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
      when(
        () => mockLocalDataSource.getSeenStatus(1, 'tv'),
      ).thenAnswer((_) async => [seen(4, 5, DateTime(2024, 5, 1))]);
      when(
        () => mockRemoteDataSource.getSeasonDetails(1, 4),
      ).thenAnswer((_) async => season([ep(6, airDate: '2024-06-08')]));

      await repository.refreshNotificationForSeries(
        1,
        MediaType.tv,
        force: true,
      );

      verifyNever(() => mockRemoteDataSource.getSeasonDetails(1, 1));
      verify(() => mockRemoteDataSource.getSeasonDetails(1, 4)).called(1);
    });

    test('should remove a finished, fully watched series', () async {
      stubNotified();
      when(
        () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
      ).thenAnswer(
        (_) async => tvItem(
          status: 'Ended',
          seasons: const [TVSeason(id: 1, seasonNumber: 1, episodeCount: 2)],
        ),
      );
      when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
      when(() => mockLocalDataSource.getSeenStatus(1, 'tv')).thenAnswer(
        (_) async => [
          seen(1, 1, DateTime(2024, 1, 1)),
          seen(1, 2, DateTime(2024, 1, 8)),
        ],
      );
      when(() => mockRemoteDataSource.getSeasonDetails(1, 1)).thenAnswer(
        (_) async => season([
          ep(1, airDate: '2024-01-01'),
          ep(2, airDate: '2024-01-08'),
        ]),
      );

      await repository.refreshNotificationForSeries(
        1,
        MediaType.tv,
        force: true,
      );

      verify(
        () => mockLocalDataSource.toggleNotification(
          tmdbId: 1,
          type: 'tv',
          title: 'Show',
        ),
      ).called(1);
    });

    test(
      'should downgrade a caught-up returning series to Returning',
      () async {
        stubNotified();
        when(
          () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
        ).thenAnswer(
          (_) async => tvItem(
            status: 'Returning Series',
            seasons: const [TVSeason(id: 1, seasonNumber: 1, episodeCount: 2)],
          ),
        );
        when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
        when(
          () => mockLocalDataSource.getSeenStatus(1, 'tv'),
        ).thenAnswer((_) async => [seen(1, 2, DateTime(2024, 1, 8))]);
        when(() => mockRemoteDataSource.getSeasonDetails(1, 1)).thenAnswer(
          (_) async => season([
            ep(1, airDate: '2024-01-01'),
            ep(2, airDate: '2024-01-08'),
          ]),
        );

        await repository.refreshNotificationForSeries(
          1,
          MediaType.tv,
          force: true,
        );

        verify(
          () => mockLocalDataSource.markNotificationAsReturning(1, 'tv'),
        ).called(1);
      },
    );

    test('should store an undated next episode as date TBA', () async {
      stubNotified();
      when(
        () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
      ).thenAnswer(
        (_) async => tvItem(
          seasons: const [TVSeason(id: 4, seasonNumber: 4, episodeCount: 6)],
        ),
      );
      when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
      when(
        () => mockLocalDataSource.getSeenStatus(1, 'tv'),
      ).thenAnswer((_) async => [seen(4, 5, DateTime(2024, 5, 1))]);
      when(
        () => mockRemoteDataSource.getSeasonDetails(1, 4),
      ).thenAnswer((_) async => season([ep(6, airDate: null)]));

      await repository.refreshNotificationForSeries(
        1,
        MediaType.tv,
        force: true,
      );

      verify(
        () => mockLocalDataSource.setNotificationEpisode(
          1,
          'tv',
          seasonNumber: 4,
          episodeNumber: 6,
          releaseDate: null,
          runtime: null,
        ),
      ).called(1);
    });

    test('should skip a series refreshed within the last day', () async {
      stubNotified(lastRefreshedAt: DateTime.now());

      await repository.refreshNotificationForSeries(1, MediaType.tv);

      verifyNever(
        () =>
            mockRemoteDataSource.getMediaItem(any(), type: any(named: 'type')),
      );
      verifyNever(
        () => mockLocalDataSource.markNotifiedRefreshed(any(), any(), any()),
      );
    });

    test('should refresh when forced even if refreshed recently', () async {
      stubNotified(lastRefreshedAt: DateTime.now());
      when(
        () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
      ).thenAnswer(
        (_) async => tvItem(
          status: 'Ended',
          seasons: const [TVSeason(id: 1, seasonNumber: 1, episodeCount: 1)],
        ),
      );
      when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
      when(
        () => mockLocalDataSource.getSeenStatus(1, 'tv'),
      ).thenAnswer((_) async => []);

      await repository.refreshNotificationForSeries(
        1,
        MediaType.tv,
        force: true,
      );

      verify(
        () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
      ).called(1);
      verify(
        () => mockLocalDataSource.markNotifiedRefreshed(1, 'tv', any()),
      ).called(1);
    });

    test('should repopulate Quick Add for newly aired episodes', () async {
      stubNotified();
      final media = tvItem(
        status: 'Returning Series',
        seasons: const [TVSeason(id: 1, seasonNumber: 1, episodeCount: 2)],
      );
      when(
        () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
      ).thenAnswer((_) async => media);
      // Simulate the item cached by the preceding refresh step.
      when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => media);

      final seenItems = [seen(1, 1, DateTime(2024, 1, 1))];
      when(
        () => mockLocalDataSource.getSeenStatus(1, 'tv'),
      ).thenAnswer((_) async => seenItems);
      when(
        () => mockLocalDataSource.getAllSeenItems(),
      ).thenAnswer((_) async => seenItems);
      when(
        () => mockLocalDataSource.getQuickAddItems(),
      ).thenAnswer((_) async => <QuickAddItemModel>[]);
      when(
        () => mockLocalDataSource.isOptedOut(
          any(),
          seasonNumber: any(named: 'seasonNumber'),
          episodeNumber: any(named: 'episodeNumber'),
        ),
      ).thenAnswer((_) async => false);
      when(() => mockRemoteDataSource.getSeasonDetails(1, 1)).thenAnswer(
        (_) async => season([
          ep(1, airDate: '2024-01-01'),
          ep(2, airDate: '2024-01-08', runtime: 43),
        ]),
      );
      when(
        () => mockLocalDataSource.addQuickAddItem(any()),
      ).thenAnswer((_) async {});

      await repository.refreshNotificationForSeries(
        1,
        MediaType.tv,
        force: true,
      );

      final captured = verify(
        () => mockLocalDataSource.addQuickAddItem(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final quick = captured.first as QuickAddItemModel;
      expect(quick.seasonNumber, 1);
      expect(quick.episodeNumber, 2);
      expect(quick.airDate, DateTime(2024, 1, 8));
      expect(quick.runtime, 43);
    });

    test(
      'should downgrade to Returning when an announced next season has no episodes',
      () async {
        stubNotified();
        when(
          () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
        ).thenAnswer(
          (_) async => tvItem(
            status: 'Returning Series',
            seasons: const [
              TVSeason(id: 1, seasonNumber: 1, episodeCount: 1),
              // Announced but unscheduled: TMDB reports no episodes.
              TVSeason(id: 2, seasonNumber: 2, episodeCount: 0),
            ],
          ),
        );
        when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
        when(
          () => mockLocalDataSource.getSeenStatus(1, 'tv'),
        ).thenAnswer((_) async => [seen(1, 1, DateTime(2024, 1, 1))]);
        when(() => mockRemoteDataSource.getSeasonDetails(1, 1)).thenAnswer(
          (_) async => season([ep(1, airDate: '2024-01-01')]),
        );
        when(
          () => mockRemoteDataSource.getSeasonDetails(1, 2),
        ).thenThrow(Exception('season not found'));

        await repository.refreshNotificationForSeries(
          1,
          MediaType.tv,
          force: true,
        );

        verify(
          () => mockLocalDataSource.markNotificationAsReturning(1, 'tv'),
        ).called(1);
      },
    );

    test(
      'should downgrade a partial scan when the record points at a seen episode',
      () async {
        stubNotified();
        // The stored record still points at the episode the user just watched.
        when(() => mockLocalDataSource.getNotifiedItem(1, 'tv')).thenAnswer(
          (_) async => NotifiedItemModel(
            tmdbId: 1,
            type: 'tv',
            title: 'Show',
            releaseDate: DateTime(2024, 1, 1),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
        );
        when(
          () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
        ).thenAnswer(
          (_) async => tvItem(
            status: 'Returning Series',
            seasons: const [TVSeason(id: 1, seasonNumber: 1, episodeCount: 2)],
          ),
        );
        when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
        when(
          () => mockLocalDataSource.getSeenStatus(1, 'tv'),
        ).thenAnswer((_) async => [seen(1, 1, DateTime(2024, 1, 1))]);
        when(
          () => mockRemoteDataSource.getSeasonDetails(1, 1),
        ).thenThrow(Exception('network'));

        await repository.refreshNotificationForSeries(
          1,
          MediaType.tv,
          force: true,
        );

        verify(
          () => mockLocalDataSource.markNotificationAsReturning(1, 'tv'),
        ).called(1);
      },
    );

    test(
      'should leave the record untouched when a partial scan points at an unseen episode',
      () async {
        stubNotified();
        when(() => mockLocalDataSource.getNotifiedItem(1, 'tv')).thenAnswer(
          (_) async => NotifiedItemModel(
            tmdbId: 1,
            type: 'tv',
            title: 'Show',
            releaseDate: DateTime(2024, 1, 1),
            seasonNumber: 1,
            episodeNumber: 2, // not seen
          ),
        );
        when(
          () => mockRemoteDataSource.getMediaItem(1, type: MediaType.tv),
        ).thenAnswer(
          (_) async => tvItem(
            status: 'Returning Series',
            seasons: const [TVSeason(id: 1, seasonNumber: 1, episodeCount: 2)],
          ),
        );
        when(() => mockCache.getItem(1, MediaType.tv)).thenAnswer((_) async => null);
        when(
          () => mockLocalDataSource.getSeenStatus(1, 'tv'),
        ).thenAnswer((_) async => [seen(1, 1, DateTime(2024, 1, 1))]);
        when(
          () => mockRemoteDataSource.getSeasonDetails(1, 1),
        ).thenThrow(Exception('network'));

        await repository.refreshNotificationForSeries(
          1,
          MediaType.tv,
          force: true,
        );

        verifyNever(
          () => mockLocalDataSource.markNotificationAsReturning(any(), any()),
        );
        verifyNever(
          () => mockLocalDataSource.setNotificationEpisode(
            any(),
            any(),
            seasonNumber: any(named: 'seasonNumber'),
            episodeNumber: any(named: 'episodeNumber'),
            releaseDate: any(named: 'releaseDate'),
            runtime: any(named: 'runtime'),
          ),
        );
      },
    );
  });
}
