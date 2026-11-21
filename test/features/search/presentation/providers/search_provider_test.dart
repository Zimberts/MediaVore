import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/domain/entities/because_you_data.dart';
import 'package:mediavore/core/domain/entities/liked_item_info.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/person_summary.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late SearchProvider provider;
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(MediaType.tv);
    registerFallbackValue(
      SeenItem(
        tmdbId: 1,
        type: MediaType.movie,
        title: 'T',
        seenDate: DateTime(2000),
      ),
    );
    registerFallbackValue(ImportMode.append);
    registerFallbackValue(const SearchFilters());
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
  });

  setUp(() async {
    mockRepository = MockMediaRepository();

    // Default mocks for SearchProvider init
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.getSeenStatus(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => mockRepository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRepository.toggleNotification(
        any(),
        autoNotify: any(named: 'autoNotify'),
      ),
    ).thenAnswer((_) async => Future.value());

    provider = SearchProvider(mockRepository);

    await untilCalled(() => mockRepository.getNotifiedItems());
    clearInteractions(mockRepository);
  });

  group('SearchProvider - Discovery & Search Filters', () {
    test(
      'searchMedia with empty query and no filter should load the trends of the week',
      () async {
        when(
          () => mockRepository.getTrendingMedia(page: any(named: 'page')),
        ).thenAnswer(
          (_) async => [
            const MediaItem(id: 1, title: 'A', overview: '', releaseDate: ''),
          ],
        );

        await provider.searchMedia('');

        verify(() => mockRepository.getTrendingMedia(page: 1)).called(1);
        expect(provider.isTrending, isTrue);
        expect(provider.items, hasLength(1));

        await provider.fetchNextPage();
        verify(() => mockRepository.getTrendingMedia(page: 2)).called(1);
        expect(provider.items, hasLength(2));
      },
    );

    test(
      'searchMedia with empty query and a rating filter should call discoverMedia for both Movie and TV',
      () async {
        when(
          () => mockRepository.discoverMedia(
            page: any(named: 'page'),
            filters: any(named: 'filters'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: any(named: 'type'),
            sortBy: any(named: 'sortBy'),
          ),
        ).thenAnswer((_) async => []);

        provider.setFilters(minRating: 7);
        await provider.searchMedia('');

        verify(
          () => mockRepository.discoverMedia(
            page: 1,
            filters: any(named: 'filters'),
            minRating: 7,
            type: MediaType.movie,
          ),
        ).called(1);
        verify(
          () => mockRepository.discoverMedia(
            page: 1,
            filters: any(named: 'filters'),
            minRating: 7,
            type: MediaType.tv,
          ),
        ).called(1);
        expect(provider.isDiscoverMode, isTrue);
        expect(provider.isTrending, isFalse);
        verifyNever(
          () => mockRepository.getTrendingMedia(page: any(named: 'page')),
        );
      },
    );

    test(
      'searchMedia with query should call searchMedia on repository',
      () async {
        when(
          () => mockRepository.searchMedia(
            any(),
            page: any(named: 'page'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => []);

        await provider.searchMedia('Inception');

        verify(
          () => mockRepository.searchMedia(
            'Inception',
            page: 1,
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            type: MediaType.movie,
          ),
        ).called(1);
        verify(
          () => mockRepository.searchMedia(
            'Inception',
            page: 1,
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            type: MediaType.tv,
          ),
        ).called(1);
        expect(provider.isDiscoverMode, isFalse);
      },
    );

    test('should pass filters to repository calls', () async {
      provider.setFilters(
        genreIds: [28],
        releaseYear: 2022,
        minRating: 7.0,
        type: MediaType.movie,
      );

      when(
        () => mockRepository.searchMedia(
          any(),
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => []);

      await provider.searchMedia('Batman');

      verify(
        () => mockRepository.searchMedia(
          'Batman',
          page: 1,
          genreIds: [28],
          releaseYear: 2022,
          minRating: 7.0,
          type: MediaType.movie,
        ),
      ).called(1);
    });

    test(
      'searchMedia with query and no filters searches people concurrently and populates peopleResults',
      () async {
        const tPeople = [
          PersonSummary(
            id: 100,
            name: 'Denis Villeneuve',
            profilePath: '/villeneuve.jpg',
            knownForDepartment: 'Directing',
          ),
        ];

        when(
          () => mockRepository.searchMedia(
            any(),
            page: any(named: 'page'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => []);

        when(
          () => mockRepository.searchPeople('Villeneuve'),
        ).thenAnswer((_) async => tPeople);

        await provider.searchMedia('Villeneuve');

        verify(() => mockRepository.searchPeople('Villeneuve')).called(1);
        expect(provider.peopleResults, equals(tPeople));

        provider.clearSearch();
        expect(provider.peopleResults, isEmpty);
      },
    );

    test('searchPeople failure does not fail searchMedia', () async {
      when(
        () => mockRepository.searchMedia(
          any(),
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          type: MediaType.movie,
        ),
      ).thenAnswer(
        (_) async => [
          const MediaItem(
            id: 1,
            title: 'Dune',
            overview: '',
            releaseDate: '2021',
          ),
        ],
      );

      when(
        () => mockRepository.searchMedia(
          any(),
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          type: MediaType.tv,
        ),
      ).thenAnswer((_) async => []);

      when(
        () => mockRepository.searchPeople(any()),
      ).thenThrow(Exception('TMDB person endpoint timeout'));

      await provider.searchMedia('Villeneuve');

      expect(provider.items, hasLength(1));
      expect(provider.items.first.title, 'Dune');
      expect(provider.peopleResults, isEmpty);
      expect(provider.error, isNull);
    });

    test('searchMedia with active filters does not search people', () async {
      provider.setFilters(type: MediaType.movie);

      when(
        () => mockRepository.searchMedia(
          any(),
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => []);

      await provider.searchMedia('Villeneuve');

      verifyNever(() => mockRepository.searchPeople(any()));
      expect(provider.peopleResults, isEmpty);
    });

    test(
      'searchMedia with query and no filters searches people concurrently and populates peopleResults',
      () async {
        const tPeople = [
          PersonSummary(
            id: 100,
            name: 'Denis Villeneuve',
            profilePath: '/villeneuve.jpg',
            knownForDepartment: 'Directing',
          ),
        ];

        when(
          () => mockRepository.searchMedia(
            any(),
            page: any(named: 'page'),
            genreIds: any(named: 'genreIds'),
            releaseYear: any(named: 'releaseYear'),
            minRating: any(named: 'minRating'),
            originalLanguage: any(named: 'originalLanguage'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => []);

        when(
          () => mockRepository.searchPeople('Villeneuve'),
        ).thenAnswer((_) async => tPeople);

        await provider.searchMedia('Villeneuve');

        verify(() => mockRepository.searchPeople('Villeneuve')).called(1);
        expect(provider.peopleResults, equals(tPeople));

        provider.clearSearch();
        expect(provider.peopleResults, isEmpty);
      },
    );

    test('searchPeople failure does not fail searchMedia', () async {
      when(
        () => mockRepository.searchMedia(
          any(),
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          type: MediaType.movie,
        ),
      ).thenAnswer(
        (_) async => [
          const MediaItem(
            id: 1,
            title: 'Dune',
            overview: '',
            releaseDate: '2021',
          ),
        ],
      );

      when(
        () => mockRepository.searchMedia(
          any(),
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          type: MediaType.tv,
        ),
      ).thenAnswer((_) async => []);

      when(
        () => mockRepository.searchPeople(any()),
      ).thenThrow(Exception('TMDB person endpoint timeout'));

      await provider.searchMedia('Villeneuve');

      expect(provider.items, hasLength(1));
      expect(provider.items.first.title, 'Dune');
      expect(provider.peopleResults, isEmpty);
      expect(provider.error, isNull);
    });

    test('searchMedia with active filters does not search people', () async {
      provider.setFilters(type: MediaType.movie);

      when(
        () => mockRepository.searchMedia(
          any(),
          page: any(named: 'page'),
          genreIds: any(named: 'genreIds'),
          releaseYear: any(named: 'releaseYear'),
          minRating: any(named: 'minRating'),
          originalLanguage: any(named: 'originalLanguage'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => []);

      await provider.searchMedia('Villeneuve');

      verifyNever(() => mockRepository.searchPeople(any()));
      expect(provider.peopleResults, isEmpty);
    });
  });

  group('SearchProvider - Because You Recommendations', () {
    test(
      'fetches recommendations for liked candidate and populates becauseYouData',
      () async {
        when(() => mockRepository.getLikedItems()).thenAnswer(
          (_) async => const [
            LikedItemInfo(tmdbId: 438631, type: MediaType.movie, title: 'Dune'),
          ],
        );

        when(
          () => mockRepository.getRecommendedMedia(438631, MediaType.movie),
        ).thenAnswer(
          (_) async => const [
            MediaItem(id: 1, title: 'Rec 1', overview: '', releaseDate: ''),
            MediaItem(id: 2, title: 'Rec 2', overview: '', releaseDate: ''),
            MediaItem(id: 3, title: 'Rec 3', overview: '', releaseDate: ''),
          ],
        );

        await provider.loadBecauseYouRecommendations();

        expect(provider.becauseYouData, isNotNull);
        expect(provider.becauseYouData!.sourceTitle, 'Dune');
        expect(provider.becauseYouData!.reason, BecauseYouReason.liked);
        expect(provider.becauseYouData!.items.length, 3);
      },
    );

    test(
      'leaves becauseYouData null if fewer than 3 recommendations remain',
      () async {
        when(() => mockRepository.getLikedItems()).thenAnswer(
          (_) async => const [
            LikedItemInfo(tmdbId: 438631, type: MediaType.movie, title: 'Dune'),
          ],
        );

        when(
          () => mockRepository.getRecommendedMedia(438631, MediaType.movie),
        ).thenAnswer(
          (_) async => const [
            MediaItem(id: 1, title: 'Rec 1', overview: '', releaseDate: ''),
            MediaItem(id: 2, title: 'Rec 2', overview: '', releaseDate: ''),
          ],
        );

        await provider.loadBecauseYouRecommendations();

        expect(provider.becauseYouData, isNull);
      },
    );
  });

  group('SearchProvider - Media Details Enrichment', () {
    test(
      'getMediaDetails should fetch extra data (similar, recommended, providers, videos)',
      () async {
        final tItem = const MediaItem(
          id: 1,
          title: 'T',
          overview: 'O',
          releaseDate: '2023',
        );
        final tDetails = MediaDetails(
          item: tItem,
          cast: [],
          similar: [],
          recommendations: [],
          watchProviders: {},
          videos: [],
        );

        when(
          () => mockRepository.getMediaDetails(any(), type: any(named: 'type')),
        ).thenAnswer((_) async => tDetails);

        final result = await provider.getMediaDetails(1, MediaType.movie);

        expect(result.similar, isNotNull);
        expect(result.recommendations, isNotNull);
        expect(result.watchProviders, isNotNull);
        expect(result.videos, isNotNull);
      },
    );
  });

  group('SearchProvider - Offline Status', () {
    test('initial state should be online', () {
      expect(provider.isOffline, isFalse);
    });

    test('should set offline to true when network call fails', () async {
      when(
        () => mockRepository.getTrendingMedia(page: any(named: 'page')),
      ).thenThrow(const NetworkException('Connection failed'));

      await provider.searchMedia('');

      expect(provider.isOffline, isTrue);
      expect(provider.errorType, SearchErrorType.offline);
    });
  });

  group('SearchProvider - Search errors', () {
    void stubDiscoverThrows(Object error) {
      when(
        () => mockRepository.getTrendingMedia(page: any(named: 'page')),
      ).thenThrow(error);
    }

    test('should classify errors by exception type', () {
      expect(
        classifySearchError(const ConfigurationException('x')),
        SearchErrorType.missingApiKey,
      );
      expect(
        classifySearchError(const NetworkException('x')),
        SearchErrorType.offline,
      );
      expect(
        classifySearchError(const ServerException('x', 401)),
        SearchErrorType.invalidApiKey,
      );
      expect(
        classifySearchError(const ServerException('x', 503)),
        SearchErrorType.server,
      );
      expect(
        classifySearchError(const ParsingException('x')),
        SearchErrorType.unknown,
      );
    });

    test('should expose missingApiKey without flagging offline', () async {
      stubDiscoverThrows(const ConfigurationException('missing key'));

      await provider.searchMedia('');

      expect(provider.errorType, SearchErrorType.missingApiKey);
      expect(provider.error, contains('Settings'));
      expect(provider.isOffline, isFalse);
      expect(provider.items, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('should clear the error on a successful retry', () async {
      stubDiscoverThrows(const ServerException('down', 503));
      await provider.searchMedia('');
      expect(provider.errorType, SearchErrorType.server);

      when(
        () => mockRepository.getTrendingMedia(page: any(named: 'page')),
      ).thenAnswer((_) async => []);
      await provider.searchMedia('');

      expect(provider.errorType, isNull);
      expect(provider.error, isNull);
    });

    test('should not re-fetch next page while it is failing', () async {
      when(
        () => mockRepository.searchMedia(
          any(),
          page: 1,
          type: any(named: 'type'),
        ),
      ).thenAnswer(
        (_) async => const [
          MediaItem(id: 1, title: 'A', overview: '', releaseDate: ''),
        ],
      );
      when(
        () => mockRepository.searchMedia(
          any(),
          page: 2,
          type: any(named: 'type'),
        ),
      ).thenThrow(const NetworkException('offline'));

      await provider.searchMedia('A');
      await provider.fetchNextPage();
      expect(provider.errorType, SearchErrorType.offline);
      expect(provider.items, hasLength(2));

      clearInteractions(mockRepository);
      await provider.fetchNextPage();
      verifyNever(
        () => mockRepository.searchMedia(
          any(),
          page: any(named: 'page'),
          type: any(named: 'type'),
        ),
      );

      // Retry issues the request again (the movie call throws first, so the
      // tv call is never reached).
      await provider.retryNextPage();
      verify(
        () => mockRepository.searchMedia(
          any(),
          page: 2,
          type: any(named: 'type'),
        ),
      ).called(1);
      expect(provider.errorType, SearchErrorType.offline);
    });
  });

  group('SearchProvider - Seen Status', () {
    test(
      'should load all seen items and deduplicate episodes for TV counts',
      () async {
        final seenItems = [
          SeenItem(
            tmdbId: 1,
            type: MediaType.movie,
            title: 'M',
            seenDate: DateTime(2023, 1, 1),
          ),
          SeenItem(
            tmdbId: 1,
            type: MediaType.movie,
            title: 'M',
            seenDate: DateTime(2023, 1, 2),
          ),
          SeenItem(
            tmdbId: 2,
            type: MediaType.tv,
            title: 'T',
            seenDate: DateTime(2023),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
          SeenItem(
            tmdbId: 2,
            type: MediaType.tv,
            title: 'T',
            seenDate: DateTime(2023),
            seasonNumber: 1,
            episodeNumber: 1,
          ),
        ];

        when(
          () => mockRepository.getSeenItems(),
        ).thenAnswer((_) async => seenItems);

        await provider.loadAllSeenStatus();

        const movieItem = MediaItem(
          id: 1,
          title: 'M',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.movie,
        );
        const tvItem = MediaItem(
          id: 2,
          title: 'T',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.tv,
        );

        expect(provider.getSeenCount(movieItem), 2);
        expect(provider.getSeenCount(tvItem), 1);
      },
    );
  });

  group('SearchProvider - Language change', () {
    setUp(() {
      when(() => mockRepository.getQuickAddItems()).thenAnswer((_) async => []);
      when(() => mockRepository.fillCache()).thenAnswer((_) async {});
    });

    test('should reload saved titles once the warm-up is done', () async {
      when(
        () => mockRepository.applyLanguageChange(),
      ).thenAnswer((_) async => true);

      await provider.reloadForLanguageChange();

      expect(provider.tmdbLanguageRevision, 1);
      verify(() => mockRepository.fillCache()).called(1);
      verify(() => mockRepository.getSeenItems()).called(2);
    });

    test('should do nothing when the cache language did not change', () async {
      when(
        () => mockRepository.applyLanguageChange(),
      ).thenAnswer((_) async => false);

      await provider.reloadForLanguageChange();

      expect(provider.tmdbLanguageRevision, 0);
      verifyNever(() => mockRepository.fillCache());
      verifyNever(() => mockRepository.getSeenItems());
    });
  });

  group('SearchProvider - Optimistic seen updates (#355)', () {
    const movieItem = MediaItem(
      id: 555,
      title: 'Optimistic Movie',
      overview: '',
      releaseDate: '',
      mediaType: MediaType.movie,
    );
    final seenMovie = SeenItem(
      tmdbId: 555,
      type: MediaType.movie,
      title: 'Optimistic Movie',
      seenDate: DateTime.now(),
    );

    setUp(() {
      when(() => mockRepository.getQuickAddItems()).thenAnswer((_) async => []);
      when(() => mockRepository.getInProgressItems()).thenAnswer((_) async => []);
      when(() => mockRepository.getQuickAddOptOuts()).thenAnswer((_) async => []);
      when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
      when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
      when(() => mockRepository.getSeenStatus(555, MediaType.movie)).thenAnswer((_) async => []);
    });

    test('markAsSeen updates _seenItems and _seenCounts immediately before repo call completes', () async {
      final completer = Completer<void>();
      when(() => mockRepository.markAsSeen(any())).thenAnswer((_) => completer.future);

      bool notified = false;
      provider.addListener(() {
        if (provider.getSeenCount(movieItem) == 1) {
          notified = true;
        }
      });

      expect(provider.getSeenCount(movieItem), 0);
      expect(provider.seenItems.any((s) => s.tmdbId == 555), isFalse);

      final future = provider.markAsSeen(seenMovie);

      // Immediately updated in memory and notified before completer.complete()
      expect(provider.getSeenCount(movieItem), 1);
      expect(provider.seenItems.any((s) => s.tmdbId == 555), isTrue);
      expect(notified, isTrue);

      completer.complete();
      await future;

      expect(provider.getSeenCount(movieItem), 1);
    });

    test('markAsSeen rolls back optimistic state when repo call fails', () async {
      when(() => mockRepository.markAsSeen(any())).thenThrow(Exception('DB error'));

      expect(provider.getSeenCount(movieItem), 0);

      expect(() => provider.markAsSeen(seenMovie), throwsA(isA<Exception>()));

      expect(provider.getSeenCount(movieItem), 0);
      expect(provider.seenItems.any((s) => s.tmdbId == 555), isFalse);
    });

    test('markManyAsSeen updates _seenItems and _seenCounts immediately before repo call completes', () async {
      final completer = Completer<void>();
      when(() => mockRepository.markManyAsSeen(any())).thenAnswer((_) => completer.future);

      final episodes = [
        SeenItem(
          tmdbId: 888,
          type: MediaType.tv,
          title: 'TV Show',
          seasonNumber: 1,
          episodeNumber: 1,
          seenDate: DateTime.now(),
        ),
        SeenItem(
          tmdbId: 888,
          type: MediaType.tv,
          title: 'TV Show',
          seasonNumber: 1,
          episodeNumber: 2,
          seenDate: DateTime.now(),
        ),
      ];
      const tvItem = MediaItem(
        id: 888,
        title: 'TV Show',
        overview: '',
        releaseDate: '',
        mediaType: MediaType.tv,
      );

      final future = provider.markManyAsSeen(episodes);

      expect(provider.getSeenCount(tvItem), 2);
      expect(provider.seenItems.where((s) => s.tmdbId == 888).length, 2);

      completer.complete();
      await future;

      expect(provider.getSeenCount(tvItem), 2);
    });

    test('loadSeenStatusForItem returns in-memory items when DB is pending', () async {
      final completer = Completer<void>();
      when(() => mockRepository.markAsSeen(any())).thenAnswer((_) => completer.future);
      when(() => mockRepository.getSeenStatus(555, MediaType.movie)).thenAnswer((_) async => []);

      final future = provider.markAsSeen(seenMovie);

      final status = await provider.loadSeenStatusForItem(555, MediaType.movie);
      expect(status, isNotEmpty);
      expect(status.first.tmdbId, 555);

      completer.complete();
      await future;
    });
  });
}
