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

    test('should count genre milestones across genre name languages', () async {
      // 5 seen in English, 5 seen in French: same TMDB genre (Horror).
      final seenItems = [
        for (var i = 0; i < 10; i++)
          SeenItemModel(
            tmdbId: i,
            type: 'movie',
            title: 'H$i',
            seenDate: DateTime(2023, 1, i + 1),
            genres: [i.isEven ? 'Horror' : 'Horreur'],
          ),
      ];
      when(
        () => mockDataSource.getAllSeenItems(),
      ).thenAnswer((_) async => seenItems);

      final achievements = await repository.getAchievements();
      final horror = achievements.firstWhere((a) => a.id == 'genre_horror');

      expect(horror.isUnlocked, isTrue);
    });

    test('should expose translated titles from the definitions', () async {
      when(() => mockDataSource.getAllSeenItems()).thenAnswer((_) async => []);
      final repo = AchievementRepositoryImpl(
        isar,
        mockDataSource,
        definitionsLoader: _TestDefinitionsLoader(
          () async => [
            {
              'id': 'movie_1',
              'title': 'Movie Starter',
              'description': 'Watch your first movie',
              'iconPath': 'assets/achievements/movie_1.png',
              'type': 'count',
              'params': {'mediaType': 'movie', 'target': 1},
              'translations': {
                'fr': {
                  'title': 'Premier film',
                  'description': 'Regarder votre premier film',
                },
              },
            },
          ],
        ),
      );

      final starter = (await repo.getAchievements()).single;

      expect(starter.titleFor('en'), 'Movie Starter');
      expect(starter.titleFor('fr'), 'Premier film');
      expect(starter.descriptionFor('fr'), 'Regarder votre premier film');
      expect(starter.titleFor('xx'), 'Movie Starter');
      expect(starter.descriptionFor('xx'), 'Watch your first movie');
    });
  });
}
