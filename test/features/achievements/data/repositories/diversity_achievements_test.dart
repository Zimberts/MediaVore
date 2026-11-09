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
  final Map<(int, String), TitleInfo> titleData;
  final Map<(int, int), Map<int, String>> airDates;
  _FakeMediaSource({this.titleData = const {}, this.airDates = const {}});

  @override
  Future<Map<int, ShowInfo>> shows(Set<int> tvIds) async => const {};

  @override
  Future<Map<int, List<SagaPart>>> sagas(Set<int> movieIds) async => const {};

  @override
  Future<Map<(int, String), TitleInfo>> titles(Set<(int, String)> keys) async =>
      {
        for (final k in keys)
          if (titleData[k] != null) k: titleData[k]!,
      };

  @override
  Future<Map<int, String>?> episodeAirDates(int tvId, int season) async =>
      airDates[(tvId, season)];
}

Map<String, dynamic> _def(
  String type,
  int target, {
  String? id,
  Map<String, dynamic> params = const {},
}) => {
  'id': id ?? '${type}_$target',
  'title': 'T',
  'description': 'D',
  'iconPath': 'I',
  'type': type,
  'params': {...params, 'target': target},
};

SeenItemModel _movie(int id, DateTime date, {List<String>? genres}) =>
    SeenItemModel(
      tmdbId: id,
      type: 'movie',
      title: 'M$id',
      seenDate: date,
      genres: genres,
    );

SeenItemModel _ep(int show, int season, int episode, DateTime date) =>
    SeenItemModel(
      tmdbId: show,
      type: 'tv',
      title: 'S$show',
      seenDate: date,
      seasonNumber: season,
      episodeNumber: episode,
    );

TitleInfo _info({
  String release = '2000-01-01',
  List<String>? countries = const ['US'],
  double? rating = 6.0,
  int? votes = 100,
}) => TitleInfo(
  releaseDate: release,
  originCountries: countries,
  voteAverage: rating,
  voteCount: votes,
);

