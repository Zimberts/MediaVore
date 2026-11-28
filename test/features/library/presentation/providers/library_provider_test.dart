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
  );

  setUpAll(() {
    registerFallbackValue(tMovie);
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(<MediaItem>[]);
    registerFallbackValue(<(int, MediaType)>[]);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', 'Favorites']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => ['101:movie']);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => ['101:movie']);
    when(() => mockRepository.toggleLike(any())).thenAnswer((_) async {});
    when(() => mockRepository.addToList(any(), any())).thenAnswer((_) async {});
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

    test(
      'toggleInList notifies listeners optimistically before addToList completes',
      () async {
        await provider.init();
        final completer = Completer<void>();
        when(
          () => mockRepository.addToList(any(), any()),
        ).thenAnswer((_) => completer.future);

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
      },
    );

    test(
      'toggleInList rolls back optimistic state on repository failure',
      () async {
        await provider.init();
        when(
          () => mockRepository.addToList(any(), any()),
        ).thenThrow(Exception('DB error'));

        expect(provider.isItemInList(tMovie, 'Favorites'), isFalse);

        await expectLater(
          () => provider.toggleInList(tMovie, 'Favorites'),
          throwsA(isA<Exception>()),
        );

        // Must be rolled back to false
        expect(provider.isItemInList(tMovie, 'Favorites'), isFalse);
      },
    );

    test('createList and deleteList call repository', () async {
      await provider.init();

      when(
        () => mockRepository.getAllListNames(),
      ).thenAnswer((_) async => ['watchlist', 'Favorites', 'SciFi']);
      await provider.createList('SciFi');
      verify(() => mockRepository.createList('SciFi')).called(1);
      expect(provider.listNames.contains('SciFi'), isTrue);

      when(
        () => mockRepository.getAllListNames(),
      ).thenAnswer((_) async => ['watchlist', 'Favorites']);
      await provider.deleteList('SciFi');
      verify(() => mockRepository.deleteList('SciFi')).called(1);
    });

    group('importList', () {
      const cachedMovie = MediaItem(
        id: 101,
        title: 'Inception',
        overview: '',
        releaseDate: '2010-07-16',
        posterPath: '/inception.jpg',
      );
      late Map<String, List<String>> stored;

      setUp(() {
        stored = {
          'watchlist': ['101:movie'],
          'Favorites': [],
        };
        when(
          () => mockRepository.getAllListNames(),
        ).thenAnswer((_) async => stored.keys.toList());
        when(() => mockRepository.getListEntries(any())).thenAnswer(
          (invocation) async => [
            ...?stored[invocation.positionalArguments.first as String],
          ],
        );
        when(
          () => mockRepository.getWatchlistEntries(),
        ).thenAnswer((_) async => [...stored['watchlist']!]);
        when(() => mockRepository.createList(any())).thenAnswer((
          invocation,
        ) async {
          stored.putIfAbsent(
            invocation.positionalArguments.first as String,
            () => [],
          );
        });
        when(() => mockRepository.addAllToList(any(), any())).thenAnswer((
          invocation,
        ) async {
          final items = invocation.positionalArguments[0] as List<MediaItem>;
          final name = invocation.positionalArguments[1] as String;
          for (final item in items) {
            final entry = '${item.id}:${item.mediaType.name}';
            if (!stored[name]!.contains(entry)) stored[name]!.add(entry);
          }
        });
        when(
          () => mockRepository.getCachedMediaItems(any()),
        ).thenAnswer((_) async => [cachedMovie, null]);
      });

      test('should add cached titles with their metadata and unknown ones as '
          'placeholders when a shared list is imported', () async {
        await provider.init();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.importList('Shared', ['101:movie', '7:TV']);

        verify(
          () => mockRepository.getCachedMediaItems([
            (101, MediaType.movie),
            (7, MediaType.tv),
          ]),
        ).called(1);
        final added =
            verify(
                  () => mockRepository.addAllToList(captureAny(), 'Shared'),
                ).captured.single
                as List<MediaItem>;
        // Re-adding the cached item rewrites the cache with itself: its
        // title and poster survive.
        expect(added.first, cachedMovie);
        expect(added.last.id, 7);
        expect(added.last.mediaType, MediaType.tv);
        expect(added.last.title, 'Unknown');
        verifyNever(() => mockRepository.addToList(any(), any()));
        expect(provider.listNames, contains('Shared'));
        expect(provider.getListEntriesCached('Shared'), ['101:movie', '7:tv']);
        expect(notifications, 1);
      });

      test('should refresh the watchlist ids when a list is imported into '
          'the watchlist', () async {
        await provider.init();
        expect(provider.watchlistIds, ['101']);

        await provider.importList('watchlist', ['101:movie', '7:tv']);

        expect(provider.watchlistIds, ['101', '7']);
        expect(provider.getListEntriesCached('watchlist'), [
          '101:movie',
          '7:tv',
        ]);
      });
    });

    group('moveItems', () {
      const movieA = MediaItem(
        id: 1,
        title: 'Alpha',
        overview: '',
        releaseDate: '2020-01-01',
      );
      const movieB = MediaItem(
        id: 2,
        title: 'Beta',
        overview: '',
        releaseDate: '2099-01-01', // future date -> canBeNotified is true
      );

      setUp(() {
        when(
          () => mockRepository.moveItems(any(), any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.addAllToList(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.toggleNotification(
            any(),
            autoNotify: any(named: 'autoNotify'),
          ),
        ).thenAnswer((_) async {});
      });

      test(
        'should move items to target, remove from source, and skip duplicates',
        () async {
          when(
            () => mockRepository.getListEntries('Favorites'),
          ).thenAnswer((_) async => ['1:movie', '2:movie']);
          when(
            () => mockRepository.getListEntries('Archive'),
          ).thenAnswer((_) async => ['1:movie']);
          when(
            () => mockRepository.getAllListNames(),
          ).thenAnswer((_) async => ['watchlist', 'Favorites', 'Archive']);
          await provider.init();

          await provider.moveItems([movieA, movieB], 'Favorites', 'Archive');

          verify(
            () => mockRepository.moveItems(
              [movieA, movieB],
              'Favorites',
              'Archive',
            ),
          ).called(1);
          expect(provider.getListEntriesCached('Favorites'), isEmpty);
          expect(provider.getListEntriesCached('Archive'), [
            '1:movie',
            '2:movie',
          ]);
        },
      );

      test(
        'should copy items when keepSource is true without removing from source',
        () async {
          when(
            () => mockRepository.getListEntries('Favorites'),
          ).thenAnswer((_) async => ['1:movie', '2:movie']);
          when(
            () => mockRepository.getListEntries('Archive'),
          ).thenAnswer((_) async => ['1:movie']);
          when(
            () => mockRepository.getAllListNames(),
          ).thenAnswer((_) async => ['watchlist', 'Favorites', 'Archive']);
          await provider.init();

          await provider.moveItems(
            [movieA, movieB],
            'Favorites',
            'Archive',
            keepSource: true,
          );

          verify(
            () => mockRepository.addAllToList([movieA, movieB], 'Archive'),
          ).called(1);
          verifyNever(() => mockRepository.moveItems(any(), any(), any()));
          expect(provider.getListEntriesCached('Favorites'), [
            '1:movie',
            '2:movie',
          ]);
          expect(provider.getListEntriesCached('Archive'), [
            '1:movie',
            '2:movie',
          ]);
        },
      );

      test(
        'should update watchlistIds and auto-notify when moving into watchlist',
        () async {
          when(
            () => mockRepository.getListEntries('Favorites'),
          ).thenAnswer((_) async => ['1:movie', '2:movie']);
          await provider.init();
          expect(provider.watchlistIds, ['101']);

          await provider.moveItems([movieA, movieB], 'Favorites', 'watchlist');

          expect(provider.watchlistIds, ['101', '1', '2']);
          expect(provider.getListEntriesCached('watchlist'), [
            '101:movie',
            '1:movie',
            '2:movie',
          ]);
          verify(
            () => mockRepository.toggleNotification(movieB, autoNotify: true),
          ).called(1);
          verifyNever(
            () => mockRepository.toggleNotification(movieA, autoNotify: true),
          );
        },
      );

      test(
        'should remove from watchlistIds when moving out of watchlist',
        () async {
          await provider.init();
          expect(provider.watchlistIds, ['101']);

          await provider.moveItems([tMovie], 'watchlist', 'Favorites');

          expect(provider.watchlistIds, isEmpty);
          expect(provider.getListEntriesCached('watchlist'), isEmpty);
          expect(provider.getListEntriesCached('Favorites'), ['101:movie']);
        },
      );

      test('should roll back optimistic state on repository failure', () async {
        when(
          () => mockRepository.moveItems(any(), any(), any()),
        ).thenThrow(Exception('DB error'));
        await provider.init();

        await expectLater(
          () => provider.moveItems([tMovie], 'watchlist', 'Favorites'),
          throwsA(isA<Exception>()),
        );

        expect(provider.watchlistIds, ['101']);
        expect(provider.getListEntriesCached('watchlist'), ['101:movie']);
        expect(provider.getListEntriesCached('Favorites'), isEmpty);
      });
    });
  });
}
