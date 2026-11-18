import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/services/in_progress_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaListLocalDataSource local;
  late MockMediaCache cache;
  late InProgressService service;

  final now = DateTime(2026, 11, 14, 21);
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));

  QuickAddItemModel next(
    int tmdbId, {
    int season = 1,
    int episode = 2,
    DateTime? insertedAt,
    String type = 'tv',
    String? title,
    String? posterPath,
    int? runtime,
  }) => QuickAddItemModel(
    isarId: tmdbId * 100 + season * 10 + episode,
    tmdbId: tmdbId,
    type: type,
    seasonNumber: season,
    episodeNumber: episode,
    insertedAt: insertedAt ?? daysAgo(1),
    title: title ?? 'Show $tmdbId',
    posterPath: posterPath,
    runtime: runtime,
  );

  SeenItemModel seen(
    int tmdbId,
    int season,
    int episode,
    DateTime date, {
    String type = 'tv',
  }) => SeenItemModel(
    tmdbId: tmdbId,
    type: type,
    title: 'Show $tmdbId',
    seenDate: date,
    seasonNumber: season,
    episodeNumber: episode,
  );

  MediaItem series(int id, {int? episodes, String? title, String? poster}) =>
      MediaItem(
        id: id,
        title: title ?? 'Show $id',
        overview: '',
        releaseDate: '',
        mediaType: MediaType.tv,
        numberOfEpisodes: episodes,
        posterPath: poster,
      );

  void stub({
    List<QuickAddItemModel> queue = const [],
    List<SeenItemModel> history = const [],
    Map<int, MediaItem> cached = const {},
  }) {
    when(() => local.getQuickAddItems()).thenAnswer((_) async => queue);
    when(() => local.getAllSeenItems()).thenAnswer((_) async => history);
    when(() => cache.getItems(any())).thenAnswer((invocation) async {
      final keys =
          invocation.positionalArguments.first as List<(int, MediaType)>;
      return [for (final key in keys) cached[key.$1]];
    });
  }

  setUpAll(() => registerFallbackValue(<(int, MediaType)>[]));

  setUp(() {
    local = MockMediaListLocalDataSource();
    cache = MockMediaCache();
    service = InProgressService(localDataSource: local, cache: cache);
  });

  group('InProgressService.getInProgressItems', () {
    test('should be empty when nothing is queued', () async {
      stub(history: [seen(1, 1, 1, daysAgo(2))]);

      expect(await service.getInProgressItems(now: now), isEmpty);
      verifyNever(() => cache.getItems(any()));
    });

    test(
      'should describe the next episode, the progress and the last activity',
      () async {
        stub(
          queue: [next(1, season: 2, episode: 4, runtime: 50)],
          history: [
            seen(1, 1, 1, daysAgo(40)),
            seen(1, 2, 3, daysAgo(2)),
            // A second viewing of the same episode counts once.
            seen(1, 1, 1, daysAgo(3)),
            // Specials are not part of the episode count.
            seen(1, 0, 1, daysAgo(5)),
          ],
          cached: {
            1: series(1, episodes: 8, title: 'Severance', poster: '/s.jpg'),
          },
        );

        final item = (await service.getInProgressItems(now: now)).single;

        expect(item.tmdbId, 1);
        expect(item.title, 'Severance');
        expect(item.posterPath, '/s.jpg');
        expect(item.seasonNumber, 2);
        expect(item.episodeNumber, 4);
        expect(item.runtime, 50);
        expect(item.seenEpisodes, 2);
        expect(item.totalEpisodes, 8);
        expect(item.progress, 0.25);
        expect(item.lastActivity, daysAgo(2));
        expect(item.paused, isFalse);
        expect(item.next.isarId, 124);
      },
    );

    test('should sort by last activity, most recent first', () async {
      stub(
        queue: [next(1), next(2), next(3)],
        history: [
          seen(1, 1, 1, daysAgo(10)),
          seen(2, 1, 1, daysAgo(1)),
          seen(3, 1, 1, daysAgo(5)),
        ],
      );

      final items = await service.getInProgressItems(now: now);

      expect(items.map((item) => item.tmdbId), [2, 3, 1]);
    });

    test(
      'should pause a series after more than 30 days without viewing',
      () async {
        stub(
          queue: [next(1), next(2)],
          history: [seen(1, 1, 1, daysAgo(30)), seen(2, 1, 1, daysAgo(31))],
        );

        final items = await service.getInProgressItems(now: now);

        expect(items.map((item) => (item.tmdbId, item.paused)), [
          (1, false),
          (2, true),
        ]);
      },
    );

    test(
      'should leave out a finished series, which has no next episode',
      () async {
        stub(
          queue: [next(1)],
          history: [
            seen(1, 1, 1, daysAgo(2)),
            for (var episode = 1; episode <= 6; episode++)
              seen(2, 1, episode, daysAgo(1)),
          ],
          cached: {2: series(2, episodes: 6)},
        );

        final items = await service.getInProgressItems(now: now);

        expect(items.map((item) => item.tmdbId), [1]);
      },
    );

    test(
      'should have no progress when the episode count is not cached',
      () async {
        stub(
          queue: [next(1), next(2), next(3)],
          history: [
            seen(1, 1, 1, daysAgo(1)),
            seen(2, 1, 1, daysAgo(2)),
            seen(3, 1, 1, daysAgo(3)),
          ],
          cached: {2: series(2), 3: series(3, episodes: 0)},
        );

        final items = await service.getInProgressItems(now: now);

        for (final item in items) {
          expect(item.progress, isNull, reason: '${item.tmdbId}');
          expect(item.totalEpisodes, isNull, reason: '${item.tmdbId}');
          expect(item.seenEpisodes, 1, reason: '${item.tmdbId}');
        }
      },
    );

    test('should never report more than 100 %', () async {
      stub(
        queue: [next(1, season: 1, episode: 1)],
        history: [
          for (var episode = 1; episode <= 5; episode++)
            seen(1, 1, episode, daysAgo(1)),
        ],
        // Stale cache: fewer episodes than already seen.
        cached: {1: series(1, episodes: 4)},
      );

      final item = (await service.getInProgressItems(now: now)).single;

      expect(item.progress, 1.0);
    });

    test('should keep one entry per series, the streak watched last', () async {
      stub(
        queue: [
          next(1, season: 1, episode: 3, insertedAt: daysAgo(20)),
          next(1, season: 4, episode: 6, insertedAt: daysAgo(2)),
        ],
        history: [seen(1, 1, 2, daysAgo(20)), seen(1, 4, 5, daysAgo(2))],
      );

      final item = (await service.getInProgressItems(now: now)).single;

      expect((item.seasonNumber, item.episodeNumber), (4, 6));
    });

    test('should ignore entries that are not an episode of a series', () async {
      stub(
        queue: [
          next(1, type: 'movie'),
          QuickAddItemModel(tmdbId: 2, type: 'tv', insertedAt: daysAgo(1)),
        ],
        history: [seen(1, 1, 1, daysAgo(1), type: 'movie')],
      );

      expect(await service.getInProgressItems(now: now), isEmpty);
    });

    test(
      'should fall back to the queue date and the stored title without history or cache',
      () async {
        stub(
          queue: [next(1, insertedAt: daysAgo(45), title: 'Stored')],
        );

        final item = (await service.getInProgressItems(now: now)).single;

        expect(item.title, 'Stored');
        expect(item.lastActivity, daysAgo(45));
        expect(item.paused, isTrue);
        expect(item.seenEpisodes, 0);
      },
    );

    test('should reset seenEpisodes and progress to 0 during active rewatch', () async {
      final rewatchStart = daysAgo(2);
      final rewatchService = InProgressService(
        localDataSource: local,
        cache: cache,
        getRewatchStart: (id) => id == 1 ? rewatchStart : null,
      );

      stub(
        queue: [next(1, season: 1, episode: 1, insertedAt: rewatchStart)],
        history: [
          seen(1, 1, 1, daysAgo(30)),
          seen(1, 1, 2, daysAgo(29)),
        ],
        cached: {1: series(1, episodes: 10)},
      );

      final items = await rewatchService.getInProgressItems(now: now);
      expect(items, hasLength(1));
      final item = items.single;
      expect(item.seenEpisodes, 0);
      expect(item.progress, 0.0);
    });
  });
}
