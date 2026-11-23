import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/cache/media_cache.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/notification_refresh_service.dart';
import 'package:mediavore/features/search/data/services/quick_add_service.dart';
import 'package:mediavore/features/search/data/services/seen_service.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaListLocalDataSource extends Mock
    implements MediaListLocalDataSource {}

class MockMediaCache extends Mock implements MediaCache {}

class MockMediaDetailsService extends Mock implements MediaDetailsService {}

class MockNotificationRefreshService extends Mock
    implements NotificationRefreshService {}

class MockQuickAddService extends Mock implements QuickAddService {}

void main() {
  late MockMediaListLocalDataSource localDataSource;
  late MockMediaCache cache;
  late MockMediaDetailsService details;
  late MockNotificationRefreshService notifications;
  late MockQuickAddService quickAdd;
  late SeenService service;

  final tMediaDetails = MediaDetails(
    item: const MediaItem(
      id: 42,
      title: 'Breaking Bad',
      overview: 'Chemistry teacher',
      releaseDate: '2008-01-20',
      mediaType: MediaType.tv,
      genres: ['Drama', 'Crime'],
    ),
    cast: const [],
  );

  final tDate = DateTime(2026);

  setUpAll(() {
    registerFallbackValue(MediaType.tv);
    registerFallbackValue(
      SeenItem(
        tmdbId: 42,
        type: MediaType.tv,
        title: 'Breaking Bad',
        seenDate: DateTime(2026),
      ),
    );
    registerFallbackValue(<SeenItemModel>[]);
  });

  setUp(() {
    localDataSource = MockMediaListLocalDataSource();
    cache = MockMediaCache();
    details = MockMediaDetailsService();
    notifications = MockNotificationRefreshService();
    quickAdd = MockQuickAddService();

    when(() => localDataSource.markManyAsSeen(any())).thenAnswer((_) async {});
    when(() => notifications.refreshAfterSeen(any())).thenAnswer((_) async {});
    when(() => quickAdd.queueNextAfterSeen(any())).thenAnswer((_) async {});

    service = SeenService(
      localDataSource: localDataSource,
      cache: cache,
      details: details,
      notifications: notifications,
      quickAdd: quickAdd,
    );
  });

  group('SeenService.markManyAsSeen', () {
    test(
      'resolves details at most once per series and season details once per season',
      () async {
        when(
          () => details.getMediaDetails(42, type: MediaType.tv),
        ).thenAnswer((_) async => tMediaDetails);

        when(() => details.getSeasonDetails(42, 1)).thenAnswer(
          (_) async => {
            'episodes': [
              {'episode_number': 1, 'runtime': 58},
              {'episode_number': 2, 'runtime': 48},
            ],
          },
        );

        when(() => details.getSeasonDetails(42, 2)).thenAnswer(
          (_) async => {
            'episodes': [
              {'episode_number': 1, 'runtime': 47},
            ],
          },
        );

        when(
          () => details.resolveRuntimeAndGenres(
            tmdbId: any(named: 'tmdbId'),
            type: any(named: 'type'),
            seasonNumber: any(named: 'seasonNumber'),
            episodeNumber: any(named: 'episodeNumber'),
            runtime: any(named: 'runtime'),
            genres: any(named: 'genres'),
            fetchDetails: any(named: 'fetchDetails'),
            fetchSeason: any(named: 'fetchSeason'),
          ),
        ).thenAnswer((invocation) async {
          final tmdbId = invocation.namedArguments[#tmdbId] as int;
          final type = invocation.namedArguments[#type] as MediaType;
          final season = invocation.namedArguments[#seasonNumber] as int?;
          final episode = invocation.namedArguments[#episodeNumber] as int?;
          final fetchDetails =
              invocation.namedArguments[#fetchDetails]
                  as Future<MediaDetails?> Function(int, MediaType)?;
          final fetchSeason =
              invocation.namedArguments[#fetchSeason]
                  as Future<Map<String, dynamic>?> Function(int, int)?;

          final d = await fetchDetails!(tmdbId, type);
          int? rt;
          if (season != null && episode != null) {
            final s = await fetchSeason!(tmdbId, season);
            final eps = s?['episodes'] as List?;
            if (eps != null) {
              for (final ep in eps) {
                if (ep is Map && ep['episode_number'] == episode) {
                  rt = ep['runtime'] as int?;
                  break;
                }
              }
            }
          }
          return (runtime: rt, genres: d?.item.genres);
        });

        final episodes = [
          SeenItem(
            tmdbId: 42,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seasonNumber: 1,
            episodeNumber: 1,
            seenDate: tDate,
          ),
          SeenItem(
            tmdbId: 42,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seasonNumber: 1,
            episodeNumber: 2,
            seenDate: tDate,
          ),
          SeenItem(
            tmdbId: 42,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seasonNumber: 2,
            episodeNumber: 1,
            seenDate: tDate,
          ),
        ];

        await service.markManyAsSeen(episodes);

        // Verify details fetched only once for show 42 despite 3 episodes
        verify(() => details.getMediaDetails(42, type: MediaType.tv)).called(1);
        // Season 1 fetched only once despite 2 episodes in S1
        verify(() => details.getSeasonDetails(42, 1)).called(1);
        // Season 2 fetched once
        verify(() => details.getSeasonDetails(42, 2)).called(1);

        verify(
          () => localDataSource.markManyAsSeen(any(that: hasLength(3))),
        ).called(1);
      },
    );

    test(
      'bypasses details lookup when runtime and genres are already provided',
      () async {
        when(
          () => details.resolveRuntimeAndGenres(
            tmdbId: any(named: 'tmdbId'),
            type: any(named: 'type'),
            seasonNumber: any(named: 'seasonNumber'),
            episodeNumber: any(named: 'episodeNumber'),
            runtime: any(named: 'runtime'),
            genres: any(named: 'genres'),
            fetchDetails: any(named: 'fetchDetails'),
            fetchSeason: any(named: 'fetchSeason'),
          ),
        ).thenAnswer((invocation) async {
          return (
            runtime: invocation.namedArguments[#runtime] as int?,
            genres: invocation.namedArguments[#genres] as List<String>?,
          );
        });

        final episodes = [
          SeenItem(
            tmdbId: 42,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seasonNumber: 1,
            episodeNumber: 1,
            runtime: 58,
            genres: const ['Drama'],
            seenDate: tDate,
          ),
          SeenItem(
            tmdbId: 42,
            type: MediaType.tv,
            title: 'Breaking Bad',
            seasonNumber: 1,
            episodeNumber: 2,
            runtime: 48,
            genres: const ['Drama'],
            seenDate: tDate,
          ),
        ];

        await service.markManyAsSeen(episodes);

        verifyNever(
          () => details.getMediaDetails(any(), type: any(named: 'type')),
        );
        verifyNever(() => details.getSeasonDetails(any(), any()));
        verify(
          () => localDataSource.markManyAsSeen(any(that: hasLength(2))),
        ).called(1);
      },
    );

    group('post-mark refresh (#431)', () {
      SeenItem episode(int season, int number) => SeenItem(
        tmdbId: 42,
        type: MediaType.tv,
        title: 'Breaking Bad',
        seasonNumber: season,
        episodeNumber: number,
        runtime: 45,
        genres: const ['Drama'],
        seenDate: tDate,
      );

      setUp(() {
        when(
          () => details.resolveRuntimeAndGenres(
            tmdbId: any(named: 'tmdbId'),
            type: any(named: 'type'),
            seasonNumber: any(named: 'seasonNumber'),
            episodeNumber: any(named: 'episodeNumber'),
            runtime: any(named: 'runtime'),
            genres: any(named: 'genres'),
            fetchDetails: any(named: 'fetchDetails'),
            fetchSeason: any(named: 'fetchSeason'),
          ),
        ).thenAnswer(
          (_) async => (runtime: 45, genres: const <String>['Drama']),
        );
      });

      test(
        'should return only once notifications and Quick Add are refreshed',
        () async {
          final refresh = Completer<void>();
          when(
            () => notifications.refreshAfterSeen(any()),
          ).thenAnswer((_) => refresh.future);

          var done = false;
          final future = service
              .markManyAsSeen([episode(1, 1), episode(1, 2)])
              .then((_) => done = true);

          await pumpEventQueue();
          expect(done, isFalse);
          verifyNever(() => quickAdd.queueNextAfterSeen(any()));

          refresh.complete();
          await future;

          expect(done, isTrue);
          verifyInOrder([
            () => localDataSource.markManyAsSeen(any()),
            () => notifications.refreshAfterSeen(
              any(
                that: isA<SeenItem>().having(
                  (i) => i.episodeNumber,
                  'episodeNumber',
                  2,
                ),
              ),
            ),
            () => quickAdd.queueNextAfterSeen(any()),
          ]);
        },
      );

      test(
        'should still queue Quick Add and not fail the batch when the notification refresh fails',
        () async {
          when(
            () => notifications.refreshAfterSeen(any()),
          ).thenThrow(Exception('offline'));

          await expectLater(service.markManyAsSeen([episode(1, 1)]), completes);
          verify(() => localDataSource.markManyAsSeen(any())).called(1);
          verify(() => quickAdd.queueNextAfterSeen(any())).called(1);
        },
      );
    });

    test(
      'should memoize failed details and season lookups for the whole batch',
      () async {
        when(
          () => details.getMediaDetails(42, type: MediaType.tv),
        ).thenThrow(Exception('offline'));
        when(
          () => details.getSeasonDetails(42, 1),
        ).thenAnswer((_) async => throw Exception('offline'));
        when(
          () => details.resolveRuntimeAndGenres(
            tmdbId: any(named: 'tmdbId'),
            type: any(named: 'type'),
            seasonNumber: any(named: 'seasonNumber'),
            episodeNumber: any(named: 'episodeNumber'),
            runtime: any(named: 'runtime'),
            genres: any(named: 'genres'),
            fetchDetails: any(named: 'fetchDetails'),
            fetchSeason: any(named: 'fetchSeason'),
          ),
        ).thenAnswer((invocation) async {
          final fetchDetails =
              invocation.namedArguments[#fetchDetails]
                  as Future<MediaDetails?> Function(int, MediaType);
          final fetchSeason =
              invocation.namedArguments[#fetchSeason]
                  as Future<Map<String, dynamic>?> Function(int, int);
          final d = await fetchDetails(42, MediaType.tv);
          final s = await fetchSeason(42, 1);
          return (runtime: s == null ? null : 0, genres: d?.item.genres);
        });

        await service.markManyAsSeen([
          for (var e = 1; e <= 3; e++)
            SeenItem(
              tmdbId: 42,
              type: MediaType.tv,
              title: 'Breaking Bad',
              seasonNumber: 1,
              episodeNumber: e,
              seenDate: tDate,
            ),
        ]);

        verify(() => details.getMediaDetails(42, type: MediaType.tv)).called(1);
        verify(() => details.getSeasonDetails(42, 1)).called(1);
        verify(
          () => localDataSource.markManyAsSeen(any(that: hasLength(3))),
        ).called(1);
      },
    );
  });
}
