import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/di/definitions_loader.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/achievements/data/datasources/achievement_media_source.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/achievements/data/repositories/achievement_repository_impl.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

class _Loader implements DefinitionsLoader {
  final List<Map<String, dynamic>> defs;
  _Loader(this.defs);
  @override
  Future<List<Map<String, dynamic>>> load() async => defs;
}

class _FakeMediaSource implements AchievementMediaSource {
  final Map<int, ShowInfo> showData;
  final Map<int, List<SagaPart>> sagaData;
  _FakeMediaSource({this.showData = const {}, this.sagaData = const {}});

  @override
  Future<Map<int, ShowInfo>> shows(Set<int> tvIds) async => {
    for (final id in tvIds)
      if (showData[id] != null) id: showData[id]!,
  };

  @override
  Future<Map<int, List<SagaPart>>> sagas(Set<int> movieIds) async => {
    for (final id in movieIds)
      if (sagaData[id] != null) id: sagaData[id]!,
  };

  @override
  Future<Map<(int, String), TitleInfo>> titles(Set<(int, String)> keys) async =>
      const {};

  @override
  Future<Map<int, String>?> episodeAirDates(int tvId, int season) async => null;
}

Map<String, dynamic> _def(String type, int target, {String? id}) => {
  'id': id ?? '${type}_$target',
  'title': 'T',
  'description': 'D',
  'iconPath': 'I',
  'type': type,
  'params': {'target': target},
};

SeenItemModel _ep(int show, int season, int episode, DateTime date) =>
    SeenItemModel(
      tmdbId: show,
      type: 'tv',
      title: 'S$show',
      seenDate: date,
      seasonNumber: season,
      episodeNumber: episode,
    );

SeenItemModel _movie(int id, DateTime date) =>
    SeenItemModel(tmdbId: id, type: 'movie', title: 'M$id', seenDate: date);

