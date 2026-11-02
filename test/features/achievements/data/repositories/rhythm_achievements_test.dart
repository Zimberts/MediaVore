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

SeenItemModel _movie(int id, DateTime date) =>
    SeenItemModel(tmdbId: id, type: 'movie', title: 'M$id', seenDate: date);

SeenItemModel _ep(int show, int episode, DateTime date) => SeenItemModel(
  tmdbId: show,
  type: 'tv',
  title: 'S$show',
  seenDate: date,
  seasonNumber: 1,
  episodeNumber: episode,
);

void main() {
  late Isar isar;
  late MockMediaListLocalDataSource local;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_rhythm_achievements';
    Directory(tempPath).createSync(recursive: true);
  });

  setUp(() async {
    isar = await Isar.open(
      [AchievementModelSchema, SeenItemModelSchema],
      directory: tempPath,
      name: 'test_rhythm_achievements_db',
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

  group('early_bird', () {
    test('should count views from 5:00 to 8:59 only', () async {
      final defs = [
        _def('behavioral', 3, params: {'subtype': 'early_bird'}),
      ];
      final a = await evaluate(defs, [
        _movie(1, DateTime(2024, 1, 1, 4, 59)), // too early
        _movie(2, DateTime(2024, 1, 1, 5)),
        _movie(3, DateTime(2024, 1, 2, 8, 59)),
        _movie(4, DateTime(2024, 1, 3, 9)), // too late
        _movie(5, DateTime(2024, 1, 4)), // date-only view
      ]);
      expect(a['behavioral_3']!.progressLabel, '2/3');
      expect(a['behavioral_3']!.isUnlocked, isFalse);

      final b = await evaluate(defs, [
        _movie(2, DateTime(2024, 1, 1, 5)),
        _ep(9, 1, DateTime(2024, 1, 2, 6)),
        _movie(3, DateTime(2024, 1, 3, 7, 30)),
      ]);
      expect(b['behavioral_3']!.isUnlocked, isTrue);
      expect(b['behavioral_3']!.unlockedAt, DateTime(2024, 1, 3, 7, 30));
    });
  });

  group('double_feature', () {
    final defs = [
      _def('double_feature', 1, params: {'minMovies': 2}),
      _def('double_feature', 2, params: {'minMovies': 2}),
    ];

    test('should count calendar days with distinct movies', () async {
      final a = await evaluate(defs, [
        // Day 1: same movie twice (a rewatch), then episodes: no.
        _movie(1, DateTime(2024, 3, 1, 14)),
        _movie(1, DateTime(2024, 3, 1, 20)),
        _ep(9, 1, DateTime(2024, 3, 1, 21)),
        // Day 2: two movies, across midnight of the next day: no.
        _movie(2, DateTime(2024, 3, 2, 23)),
        _movie(3, DateTime(2024, 3, 3, 1)),
        // Day 4: two distinct movies, then a third.
        _movie(4, DateTime(2024, 3, 4, 14)),
        _movie(5, DateTime(2024, 3, 4, 18)),
        _movie(6, DateTime(2024, 3, 4, 21)),
      ]);
      expect(a['double_feature_1']!.isUnlocked, isTrue);
      expect(a['double_feature_1']!.unlockedAt, DateTime(2024, 3, 4, 18));
      expect(a['double_feature_2']!.isUnlocked, isFalse);
      expect(a['double_feature_2']!.progressLabel, '1/2');
    });

    test('should default minMovies to 2', () async {
      final a = await evaluate(
        [_def('double_feature', 1)],
        [_movie(1, DateTime(2024, 3, 1, 9)), _movie(2, DateTime(2024, 3, 1))],
      );
      expect(a['double_feature_1']!.isUnlocked, isTrue);
    });
  });

  group('every_weekday', () {
    // 2024-01-01 is a Monday.
    List<SeenItemModel> week(int start, {int days = 7, int id = 0}) => [
      for (var d = 0; d < days; d++)
        _movie(id + d, DateTime(2024, 1, start + d, 20)),
    ];

    test('should require every day of the week', () async {
      final a = await evaluate(
        [_def('every_weekday', 1)],
        [...week(1, days: 6), _movie(99, DateTime(2024, 1, 15, 20))],
      );
      expect(a['every_weekday_1']!.isUnlocked, isFalse);
      expect(a['every_weekday_1']!.progressLabel, '0/1');

      final b = await evaluate(
        [_def('every_weekday', 1)],
        [...week(1, days: 6), _movie(99, DateTime(2024, 1, 21, 20))],
      );
      expect(b['every_weekday_1']!.isUnlocked, isTrue);
      expect(b['every_weekday_1']!.unlockedAt, DateTime(2024, 1, 21, 20));
    });

    test('should use the least-watched weekday for progress', () async {
      final a = await evaluate(
        [_def('every_weekday', 2)],
        [...week(1), ...week(8, days: 5, id: 10)],
      );
      expect(a['every_weekday_2']!.progressLabel, '1/2');
      expect(a['every_weekday_2']!.progress, closeTo(0.5, 1e-9));

      final b = await evaluate(
        [_def('every_weekday', 2)],
        [...week(1), ...week(8, id: 10)],
      );
      expect(b['every_weekday_2']!.isUnlocked, isTrue);
      expect(b['every_weekday_2']!.unlockedAt, DateTime(2024, 1, 14, 20));
    });
  });

  group('monthly_streak', () {
    test('should count consecutive calendar months', () async {
      final defs = [_def('monthly_streak', 3), _def('monthly_streak', 4)];
      final a = await evaluate(defs, [
        _movie(1, DateTime(2023, 11, 30)),
        _movie(2, DateTime(2023, 12, 1)),
        _movie(3, DateTime(2023, 12, 20)),
        // across the year boundary
        _movie(4, DateTime(2024, 1, 31, 23)),
        _movie(5, DateTime(2024, 1, 5)),
        // gap: March missing
        _movie(6, DateTime(2024, 4, 2)),
      ]);
      expect(a['monthly_streak_3']!.isUnlocked, isTrue);
      // First view of the third month (the history is sorted).
      expect(a['monthly_streak_3']!.unlockedAt, DateTime(2024, 1, 5));
      expect(a['monthly_streak_4']!.isUnlocked, isFalse);
      expect(a['monthly_streak_4']!.progressLabel, '3/4');
    });

    test('should restart after a missing month', () async {
      final a = await evaluate(
        [_def('monthly_streak', 2)],
        [_movie(1, DateTime(2024, 1, 10)), _movie(2, DateTime(2024, 3, 10))],
      );
      expect(a['monthly_streak_2']!.isUnlocked, isFalse);
      expect(a['monthly_streak_2']!.progressLabel, '1/2');
    });
  });

  group('anniversary', () {
    test('should count full years since the first view', () async {
      final now = DateTime.now();
      final first = DateTime(now.year - 2, now.month, now.day - 10);
      final defs = [
        _def('anniversary', 1),
        _def('anniversary', 2),
        _def('anniversary', 5),
      ];
      final a = await evaluate(defs, [
        _movie(2, now.subtract(const Duration(days: 1))),
        _movie(1, first),
      ]);
      expect(a['anniversary_1']!.isUnlocked, isTrue);
      expect(
        a['anniversary_1']!.unlockedAt,
        DateTime(first.year + 1, first.month, first.day),
      );
      expect(a['anniversary_2']!.isUnlocked, isTrue);
      expect(a['anniversary_5']!.isUnlocked, isFalse);
      expect(a['anniversary_5']!.progressLabel, '2/5');
      expect(a['anniversary_5']!.progress, closeTo(0.4, 0.02));
    });

    test('should stay at 0 without history or before a year', () async {
      final defs = [_def('anniversary', 1)];
      expect((await evaluate(defs, []))['anniversary_1']!.progressLabel, '0/1');

      final a = await evaluate(defs, [
        _movie(1, DateTime.now().subtract(const Duration(days: 300))),
      ]);
      expect(a['anniversary_1']!.isUnlocked, isFalse);
      expect(a['anniversary_1']!.progressLabel, '0/1');
      expect(a['anniversary_1']!.progress, inExclusiveRange(0.7, 0.9));
    });
  });

  group('calendar_date', () {
    final defs = [
      _def(
        'calendar_date',
        1,
        params: {
          'dates': ['12-24', '12-25'],
        },
      ),
      _def(
        'calendar_date',
        2,
        params: {
          'dates': ['12-24', '12-25'],
        },
      ),
    ];

    test('should count distinct years with a view on the dates', () async {
      final a = await evaluate(defs, [
        _movie(1, DateTime(2022, 12, 24, 20)),
        _movie(2, DateTime(2022, 12, 25, 15)), // same year: once
        _movie(3, DateTime(2022, 12, 26, 1)), // not a listed date
        _movie(4, DateTime(2023, 12, 23, 23, 59)), // not a listed date
      ]);
      expect(a['calendar_date_1']!.isUnlocked, isTrue);
      expect(a['calendar_date_1']!.unlockedAt, DateTime(2022, 12, 24, 20));
      expect(a['calendar_date_2']!.isUnlocked, isFalse);
      expect(a['calendar_date_2']!.progressLabel, '1/2');

      final b = await evaluate(defs, [
        _movie(1, DateTime(2022, 12, 24, 20)),
        _ep(9, 1, DateTime(2023, 12, 25)), // date-only view counts
      ]);
      expect(b['calendar_date_2']!.isUnlocked, isTrue);
      expect(b['calendar_date_2']!.unlockedAt, DateTime(2023, 12, 25));
    });
  });
}
