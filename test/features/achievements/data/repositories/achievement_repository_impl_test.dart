import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/achievements/data/repositories/achievement_repository_impl.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:convert';
import 'dart:io';
import 'package:mediavore/core/di/definitions_loader.dart';
import '../../../../helpers/mocks.dart';

// Simple test helper that implements the runtime `DefinitionsLoader`.
class _TestDefinitionsLoader implements DefinitionsLoader {
  final Future<List<Map<String, dynamic>>> Function() _loader;
  _TestDefinitionsLoader(this._loader);
  @override
  Future<List<Map<String, dynamic>>> load() => _loader();
}

void main() {
  late AchievementRepositoryImpl repository;
  late MockMediaListLocalDataSource mockDataSource;
  late Isar isar;
  late String tempPath;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    tempPath = '${Directory.current.path}/test/tmp_achievements';
    if (!Directory(tempPath).existsSync()) {
      Directory(tempPath).createSync(recursive: true);
    }
  });

  setUp(() async {
    isar = await Isar.open(
      [AchievementModelSchema, SeenItemModelSchema],
      directory: tempPath,
      name: 'test_achievements_db',
    );
    mockDataSource = MockMediaListLocalDataSource();
    // loader that reads the JSON definitions file from disk for tests
    final assetPath =
        '${Directory.current.path.replaceAll('\\', '/')}/assets/achievements/definitions.json';
    Future<List<Map<String, dynamic>>> loader() async {
      final content = await File(assetPath).readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    repository = AchievementRepositoryImpl(
      isar,
      mockDataSource,
      definitionsLoader: _TestDefinitionsLoader(loader),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('AchievementRepositoryImpl', () {
    test('should calculate Movie Starter progress correctly', () async {
      final seenItems = [
        SeenItemModel(
          tmdbId: 1,
          type: 'movie',
          title: 'M1',
          seenDate: DateTime(2023, 1, 1),
        ),
      ];
      when(
        () => mockDataSource.getAllSeenItems(),
      ).thenAnswer((_) async => seenItems);

      final achievements = await repository.getAchievements();
      final starter = achievements.firstWhere((a) => a.id == 'movie_1');

      expect(starter.isUnlocked, isTrue);
      expect(starter.progress, 1.0);
      expect(starter.unlockedAt, seenItems[0].seenDate);
    });

    test('should calculate Night Owl progress correctly', () async {
      // 1 AM is a Night Owl hour
      final seenItems = List.generate(
        10,
        (index) => SeenItemModel(
          tmdbId: index,
          type: 'movie',
          title: 'M',
          seenDate: DateTime(2023, 1, 1, 1),
        ),
      );
      when(
        () => mockDataSource.getAllSeenItems(),
      ).thenAnswer((_) async => seenItems);

      final achievements = await repository.getAchievements();
      final nightOwl = achievements.firstWhere((a) => a.id == 'night_owl');

      expect(nightOwl.isUnlocked, isTrue);
      expect(nightOwl.progress, 1.0);
    });

    test('should not count date-only (midnight) views as Night Owl', () async {
      // 00:00:00.000 = no time recorded; 00:30 is a real night view
      final seenItems = [
        ...List.generate(
          10,
          (index) => SeenItemModel(
            tmdbId: index,
            type: 'movie',
            title: 'M',
            seenDate: DateTime(2023, 1, 1),
          ),
        ),
        SeenItemModel(
          tmdbId: 100,
          type: 'movie',
          title: 'M',
          seenDate: DateTime(2023, 1, 2, 0, 30),
        ),
      ];
      when(
        () => mockDataSource.getAllSeenItems(),
      ).thenAnswer((_) async => seenItems);

      final achievements = await repository.getAchievements();
      final nightOwl = achievements.firstWhere((a) => a.id == 'night_owl');

      expect(nightOwl.isUnlocked, isFalse);
      expect(nightOwl.progress, closeTo(0.1, 1e-9));
    });

    test('unlockAchievement should persist to DB', () async {
      final date = DateTime(2023, 1, 1);
      await repository.unlockAchievement('test_id', date);

      final persisted = await isar.achievementModels.where().findAll();
      expect(persisted.length, 1);
      expect(persisted.first.achievementId, 'test_id');
    });

    test('should load definitions via injected loader reading JSON file', () async {
      // create a loader that reads the repo asset file directly from disk
      final assetPath =
          '${Directory.current.path.replaceAll('\\', '/')}/assets/achievements/definitions.json';
      Future<List<Map<String, dynamic>>> loader() async {
        final content = await File(assetPath).readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      // New repository instance using injected loader to exercise JSON path
      final repoWithLoader = AchievementRepositoryImpl(
        isar,
        mockDataSource,
        definitionsLoader: _TestDefinitionsLoader(loader),
      );

      // No seen items required for existence check — call getAchievements()
      when(
        () => mockDataSource.getAllSeenItems(),
      ).thenAnswer((_) async => <SeenItemModel>[]);

      final achievements = await repoWithLoader.getAchievements();

      // Basic sanity: ensure a known id from the JSON is present and has expected title
      final movieStarter = achievements.firstWhere((a) => a.id == 'movie_1');
      expect(movieStarter.title, 'Movie Starter');
    });

    group('with inline definitions', () {
      AchievementRepositoryImpl repoWith(List<Map<String, dynamic>> defs) =>
          AchievementRepositoryImpl(
            isar,
            mockDataSource,
            definitionsLoader: _TestDefinitionsLoader(() async => defs),
          );

      SeenItemModel movie(int id, List<String> genres, {int? runtime}) =>
          SeenItemModel(
            tmdbId: id,
            type: 'movie',
            title: 'M$id',
            seenDate: DateTime(2023, 1, id),
            genres: genres,
            runtime: runtime,
          );

      test(
        'should match genre achievements by TMDB id in any language',
        () async {
          when(() => mockDataSource.getAllSeenItems()).thenAnswer(
            (_) async => [
              movie(1, ['Horror']),
              movie(2, ['Horreur', 'Comédie']),
              movie(3, ['Comedy']),
            ],
          );
          final achievements = await repoWith([
            {
              'id': 'genre_horror',
              'title': 'T',
              'description': 'D',
              'iconPath': 'I',
              'type': 'genre',
              'params': {'genreId': 27, 'target': 2},
            },
            {
              'id': 'legacy_comedy_by_name',
              'title': 'T',
              'description': 'D',
              'iconPath': 'I',
              'type': 'genre',
              'params': {'genre': 'Comedy', 'target': 3},
            },
          ]).getAchievements();

          expect(achievements[0].isUnlocked, isTrue);
          expect(achievements[0].unlockedAt, DateTime(2023, 1, 2));
          expect(achievements[1].progressLabel, '2/3');
        },
      );

      test('should fill group and tier from the definition', () async {
        when(
          () => mockDataSource.getAllSeenItems(),
        ).thenAnswer((_) async => <SeenItemModel>[]);
        final achievements = await repoWith([
          {
            'id': 'movie_10',
            'title': 'T',
            'description': 'D',
            'iconPath': 'I',
            'type': 'count',
            'group': 'movies',
            'tier': 2,
            'params': {'mediaType': 'movie', 'target': 10},
          },
        ]).getAchievements();

        expect(achievements.single.group, 'movies');
        expect(achievements.single.tier, 2);
      });

      test(
        'should report no progress for unknown types or zero targets',
        () async {
          when(
            () => mockDataSource.getAllSeenItems(),
          ).thenAnswer((_) async => [movie(1, [])]);
          final achievements = await repoWith([
            {
              'id': 'unknown',
              'title': 'T',
              'description': 'D',
              'iconPath': 'I',
              'type': 'does_not_exist',
              'params': {'target': 1},
            },
            {
              'id': 'zero',
              'title': 'T',
              'description': 'D',
              'iconPath': 'I',
              'type': 'count',
              'params': {'mediaType': 'movie', 'target': 0},
            },
          ]).getAchievements();

          expect(achievements.every((a) => !a.isUnlocked), isTrue);
          expect(achievements.every((a) => a.progress == 0), isTrue);
        },
      );

      test('should format runtime progress with readable units', () async {
        when(
          () => mockDataSource.getAllSeenItems(),
        ).thenAnswer((_) async => [movie(1, [], runtime: 1000)]);
        final achievements = await repoWith([
          {
            'id': 'runtime_day_10',
            'title': 'T',
            'description': 'D',
            'iconPath': 'I',
            'type': 'runtime',
            'params': {'targetMinutes': 14400},
          },
        ]).getAchievements();

        expect(achievements.single.progressLabel, '16h 40m / 10 days');
      });
    });

    test('clearAchievements should remove all from DB', () async {
      await isar.writeTxn(() async {
        await isar.achievementModels.put(
          AchievementModel(achievementId: '1', unlockedAt: DateTime.now()),
        );
      });

      await repository.clearAchievements();

      final count = await isar.achievementModels.count();
      expect(count, 0);
    });
  });
}
