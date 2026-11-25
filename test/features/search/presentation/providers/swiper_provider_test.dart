import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/providers/swiper_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;
  late SwiperProvider provider;

  const movie1 = MediaItem(
    id: 101,
    title: 'Movie 101',
    overview: 'Desc',
    releaseDate: '2023-01-01',
  );

  const movie2 = MediaItem(
    id: 102,
    title: 'Movie 102',
    overview: 'Desc',
    releaseDate: '2023-02-01',
  );

  const movieSagaPart1 = MediaItem(
    id: 201,
    title: 'Saga Part 1',
    overview: 'Part 1',
    releaseDate: '2010-01-01',
    collectionId: 999,
    collectionName: 'Epic Saga',
  );

  const movieSagaPart2 = MediaItem(
    id: 202,
    title: 'Saga Part 2',
    overview: 'Part 2',
    releaseDate: '2015-01-01',
    collectionId: 999,
    collectionName: 'Epic Saga',
  );

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(movie1);
    registerFallbackValue(
      SwipeDecisionModel(
        tmdbId: 0,
        title: '',
        decision: 'added',
        decidedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    repo = MockMediaRepository();

    when(() => repo.getDecidedTmdbIds()).thenAnswer((_) async => <int>{});
    when(
      () => repo.getSwipeDecisions(),
    ).thenAnswer((_) async => <SwipeDecisionModel>[]);
    when(
      () => repo.discoverMedia(
        type: any(named: 'type'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => [movie1, movie2, movieSagaPart1]);

    when(
      () => repo.getMediaDetails(101, type: any(named: 'type')),
    ).thenAnswer((_) async => MediaDetails(item: movie1, cast: const []));
    when(
      () => repo.getMediaDetails(102, type: any(named: 'type')),
    ).thenAnswer((_) async => MediaDetails(item: movie2, cast: const []));
    when(() => repo.getMediaDetails(201, type: any(named: 'type'))).thenAnswer(
      (_) async => MediaDetails(
        item: movieSagaPart1,
        cast: const [],
        collection: [movieSagaPart2, movieSagaPart1], // Unsorted to test sort
      ),
    );

    when(() => repo.addToList(any(), any())).thenAnswer((_) async {});
    when(
      () => repo.removeFromList(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => repo.recordSwipeDecision(any())).thenAnswer((_) async {});
    when(() => repo.recordSwipeDecisions(any())).thenAnswer((_) async {});
    when(() => repo.undoLastSwipeDecision()).thenAnswer((_) async => null);

    provider = SwiperProvider(repo);
  });

  test(
    'init filters out already decided, already seen, and already in list items',
    () async {
      when(() => repo.getDecidedTmdbIds()).thenAnswer((_) async => {101});

      await provider.init(existingListIds: {102}, seenIds: {});

      // 101 is decided, 102 is already in a list -> only saga 201 should be loaded
      expect(provider.candidates.length, 1);
      expect(provider.candidates.first.item.id, 201);
      expect(provider.candidates.first.isSaga, true);
      // Saga parts should be chronologically sorted (201: 2010, 202: 2015)
      expect(provider.candidates.first.sagaItems.first.id, 201);
      expect(provider.candidates.first.sagaItems.last.id, 202);
    },
  );

  test('swipeRight adds movie to target list and records decision', () async {
    await provider.init();
    expect(provider.candidates.isNotEmpty, true);

    final first = provider.currentCandidate!;
    expect(first.item.id, 101);

    await provider.swipeRight('watchlist');

    verify(() => repo.addToList(movie1, 'watchlist')).called(1);
    verify(
      () => repo.recordSwipeDecision(
        any(
          that: isA<SwipeDecisionModel>()
              .having((d) => d.tmdbId, 'tmdbId', 101)
              .having((d) => d.decision, 'decision', 'added')
              .having((d) => d.targetList, 'targetList', 'watchlist'),
        ),
      ),
    ).called(1);

    expect(provider.sessionAddedCount, 1);
    expect(provider.sessionDiscardedCount, 0);
    expect(provider.currentCandidate?.item.id, 102);
  });

  test('swipeLeft discards movie without adding to list', () async {
    await provider.init();
    expect(provider.currentCandidate?.item.id, 101);

    await provider.swipeLeft();

    verifyNever(() => repo.addToList(any(), any()));
    verify(
      () => repo.recordSwipeDecision(
        any(
          that: isA<SwipeDecisionModel>()
              .having((d) => d.tmdbId, 'tmdbId', 101)
              .having((d) => d.decision, 'decision', 'discarded'),
        ),
      ),
    ).called(1);

    expect(provider.sessionAddedCount, 0);
    expect(provider.sessionDiscardedCount, 1);
    expect(provider.currentCandidate?.item.id, 102);
  });

  test(
    'swipeRight on saga adds all missing saga parts in chronological order',
    () async {
      // Only saga available
      when(() => repo.getDecidedTmdbIds()).thenAnswer((_) async => {101, 102});
      await provider.init();

      expect(provider.candidates.length, 1);
      final saga = provider.currentCandidate!;
      expect(saga.isSaga, true);

      await provider.swipeRight('watchlist');

      // Both parts should be added
      verify(() => repo.addToList(movieSagaPart1, 'watchlist')).called(1);
      verify(() => repo.addToList(movieSagaPart2, 'watchlist')).called(1);
      verify(
        () => repo.recordSwipeDecisions(any(that: hasLength(2))),
      ).called(1);

      expect(provider.sessionAddedCount, 1);
      expect(provider.candidates.isEmpty, true);
    },
  );

  test(
    'undoLastDecision reverts an added movie and removes it from target list',
    () async {
      await provider.init();
      await provider.swipeRight('watchlist');

      when(() => repo.undoLastSwipeDecision()).thenAnswer(
        (_) async => SwipeDecisionModel(
          isarId: 1,
          tmdbId: 101,
          title: 'Movie 101',
          decision: 'added',
          decidedAt: DateTime.now(),
          targetList: 'watchlist',
        ),
      );

      expect(provider.canUndo, true);
      final undoResult = await provider.undoLastDecision();

      expect(undoResult, isNotNull);
      expect(undoResult!.restoredCandidate.item.id, 101);
      expect(provider.sessionAddedCount, 0);
      verify(
        () => repo.removeFromList(101, MediaType.movie, 'watchlist'),
      ).called(1);
      expect(provider.currentCandidate?.item.id, 101);
    },
  );

  test('should keep the rest of a discover page for the next cards instead of '
      'skipping it', () async {
    MediaItem movie(int id) => MediaItem(
      id: id,
      title: 'Movie $id',
      overview: '',
      releaseDate: '2023-01-01',
    );
    when(
      () => repo.discoverMedia(
        type: any(named: 'type'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      return page <= 2
          ? [for (var i = 1; i <= 3; i++) movie(page * 100 + i)]
          : <MediaItem>[];
    });
    when(
      () => repo.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer(
      (invocation) async => MediaDetails(
        item: movie(invocation.positionalArguments.first as int),
        cast: const [],
      ),
    );

    await provider.init();
    final shown = <int>[];
    while (provider.currentCandidate != null) {
      shown.add(provider.currentCandidate!.item.id);
      await provider.swipeLeft();
    }

    // The first load stops at 4 cards, in the middle of page 2: its last
    // two titles still come next.
    expect(shown, [101, 102, 103, 201, 202, 203]);
  });

  test('should not propose an undone saga twice when a load in flight meets '
      'another of its parts', () async {
    final page2 = Completer<List<MediaItem>>();
    when(
      () => repo.discoverMedia(
        type: any(named: 'type'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      if (page == 1) return [movieSagaPart1, movie1, movie2];
      if (page == 2) return page2.future;
      return <MediaItem>[];
    });
    when(() => repo.getMediaDetails(202, type: any(named: 'type'))).thenAnswer(
      (_) async => MediaDetails(
        item: movieSagaPart2,
        cast: const [],
        collection: [movieSagaPart1, movieSagaPart2],
      ),
    );
    when(() => repo.undoLastSwipeDecision()).thenAnswer(
      (_) async => SwipeDecisionModel(
        isarId: 1,
        tmdbId: 201,
        title: 'Saga Part 1',
        decision: 'discarded',
        decidedAt: DateTime.now(),
        collectionId: 999,
      ),
    );

    // The first load holds 3 cards and waits for page 2.
    final loading = provider.init();
    await pumpEventQueue();
    expect(provider.currentCandidate?.collectionId, 999);

    await provider.swipeLeft();
    await provider.undoLastDecision();
    expect(provider.currentCandidate?.collectionId, 999);

    // Page 2 brings the other part of the saga, which is back in the deck.
    page2.complete([movieSagaPart2]);
    await loading;

    expect(
      provider.candidates.where((c) => c.collectionId == 999),
      hasLength(1),
    );
  });

  test('should report no more cards once the page limit is reached', () async {
    await provider.init();

    // Every page repeats the same titles: the deck stops at page 50.
    verify(
      () => repo.discoverMedia(
        type: any(named: 'type'),
        page: any(named: 'page'),
      ),
    ).called(50);
    expect(provider.hasMore, isFalse);
  });

  group('with LibraryProvider', () {
    late LibraryProvider libraryProvider;

    setUp(() {
      when(
        () => repo.getAllListNames(),
      ).thenAnswer((_) async => ['watchlist', 'Favorites']);
      when(() => repo.getListEntries(any())).thenAnswer((_) async => []);
      when(() => repo.getListPreviews(any())).thenAnswer((_) async => []);
      when(() => repo.getWatchlistEntries()).thenAnswer((_) async => []);
      when(() => repo.getLikedEntries()).thenAnswer((_) async => []);
      when(() => repo.getListMediaItems(any())).thenAnswer((_) async => []);
      when(() => repo.addAllToList(any(), any())).thenAnswer((_) async {});
      when(() => repo.getNotifiedItems()).thenAnswer((_) async => []);
      when(
        () => repo.watchNotifiedItems(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => repo.getCacheSize()).thenAnswer((_) async => 0);
      when(() => repo.getSeenDbSize()).thenAnswer((_) async => 0);

      libraryProvider = LibraryProvider(repo);
      provider = SwiperProvider(repo, libraryProvider: libraryProvider);
    });

    test('swipeRight updates LibraryProvider entries immediately', () async {
      await provider.init();
      await provider.swipeRight('watchlist');

      expect(libraryProvider.isItemInList(movie1, 'watchlist'), isTrue);
      expect(
        libraryProvider.getListEntriesCached('watchlist'),
        contains('101:movie'),
      );
    });

    test(
      'swipeRight with saga updates LibraryProvider entries for all parts',
      () async {
        when(
          () => repo.getDecidedTmdbIds(),
        ).thenAnswer((_) async => {101, 102});
        await provider.init();
        await provider.swipeRight('watchlist');

        expect(
          libraryProvider.isItemInList(movieSagaPart1, 'watchlist'),
          isTrue,
        );
        expect(
          libraryProvider.isItemInList(movieSagaPart2, 'watchlist'),
          isTrue,
        );
      },
    );

    test(
      'undoLastDecision removes movie from LibraryProvider entries',
      () async {
        await provider.init();
        await provider.swipeRight('watchlist');
        expect(libraryProvider.isItemInList(movie1, 'watchlist'), isTrue);

        when(() => repo.undoLastSwipeDecision()).thenAnswer(
          (_) async => SwipeDecisionModel(
            isarId: 1,
            tmdbId: 101,
            title: 'Movie 101',
            decision: 'added',
            decidedAt: DateTime.now(),
            targetList: 'watchlist',
          ),
        );

        await provider.undoLastDecision();
        expect(libraryProvider.isItemInList(movie1, 'watchlist'), isFalse);
      },
    );

    test(
      'Swiping right updates SearchProvider tonightCandidates via LibraryProvider',
      () async {
        when(
          () => repo.getListMediaItems('watchlist'),
        ).thenAnswer((_) async => [movie1]);
        when(() => repo.getSeenItems()).thenAnswer((_) async => []);

        final searchProvider = SearchProvider(
          repo,
          libraryProvider: libraryProvider,
        );
        await provider.init();
        await provider.swipeRight('watchlist');

        // Wait a tick for _onLibraryChanged unawaited task
        await Future<void>.delayed(Duration.zero);

        expect(
          searchProvider.tonightCandidates().map((m) => m.id),
          contains(101),
        );
      },
    );
  });
}
