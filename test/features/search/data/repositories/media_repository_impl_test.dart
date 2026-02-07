import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/data/repositories/media_repository_impl.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
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
    when(() => mockCache.isItemCached(any(), any())).thenReturn(false);
    when(() => mockCache.areDetailsCached(any(), any())).thenReturn(false);
    when(() => mockCache.isSeasonCached(any(), any())).thenReturn(false);
    when(
      () => mockCache.cacheSeason(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockCache.getItem(any(), any())).thenReturn(null);

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

  group('getMediaDetails Enrichment', () {
    const tId = 1;

    test(
      'should fetch and cache media details including similar, recommended, providers, and videos',
      () async {
        when(
          () => mockCache.areDetailsCached(tId, MediaType.movie),
        ).thenReturn(false);
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
        when(() => mockCache.getItem(any(), any())).thenReturn(tMediaItem);

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
        when(() => mockCache.getItem(any(), any())).thenReturn(null);
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
      verify(() => mockCache.cacheItem(tMediaItem)).called(1);
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
}
