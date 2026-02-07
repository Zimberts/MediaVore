import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/achievements/data/repositories/achievement_repository_impl.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:io';
import '../../../../helpers/mocks.dart';

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
    repository = AchievementRepositoryImpl(isar, mockDataSource);
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
