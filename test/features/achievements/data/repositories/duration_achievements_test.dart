import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/di/definitions_loader.dart';
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

SeenItemModel _movie(int id, DateTime date, int? runtime) => SeenItemModel(
  tmdbId: id,
  type: 'movie',
  title: 'M$id',
  seenDate: date,
  runtime: runtime,
);

SeenItemModel _ep(int show, int season, int episode, DateTime date) =>
    SeenItemModel(
      tmdbId: show,
      type: 'tv',
      title: 'S$show',
      seenDate: date,
      seasonNumber: season,
      episodeNumber: episode,
      runtime: 200,
    );

void main() {
  late Isar isar;
  late MockMediaListLocalDataSource local;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_duration_achievements';
    Directory(tempPath).createSync(recursive: true);
  });

  setUp(() async {
    isar = await Isar.open(
      [AchievementModelSchema, SeenItemModelSchema],
      directory: tempPath,
      name: 'test_duration_achievements_db',
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
    List<SeenItemModel> seen,
  ) async {
    when(() => local.getAllSeenItems()).thenAnswer((_) async => seen);
    final repo = AchievementRepositoryImpl(
      isar,
      local,
      definitionsLoader: _Loader(defs),
    );
    return {for (final a in await repo.getAchievements()) a.id: a};
  }

  group('movie_runtime', () {
    test('should count distinct movies at or above minMinutes', () async {
      final defs = [
        _def('movie_runtime', 2, id: 'epic_2', params: {'minMinutes': 180}),
        _def('movie_runtime', 3, id: 'epic_3', params: {'minMinutes': 180}),
      ];
      final a = await evaluate(defs, [
        _movie(1, DateTime(2024, 1, 1), 179), // too short
        _movie(2, DateTime(2024, 1, 2), 180), // inclusive bound
        _movie(2, DateTime(2024, 1, 3), 180), // rewatch: counted once
        _ep(9, 1, 1, DateTime(2024, 1, 4)), // episodes never count
        _movie(3, DateTime(2024, 1, 5), null), // unknown runtime
        _movie(4, DateTime(2024, 1, 6), 201),
      ]);
      expect(a['epic_2']!.isUnlocked, isTrue);
      expect(a['epic_2']!.unlockedAt, DateTime(2024, 1, 6));
      expect(a['epic_3']!.isUnlocked, isFalse);
      expect(a['epic_3']!.progressLabel, '2/3');
    });

    test('should apply both bounds inclusively', () async {
      final defs = [
        _def(
          'movie_runtime',
          10,
          id: 'short_10',
          params: {'minMinutes': 40, 'maxMinutes': 80},
        ),
      ];
      final a = await evaluate(defs, [
        _movie(1, DateTime(2024, 1, 1), 39), // short film
        _movie(2, DateTime(2024, 1, 2), 40),
        _movie(3, DateTime(2024, 1, 3), 80),
        _movie(4, DateTime(2024, 1, 4), 81),
        _movie(5, DateTime(2024, 1, 5), 0), // missing runtime stored as 0
      ]);
      expect(a['short_10']!.progressLabel, '2/10');
    });

    test('should date a movie by its first view in the bounds', () async {
      // Runtime updated between two views (e.g. director's cut re-cached).
      final defs = [
        _def('movie_runtime', 1, id: 'epic_1', params: {'minMinutes': 180}),
      ];
      final a = await evaluate(defs, [
        _movie(1, DateTime(2024, 1, 1), 170),
        _movie(1, DateTime(2024, 2, 1), 185),
      ]);
      expect(a['epic_1']!.unlockedAt, DateTime(2024, 2, 1));
    });
  });

  group('series_seasons', () {
    final defs = [
      _def('series_seasons', 3, id: 'long_3'),
      _def('series_seasons', 4, id: 'long_4'),
    ];

    test('should count regular seasons of the same series', () async {
      final a = await evaluate(defs, [
        _ep(1, 0, 1, DateTime(2024, 1, 1)), // special: excluded
        _ep(1, 1, 1, DateTime(2024, 1, 2)),
        _ep(1, 1, 2, DateTime(2024, 1, 3)), // same season
        _ep(2, 2, 1, DateTime(2024, 1, 4)), // other series
        _ep(2, 3, 1, DateTime(2024, 1, 5)),
        _ep(1, 3, 1, DateTime(2024, 1, 6)),
        _ep(1, 2, 5, DateTime(2024, 1, 7)), // third season of series 1
      ]);
      expect(a['long_3']!.isUnlocked, isTrue);
      expect(a['long_3']!.unlockedAt, DateTime(2024, 1, 7));
      expect(a['long_4']!.isUnlocked, isFalse);
      expect(a['long_4']!.progressLabel, '3/4');
    });

    test('should ignore movies', () async {
      final a = await evaluate(defs, [
        SeenItemModel(
          tmdbId: 1,
          type: 'movie',
          title: 'M',
          seenDate: DateTime(2024, 1, 1),
          seasonNumber: 3,
        ),
      ]);
      expect(a['long_3']!.progressLabel, '0/3');
    });
  });
}
