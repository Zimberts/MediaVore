import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/library/presentation/providers/library_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late LibraryProvider provider;

  const tMovie = MediaItem(
    id: 101,
    title: 'Inception',
    overview: 'Dream within a dream',
    releaseDate: '2010-07-16',
    mediaType: MediaType.movie,
  );

  setUpAll(() {
    registerFallbackValue(tMovie);
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(() => mockRepository.getAllListNames()).thenAnswer(
      (_) async => ['watchlist', 'Favorites'],
    );
    when(() => mockRepository.getListEntries(any())).thenAnswer(
      (_) async => [],
    );
    when(() => mockRepository.getListPreviews(any())).thenAnswer(
      (_) async => [],
    );
    when(() => mockRepository.getWatchlistEntries()).thenAnswer(
      (_) async => ['101:movie'],
    );
    when(() => mockRepository.getLikedEntries()).thenAnswer(
      (_) async => ['101:movie'],
    );
    when(() => mockRepository.toggleLike(any())).thenAnswer((_) async {});
    when(
      () => mockRepository.addToList(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.removeFromList(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockRepository.createList(any())).thenAnswer((_) async {});
    when(() => mockRepository.deleteList(any())).thenAnswer((_) async {});
    when(
      () => mockRepository.updateListOrder(any(), any()),
    ).thenAnswer((_) async {});

    provider = LibraryProvider(mockRepository);
  });

  tearDown(() {
    provider.dispose();
  });

  group('LibraryProvider', () {
    test('initializes lists, watchlist and liked entries', () async {
      await provider.init();

      expect(provider.listNames, ['watchlist', 'Favorites']);
      expect(provider.watchlistIds, ['101']);
      expect(provider.likedIds, ['101:movie']);
      expect(provider.isLiked(tMovie), isTrue);
      expect(provider.isWatchlist(tMovie), isTrue);
    });

    test('toggleLike updates liked status and notifies listeners', () async {
      await provider.init();
      when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.toggleLike(tMovie);

      verify(() => mockRepository.toggleLike(tMovie)).called(1);
      expect(notified, isTrue);
      expect(provider.isLiked(tMovie), isFalse);
    });

    test('toggleInList adds and removes items', () async {
      await provider.init();

      await provider.toggleInList(tMovie, 'Favorites');
      verify(() => mockRepository.addToList(tMovie, 'Favorites')).called(1);
      expect(provider.isItemInList(tMovie, 'Favorites'), isTrue);

      await provider.toggleInList(tMovie, 'Favorites');
      verify(
        () => mockRepository.removeFromList(
          tMovie.id,
          tMovie.mediaType,
          'Favorites',
        ),
      ).called(1);
      expect(provider.isItemInList(tMovie, 'Favorites'), isFalse);
    });

    test('toggleInList notifies listeners optimistically before addToList completes', () async {
      await provider.init();
      final completer = Completer<void>();
      when(() => mockRepository.addToList(any(), any())).thenAnswer((_) => completer.future);

      var notifiedCount = 0;
      var wasInListDuringNotification = false;
      provider.addListener(() {
        notifiedCount++;
        if (provider.isItemInList(tMovie, 'Favorites')) {
          wasInListDuringNotification = true;
        }
      });

      final future = provider.toggleInList(tMovie, 'Favorites');

      // Immediate optimistic update before repository completes
      expect(notifiedCount, greaterThanOrEqualTo(1));
      expect(wasInListDuringNotification, isTrue);
      expect(provider.isItemInList(tMovie, 'Favorites'), isTrue);

      // Now complete the repository call
      completer.complete();
      await future;
      expect(provider.isItemInList(tMovie, 'Favorites'), isTrue);
    });

    test('toggleInList rolls back optimistic state on repository failure', () async {
      await provider.init();
      when(() => mockRepository.addToList(any(), any())).thenThrow(Exception('DB error'));

      expect(provider.isItemInList(tMovie, 'Favorites'), isFalse);

      await expectLater(
        () => provider.toggleInList(tMovie, 'Favorites'),
        throwsA(isA<Exception>()),
      );

      // Must be rolled back to false
      expect(provider.isItemInList(tMovie, 'Favorites'), isFalse);
    });

    test('createList and deleteList call repository', () async {
      await provider.init();

      when(() => mockRepository.getAllListNames()).thenAnswer(
        (_) async => ['watchlist', 'Favorites', 'SciFi'],
      );
      await provider.createList('SciFi');
      verify(() => mockRepository.createList('SciFi')).called(1);
      expect(provider.listNames.contains('SciFi'), isTrue);

      when(() => mockRepository.getAllListNames()).thenAnswer(
        (_) async => ['watchlist', 'Favorites'],
      );
      await provider.deleteList('SciFi');
      verify(() => mockRepository.deleteList('SciFi')).called(1);
    });
  });
}