void main() {
  late Isar isar;
  late MockMediaListLocalDataSource local;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_diversity_achievements';
    Directory(tempPath).createSync(recursive: true);
  });

  setUp(() async {
    isar = await Isar.open(
      [AchievementModelSchema, SeenItemModelSchema],
      directory: tempPath,
      name: 'test_diversity_achievements_db',
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

  final d1 = DateTime(2024, 1, 1, 20);
  final d2 = DateTime(2024, 1, 2, 20);
  final d3 = DateTime(2024, 1, 3, 20);

  test('distinct_genres should count genre ids across languages', () async {
    final a = await evaluate(
      [_def('distinct_genres', 3), _def('distinct_genres', 4, id: 'g4')],
      [
        _movie(1, d1, genres: ['Comedy', 'Unknown genre']),
        _movie(2, d2, genres: ['Comédie', 'Drama']), // same id as Comedy
        _movie(3, d3, genres: ['Horreur']),
      ],
    );
    expect(a['distinct_genres_3']!.isUnlocked, isTrue);
    expect(a['distinct_genres_3']!.unlockedAt, d3);
    expect(a['g4']!.progressLabel, '3/4');
  });

  test('distinct_countries should count each country once, by title', () async {
    final source = _FakeMediaSource(
      titleData: {
        (1, 'movie'): _info(countries: ['FR', 'BE']),
        (2, 'tv'): _info(countries: ['FR']),
        (3, 'movie'): _info(countries: ['JP']),
        // (4, movie) is not cached: ignored.
      },
    );
    final a = await evaluate(
      [_def('distinct_countries', 3), _def('distinct_countries', 4, id: 'c4')],
      [
        _movie(1, d1),
        _ep(2, 1, 1, d2),
        _movie(4, d2),
        _movie(3, d3),
        _movie(1, d3), // rewatch
      ],
      source: source,
    );
    expect(a['distinct_countries_3']!.unlockedAt, d3);
    expect(a['c4']!.progressLabel, '3/4');
    expect(a['c4']!.isUnlocked, isFalse);
  });

  test('distinct_decades should use the release year of each title', () async {
    final source = _FakeMediaSource(
      titleData: {
        (1, 'movie'): _info(release: '1999-12-31'),
        (2, 'movie'): _info(release: '1990-01-01'), // same decade
        (3, 'tv'): _info(release: '2000-01-01'),
        (4, 'movie'): _info(release: ''), // unknown
      },
    );
    final a = await evaluate(
      [_def('distinct_decades', 2), _def('distinct_decades', 3, id: 'd3')],
      [_movie(1, d1), _movie(2, d1), _movie(4, d2), _ep(3, 1, 1, d3)],
      source: source,
    );
    expect(a['distinct_decades_2']!.unlockedAt, d3);
    expect(a['d3']!.progressLabel, '2/3');
  });

  test(
    'released_before should count titles strictly before the year',
    () async {
      final source = _FakeMediaSource(
        titleData: {
          (1, 'movie'): _info(release: '1969-12-31'),
          (2, 'movie'): _info(release: '1970-01-01'), // not before 1970
          (3, 'tv'): _info(release: '1965-09-08'),
          (4, 'movie'): _info(release: ''),
        },
      );
      final def = _def('released_before', 2, params: {'year': 1970});
      final a = await evaluate(
        [def],
        [
          _movie(1, d1),
          _movie(1, d2), // rewatch: same title
          _movie(2, d2),
          _movie(4, d2),
          _ep(3, 1, 1, d3),
          _ep(3, 1, 2, d3), // same series
        ],
        source: source,
      );
      expect(a['released_before_2']!.isUnlocked, isTrue);
      expect(a['released_before_2']!.unlockedAt, d3);

      final three = await evaluate(
        [
          _def('released_before', 3, params: {'year': 1970}),
        ],
        [_movie(1, d1), _movie(2, d2), _ep(3, 1, 1, d3), _ep(3, 1, 2, d3)],
        source: source,
      );
      expect(three['released_before_3']!.progressLabel, '2/3');
    },
  );

  test('tmdb_rating should apply inclusive vote and rating bounds', () async {
    final source = _FakeMediaSource(
      titleData: {
        (1, 'movie'): _info(rating: 7.5, votes: 20), // both bounds hit
        (2, 'movie'): _info(rating: 9.0, votes: 501), // too many votes
        (3, 'movie'): _info(rating: 7.4, votes: 100), // rating too low
        (4, 'movie'): _info(rating: 9.0, votes: 19), // too few votes
        (5, 'tv'): _info(rating: 8.0, votes: 500),
        (6, 'movie'): _info(rating: null, votes: null),
      },
    );
    final a = await evaluate(
      [
        _def(
          'tmdb_rating',
          2,
          id: 'gem',
          params: {'minRating': 7.5, 'minVotes': 20, 'maxVotes': 500},
        ),
        _def('tmdb_rating', 2, id: 'popular', params: {'minVotes': 101}),
      ],
      [
        for (final id in [1, 2, 3, 4, 6]) _movie(id, d1),
        _ep(5, 1, 1, d2),
      ],
      source: source,
    );
    expect(a['gem']!.isUnlocked, isTrue);
    expect(a['gem']!.unlockedAt, d2);
    expect(a['popular']!.progressLabel, '2/2'); // 501 and 500 votes
  });

  test('day_one should compare calendar days within the delay', () async {
    final source = _FakeMediaSource(
      titleData: {
        (1, 'movie'): _info(release: '2024-01-01'), // seen the same day
        (2, 'movie'): _info(release: '2024-01-01'), // seen the next day
        (3, 'movie'): _info(release: '2024-01-01'), // seen 2 days later
        (4, 'movie'): _info(release: '2024-01-02'), // seen before release
      },
      airDates: {
        (10, 1): {1: '2024-01-02', 2: '2023-12-01'},
        // (10, 2) not cached
      },
    );
    final seen = [
      _movie(1, DateTime(2024, 1, 1, 23, 59)),
      _movie(2, d2),
      _movie(4, d1),
      _movie(3, d3),
      _ep(10, 1, 1, DateTime(2024, 1, 3, 1)), // next day, at 1 AM
      _ep(10, 1, 2, d3), // a month late
      _ep(10, 2, 1, d3),
    ];
    final a = await evaluate(
      [
        _def('day_one', 3, params: {'maxDelayDays': 1}),
        _def('day_one', 1, id: 'strict'),
        _def('day_one', 2, id: 'strict2'),
      ],
      seen,
      source: source,
    );
    expect(a['day_one_3']!.isUnlocked, isTrue);
    expect(a['day_one_3']!.unlockedAt, DateTime(2024, 1, 3, 1));
    // Without maxDelayDays only the same calendar day counts.
    expect(a['strict']!.isUnlocked, isTrue);
    expect(a['strict2']!.progressLabel, '1/2');
  });

  test('day_one should only count the first view of a movie', () async {
    final source = _FakeMediaSource(
      titleData: {(1, 'movie'): _info(release: '2024-01-03')},
    );
    final a = await evaluate(
      [_def('day_one', 1)],
      [_movie(1, d1), _movie(1, d3)], // seen before release, then on the day
      source: source,
    );
    expect(a['day_one_1']!.isUnlocked, isFalse);
  });

  test('cache-based unlocks should be sticky, genres not', () async {
    final unlockedAt = DateTime(2023, 5, 1);
    await isar.writeTxn(() async {
      await isar.achievementModels.putAll([
        AchievementModel(
          achievementId: 'distinct_countries_1',
          unlockedAt: unlockedAt,
        ),
        AchievementModel(
          achievementId: 'distinct_genres_1',
          unlockedAt: unlockedAt,
        ),
      ]);
    });
    final a = await evaluate([
      _def('distinct_countries', 1),
      _def('distinct_genres', 1),
    ], []);
    expect(a['distinct_countries_1']!.isUnlocked, isTrue);
    expect(a['distinct_countries_1']!.unlockedAt, unlockedAt);
    expect(a['distinct_genres_1']!.isUnlocked, isFalse);
  });

  group('MediaItem metadata', () {
    test('should parse origin_country and vote_count', () {
      final item = MediaItem.fromJson({
        'id': 1,
        'name': 'S',
        'media_type': 'tv',
        'origin_country': ['KR'],
        'production_countries': [
          {'iso_3166_1': 'US'},
        ],
        'vote_count': 1234,
      });
      expect(item.originCountries, ['KR']);
      expect(item.voteCount, 1234);
      final back = MediaItem.fromJson(item.toJson());
      expect(back.originCountries, ['KR']);
      expect(back.voteCount, 1234);
    });

    test('should fall back to production_countries', () {
      final item = MediaItem.fromJson({
        'id': 1,
        'title': 'M',
        'production_countries': [
          {'iso_3166_1': 'FR', 'name': 'France'},
          {'name': 'no code'},
        ],
      });
      expect(item.originCountries, ['FR']);
      expect(MediaItem.fromJson({'id': 2}).originCountries, isNull);
    });
  });

  group('CachedAchievementMediaSource', () {
    late MockMediaCache cache;
    late CachedAchievementMediaSource source;

    setUpAll(() => registerFallbackValue(MediaType.movie));

    setUp(() {
      cache = MockMediaCache();
      source = CachedAchievementMediaSource(cache);
    });

    test(
      'should complete list rows from the details and memoize them',
      () async {
        const listRow = MediaItem(
          id: 1,
          title: 'M',
          overview: '',
          releaseDate: '1999-01-01',
          voteAverage: 7.0,
          voteCount: 50,
        );
        when(() => cache.getItems(any())).thenAnswer((_) async => [listRow]);
        when(() => cache.getDetails(1, MediaType.movie)).thenAnswer(
          (_) async => MediaDetails(
            item: listRow.copyWith(originCountries: ['FR']),
            cast: const [],
          ),
        );

        await source.titles({(1, 'movie')});
        final titles = await source.titles({(1, 'movie')});

        expect(titles[(1, 'movie')]!.originCountries, ['FR']);
        expect(titles[(1, 'movie')]!.year, 1999);
        verify(() => cache.getItems(any())).called(1);
        verify(() => cache.getDetails(1, MediaType.movie)).called(1);
      },
    );

    test('should return incomplete titles and re-read them', () async {
      const oldRow = MediaItem(
        id: 2,
        title: 'M',
        overview: '',
        releaseDate: '1999-01-01',
      );
      when(() => cache.getItems(any())).thenAnswer((_) async => [oldRow]);
      when(
        () => cache.getDetails(2, MediaType.movie),
      ).thenAnswer((_) async => null);

      await source.titles({(2, 'movie')});
      final titles = await source.titles({(2, 'movie')});

      expect(titles[(2, 'movie')]!.year, 1999);
      expect(titles[(2, 'movie')]!.originCountries, isNull);
      verify(() => cache.getItems(any())).called(2);
    });

    test('should read episode air dates from the cached season', () async {
      when(() => cache.getSeason(1, 1)).thenAnswer(
        (_) async => {
          'episodes': [
            {'episode_number': 1, 'air_date': '2024-01-01'},
            {'episode_number': 2, 'air_date': ''},
            {'episode_number': 3, 'air_date': null},
          ],
        },
      );
      when(() => cache.getSeason(1, 2)).thenAnswer((_) async => null);

      expect(await source.episodeAirDates(1, 1), {1: '2024-01-01'});
      expect(await source.episodeAirDates(1, 2), isNull);
    });
  });
}
