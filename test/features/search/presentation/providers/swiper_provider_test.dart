import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';
import 'package:mediavore/features/search/presentation/providers/swiper_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;
  late SwiperProvider provider;

  final movie1 = const MediaItem(
    id: 101,
    title: 'Movie 101',
    overview: 'Desc',
    releaseDate: '2023-01-01',
    mediaType: MediaType.movie,
  );

  final movie2 = const MediaItem(
    id: 102,
    title: 'Movie 102',
    overview: 'Desc',
    releaseDate: '2023-02-01',
    mediaType: MediaType.movie,
  );

  final movieSagaPart1 = const MediaItem(
    id: 201,
    title: 'Saga Part 1',
    overview: 'Part 1',
    releaseDate: '2010-01-01',
    collectionId: 999,
    collectionName: 'Epic Saga',
    mediaType: MediaType.movie,
  );

  final movieSagaPart2 = const MediaItem(
    id: 202,
    title: 'Saga Part 2',
    overview: 'Part 2',
    releaseDate: '2015-01-01',
    collectionId: 999,
    collectionName: 'Epic Saga',
    mediaType: MediaType.movie,
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
}