void main() {
  late Isar isar;
  late MockMediaListLocalDataSource local;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_collection_achievements';
    Directory(tempPath).createSync(recursive: true);
  });

  setUp(() async {
    isar = await Isar.open(
      [AchievementModelSchema, SeenItemModelSchema],
      directory: tempPath,
      name: 'test_collection_achievements_db',
      inspector: false,
    );
    local = MockMediaListLocalDataSource();
    when(() => local.getListItems('watchlist')).thenAnswer((_) async => []);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  Future<Map<String, Achievement>> evaluate(
    List<Map<String, dynamic>> defs,
    List<SeenItemModel> seen, {
    AchievementMediaSource? source,
  }) async {
    when(() => local.getAllSeenItems()).thenAnswer((_) async => seen);
    final repo = AchievementRepositoryImpl(
      isar,
      local,
      definitionsLoader: _Loader(defs),
      mediaSource: source ?? _FakeMediaSource(),
    );
    return {for (final a in await repo.getAchievements()) a.id: a};
  }

  group('ShowInfo', () {
    test('should only count aired episodes of regular seasons', () {
      const info = ShowInfo(
        status: 'Returning Series',
        episodeCounts: {1: 10, 2: 8, 3: 6},
        lastSeason: 2,
        lastEpisode: 3,
      );
      expect(info.airedEpisodeCounts, {1: 10, 2: 3});
      expect(info.isFinished, isFalse);
      expect(const ShowInfo(episodeCounts: {1: 4}).airedEpisodeCounts, {1: 4});
    });
  });

  group('series achievements', () {
    // Show 1: ended, 2 seasons of 2 episodes, fully seen.
    // Show 2: running, season 2 airing (1 of 3 aired), all aired seen.
    // Show 3: ended, one episode missing.
    final source = _FakeMediaSource(
      showData: {
        1: const ShowInfo(
          status: 'Ended',
          episodeCounts: {1: 2, 2: 2},
          lastSeason: 2,
          lastEpisode: 2,
        ),
        2: const ShowInfo(
          status: 'Returning Series',
          episodeCounts: {1: 2, 2: 3},
          lastSeason: 2,
          lastEpisode: 1,
        ),
        3: const ShowInfo(
          status: 'Canceled',
          episodeCounts: {1: 2},
          lastSeason: 1,
          lastEpisode: 2,
        ),
      },
    );
    final seen = [
      _ep(1, 1, 1, DateTime(2024, 1, 1)),
      _ep(1, 1, 2, DateTime(2024, 1, 2)),
      _ep(2, 1, 1, DateTime(2024, 1, 3)),
      _ep(1, 2, 1, DateTime(2024, 1, 4)),
      _ep(2, 1, 2, DateTime(2024, 1, 5)),
      _ep(1, 2, 2, DateTime(2024, 1, 6)),
      _ep(1, 2, 2, DateTime(2024, 3, 1)), // rewatch: first view counts
      _ep(2, 2, 1, DateTime(2024, 1, 7)),
      _ep(3, 1, 1, DateTime(2024, 1, 8)),
      _ep(3, 0, 1, DateTime(2024, 1, 9)), // special: ignored
    ];

    test('should count fully aired seasons seen entirely', () async {
      final a = await evaluate(
        [_def('season_complete', 3), _def('season_complete', 4)],
        seen,
        source: source,
      );

      // Show 1 S1 (Jan 2), show 2 S1 (Jan 5), show 1 S2 (Jan 6).
      expect(a['season_complete_3']!.isUnlocked, isTrue);
      expect(a['season_complete_3']!.unlockedAt, DateTime(2024, 1, 6));
      expect(a['season_complete_4']!.isUnlocked, isFalse);
      expect(a['season_complete_4']!.progressLabel, '3/4');
    });

    test('should split caught-up series into ended and running', () async {
      final a = await evaluate(
        [
          _def('series_complete', 1),
          _def('series_complete', 2),
          _def('up_to_date', 1),
        ],
        seen,
        source: source,
      );

      expect(a['series_complete_1']!.unlockedAt, DateTime(2024, 1, 6));
      expect(a['series_complete_2']!.progressLabel, '1/2');
      expect(a['up_to_date_1']!.unlockedAt, DateTime(2024, 1, 7));
    });

    test('should not count series missing from the cache', () async {
      final a = await evaluate([_def('series_complete', 1)], seen);
      expect(a['series_complete_1']!.isUnlocked, isFalse);
      expect(a['series_complete_1']!.progress, 0);
    });
  });

  group('saga achievements', () {
    test('should need every released part of a saga', () async {
      const saga = [
        SagaPart(1, '2001-01-01'),
        SagaPart(2, '2003-01-01'),
        SagaPart(3, '2999-01-01'), // unreleased
        SagaPart(4, ''), // no date
      ];
      final a = await evaluate(
        [_def('saga_complete', 1), _def('saga_complete', 2)],
        [
          _movie(1, DateTime(2024, 1, 1)),
          _movie(2, DateTime(2024, 1, 2)),
          _movie(5, DateTime(2024, 1, 3)),
          _movie(7, DateTime(2024, 1, 4)),
        ],
        source: _FakeMediaSource(
          sagaData: {
            1: saga,
            2: saga, // same saga seen twice: counted once
            5: const [SagaPart(5, '2010-01-01'), SagaPart(6, '2012-01-01')],
            7: const [SagaPart(7, '2010-01-01')], // single film
          },
        ),
      );

      expect(a['saga_complete_1']!.unlockedAt, DateTime(2024, 1, 2));
      expect(a['saga_complete_2']!.progressLabel, '1/2');
    });
  });

  group('watchlist_clear', () {
    final seen = [
      _movie(1, DateTime(2024, 1, 1)),
      _movie(2, DateTime(2024, 1, 2)),
    ];

    test('should unlock when every watchlist title is seen', () async {
      when(() => local.getListItems('watchlist')).thenAnswer(
        (_) async => [MediaListItem(id: 1, type: 'movie', title: 'M1')],
      );
      final a = await evaluate([_def('watchlist_clear', 2)], seen);
      expect(a['watchlist_clear_2']!.isUnlocked, isTrue);
    });

    test('should stay locked with an unseen title', () async {
      when(() => local.getListItems('watchlist')).thenAnswer(
        (_) async => [
          MediaListItem(id: 1, type: 'movie', title: 'M1'),
          MediaListItem(id: 9, type: 'movie', title: 'M9'),
        ],
      );
      final a = await evaluate([_def('watchlist_clear', 2)], seen);
      expect(a['watchlist_clear_2']!.isUnlocked, isFalse);
      expect(a['watchlist_clear_2']!.progressLabel, '1/2');
    });

    test('should need the minimum history', () async {
      final a = await evaluate([_def('watchlist_clear', 3)], seen);
      expect(a['watchlist_clear_3']!.isUnlocked, isFalse);
      expect(a['watchlist_clear_3']!.progressLabel, '2/3');
    });
  });

  test('should keep persisted unlocks of cache-based types only', () async {
    final unlockedAt = DateTime(2024, 5, 1);
    await isar.writeTxn(() async {
      await isar.achievementModels.putAll([
        AchievementModel(achievementId: 'saga', unlockedAt: unlockedAt),
        AchievementModel(achievementId: 'movies', unlockedAt: unlockedAt),
      ]);
    });
    final a = await evaluate([
      _def('saga_complete', 1, id: 'saga'),
      {
        ..._def('count', 1, id: 'movies'),
        'params': {'mediaType': 'movie', 'target': 1},
      },
    ], []);

    expect(a['saga']!.isUnlocked, isTrue);
    expect(a['saga']!.unlockedAt, unlockedAt);
    expect(a['saga']!.progress, 1.0);
    expect(a['movies']!.isUnlocked, isFalse);
  });

  group('CachedAchievementMediaSource', () {
    late MockMediaCache cache;
    late CachedAchievementMediaSource source;

    setUpAll(() => registerFallbackValue(MediaType.tv));

    setUp(() {
      cache = MockMediaCache();
      source = CachedAchievementMediaSource(cache);
    });

    test(
      'should fall back to the details when the item has no seasons',
      () async {
        const listRow = MediaItem(
          id: 1,
          title: 'S',
          overview: '',
          releaseDate: '',
          mediaType: MediaType.tv,
        );
        when(() => cache.getItems(any())).thenAnswer((_) async => [listRow]);
        when(() => cache.getDetails(1, MediaType.tv)).thenAnswer(
          (_) async => MediaDetails(
            item: listRow.copyWith(
              status: 'Ended',
              seasons: const [
                TVSeason(id: 10, seasonNumber: 0, episodeCount: 3),
                TVSeason(id: 11, seasonNumber: 1, episodeCount: 8),
              ],
            ),
            cast: const [],
          ),
        );

        final shows = await source.shows({1});
        expect(shows[1]!.episodeCounts, {1: 8});
        expect(shows[1]!.isFinished, isTrue);
      },
    );

    test('should decode a saga once and retry uncached movies', () async {
      when(() => cache.getCollectionParts(1)).thenAnswer(
        (_) async => const [
          MediaItem(id: 1, title: 'A', overview: '', releaseDate: '2001-01-01'),
          MediaItem(id: 2, title: 'B', overview: '', releaseDate: '2002-01-01'),
        ],
      );
      when(() => cache.getCollectionParts(2)).thenAnswer((_) async => null);

      await source.sagas({1, 2});
      final sagas = await source.sagas({1, 2});

      expect(sagas.keys, [1]);
      expect(sagas[1]!.map((p) => p.id), [1, 2]);
      verify(() => cache.getCollectionParts(1)).called(1);
      verify(() => cache.getCollectionParts(2)).called(2);
    });
  });
}
