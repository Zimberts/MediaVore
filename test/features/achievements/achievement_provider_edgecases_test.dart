import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';

void main() {
  late MockAchievementRepository repo;

  setUp(() {
    repo = MockAchievementRepository();
    when(
      () => repo.watchAchievements(),
    ).thenAnswer((_) => const Stream<List<Achievement>>.empty());
  });

  test(
    'autoUnlock calls unlockAchievement for unlocked but not persisted',
    () async {
      final now = DateTime.now();
      final ach = Achievement(
        id: 'a1',
        title: 'Test',
        description: '',
        iconPath: 'icon.png',
        isUnlocked: true,
        isPersisted: false,
        unlockedAt: now,
      );

      when(() => repo.getAchievements()).thenAnswer((_) async => [ach]);
      when(() => repo.unlockAchievement('a1', now)).thenAnswer((_) async {});

      final provider = AchievementProvider(repo);

      // Give async a moment to run init
      await Future.delayed(const Duration(milliseconds: 50));

      verify(() => repo.unlockAchievement('a1', any())).called(1);
      provider.dispose();
    },
  );

  test('clearAchievements clears and refreshes', () async {
    when(() => repo.getAchievements()).thenAnswer((_) async => <Achievement>[]);
    when(() => repo.clearAchievements()).thenAnswer((_) async {});

    final provider = AchievementProvider(repo);
    await Future.delayed(const Duration(milliseconds: 50));

    await provider.clearAchievements();

    verify(() => repo.clearAchievements()).called(1);
    provider.dispose();
  });
}
