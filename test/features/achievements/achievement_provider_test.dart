import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAchievementRepository mockRepo;
  late AchievementProvider provider;

  setUp(() {
    mockRepo = MockAchievementRepository();
  });

  tearDown(() {
    provider.dispose();
  });

  test(
    'auto-unlock calls repository.unlockAchievement and emits stream',
    () async {
      final unlockedAt = DateTime.now();
      final achUnlockedButNotPersisted = Achievement(
        id: 'a1',
        title: 'Test Ach',
        description: 'Desc',
        iconPath: '',
        isUnlocked: true,
        isPersisted: false,
        unlockedAt: unlockedAt,
        progress: 1.0,
      );

      // repository will return this list on getAchievements and as stream update
      when(
        () => mockRepo.getAchievements(),
      ).thenAnswer((_) async => [achUnlockedButNotPersisted]);

      // watchAchievements should emit the same list then close
      final controller = StreamController<List<Achievement>>();
      when(
        () => mockRepo.watchAchievements(),
      ).thenAnswer((_) => controller.stream);

      when(
        () => mockRepo.unlockAchievement(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockRepo.clearAchievements()).thenAnswer((_) async {});

      provider = AchievementProvider(mockRepo);

      // Listen to onAchievementUnlocked
      final events = <Achievement>[];
      final sub = provider.onAchievementUnlocked.listen((a) => events.add(a));

      // Trigger the watch stream
      controller.add([achUnlockedButNotPersisted]);
      await Future.delayed(const Duration(milliseconds: 50));

      // The provider should have attempted to persist by calling unlockAchievement
      verify(() => mockRepo.unlockAchievement('a1', unlockedAt)).called(1);

      // The provider should have added to the onAchievementUnlocked stream
      expect(events, isNotEmpty);
      expect(events.first.id, equals('a1'));

      await sub.cancel();
      await controller.close();
    },
  );
}
