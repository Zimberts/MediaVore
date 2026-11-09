import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/watch_tail.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/data/services/next_episode_scanner.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRemoteDataSource remote;
  late MockMediaCache cache;
  late NextEpisodeScanner scanner;

  final now = DateTime(2026, 6, 1);
  final past = '2026-01-01';
  final future = '2026-12-01';

  MediaItem series(List<TVSeason> seasons) => MediaItem(
    id: 7,
    title: 'Show',
    overview: '',
    releaseDate: '',
    mediaType: MediaType.tv,
    seasons: seasons,
  );

  TVSeason season(int number, {int episodeCount = 3}) =>
      TVSeason(id: number, seasonNumber: number, episodeCount: episodeCount);

  Map<String, dynamic> episodes(List<(int, String?)> eps) => {
    'episodes': [
      for (final (number, airDate) in eps)
        {'episode_number': number, 'air_date': airDate, 'runtime': 40},
    ],
  };

  WatchTail tail(int season, int episode) => WatchTail(
    seasonNumber: season,
    episodeNumber: episode,
    seenDate: DateTime(2026, 5, 1),
  );

  void stubCachedSeason(int number, Map<String, dynamic>? data) {
    when(() => cache.getSeason(7, number)).thenAnswer((_) async => data);
  }

  setUpAll(() => registerFallbackValue(MediaType.tv));

  setUp(() {
    remote = MockMediaRemoteDataSource();
    cache = MockMediaCache();
    scanner = NextEpisodeScanner(
      MediaDetailsService(remoteDataSource: remote, cache: cache),
    );
    when(() => cache.cacheSeason(any(), any(), any())).thenAnswer((_) async {});
    when(() => cache.getItem(any(), any())).thenAnswer((_) async => null);
    when(
      () => cache.getSeasonUpdateDate(any(), any()),
    ).thenAnswer((_) async => null);
  });

  group('NextEpisodeScanner.scan', () {
    test('should be incomplete without a series', () async {
      final result = await scanner.scan(
        null,
        tail(1, 1),
        {},
        forceRemote: false,
        now: now,
      );

      expect(result.episode, isNull);
      expect(result.complete, isFalse);
    });

    test('should be incomplete when the series has no seasons', () async {
      final result = await scanner.scan(
        series([]),
        tail(1, 1),
        {},
        forceRemote: false,
        now: now,
      );

      expect(result.episode, isNull);
      expect(result.complete, isFalse);
    });

    test('should skip specials and seasons before the tail', () async {
      stubCachedSeason(2, episodes([(1, past), (2, past)]));

      final result = await scanner.scan(
        series([season(0), season(1), season(2)]),
        tail(2, 1),
        {},
        forceRemote: false,
        now: now,
      );

      expect(result.episode?.seasonNumber, 2);
      expect(result.episode?.episodeNumber, 2);
      expect(result.episode?.runtime, 40);
      expect(result.complete, isTrue);
      verifyNever(() => cache.getSeason(7, 0));
      verifyNever(() => cache.getSeason(7, 1));
    });

    test(
      'should prefer an aired unseen episode over an announced one',
      () async {
        stubCachedSeason(1, episodes([(1, past), (2, past), (3, past)]));
        stubCachedSeason(2, episodes([(1, future)]));

        final result = await scanner.scan(
          series([season(1), season(2)]),
          tail(1, 1),
          {episodeKey(1, 2)},
          forceRemote: false,
          now: now,
        );

        expect(result.episode?.seasonNumber, 1);
        expect(result.episode?.episodeNumber, 3);
        // The first aired unseen episode ends the scan.
        verifyNever(() => cache.getSeason(7, 2));
      },
    );

    test(
      'should fall back to the announced episode once aired ones are seen',
      () async {
        stubCachedSeason(1, episodes([(1, past), (2, past)]));
        stubCachedSeason(2, episodes([(1, future), (2, null)]));

        final result = await scanner.scan(
          series([season(1), season(2)]),
          tail(1, 2),
          {},
          forceRemote: false,
          now: now,
        );

        expect(result.episode?.seasonNumber, 2);
        expect(result.episode?.episodeNumber, 1);
        expect(result.episode?.airDate, DateTime.parse(future));
        expect(result.complete, isTrue);
      },
    );

    test('should apply the where filter to both passes', () async {
      stubCachedSeason(1, episodes([(1, past), (2, future)]));

      final result = await scanner.scan(
        series([season(1)]),
        tail(1, 1),
        {},
        forceRemote: false,
        now: now,
        where: (episode) => isAired(episode, now),
      );

      expect(result.episode, isNull);
      expect(result.complete, isTrue);
    });

    test(
      'should mark the scan incomplete when a season with episodes fails',
      () async {
        stubCachedSeason(1, null);
        when(
          () => remote.getSeasonDetails(7, 1),
        ).thenThrow(Exception('offline'));

        final result = await scanner.scan(
          series([season(1, episodeCount: 5)]),
          tail(1, 1),
          {},
          forceRemote: false,
          now: now,
        );

        expect(result.episode, isNull);
        expect(result.complete, isFalse);
      },
    );

    test(
      'should stay complete when only an empty announced season fails',
      () async {
        stubCachedSeason(1, episodes([(1, past)]));
        stubCachedSeason(2, null);
        when(() => remote.getSeasonDetails(7, 2)).thenThrow(Exception('404'));

        final result = await scanner.scan(
          series([season(1), season(2, episodeCount: 0)]),
          tail(1, 1),
          {},
          forceRemote: false,
          now: now,
        );

        expect(result.episode, isNull);
        expect(result.complete, isTrue);
      },
    );

    test('should bypass the season cache when forced', () async {
      when(
        () => remote.getSeasonDetails(7, 1),
      ).thenAnswer((_) async => episodes([(1, past), (2, past)]));

      final result = await scanner.scan(
        series([season(1)]),
        tail(1, 1),
        {},
        forceRemote: true,
        now: now,
      );

      expect(result.episode?.episodeNumber, 2);
      verifyNever(() => cache.getSeason(any(), any()));
      verify(() => cache.cacheSeason(7, 1, any())).called(1);
    });
  });
}
