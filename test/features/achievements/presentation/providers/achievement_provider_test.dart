import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAchievementRepository mockRepository;
  late AchievementProvider provider;

  setUp(() {
    mockRepository = MockAchievementRepository();
    // Default mock behavior for constructor init
    when(
      () => mockRepository.watchAchievements(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockRepository.getAchievements()).thenAnswer((_) async => []);

    provider = AchievementProvider(mockRepository);
  });

  group('AchievementProvider', () {
    test('should load achievements on init', () async {
      final achievements = [
        const Achievement(id: '1', title: 'T', description: 'D', iconPath: 'I'),
      ];
      when(
        () => mockRepository.getAchievements(),
      ).thenAnswer((_) async => achievements);

      await provider.refresh();

      expect(provider.achievements, achievements);
      verify(() => mockRepository.getAchievements()).called(greaterThan(0));
    });

    test(
      'should auto-unlock achievements that meet criteria but are not persisted',
      () async {
        final unlockedAt = DateTime(2023, 1, 1);
        final achievements = [
          Achievement(
            id: 'unlocked_but_not_saved',
            title: 'T',
            description: 'D',
            iconPath: 'I',
            isUnlocked: true,
            isPersisted: false,
            unlockedAt: unlockedAt,
            progress: 1.0,
          ),
        ];

        when(
          () => mockRepository.getAchievements(),
        ).thenAnswer((_) async => achievements);
        when(
          () => mockRepository.unlockAchievement(any(), any()),
        ).thenAnswer((_) async {});

        await provider.refresh();

        verify(
          () => mockRepository.unlockAchievement(
            'unlocked_but_not_saved',
            unlockedAt,
          ),
        ).called(1);
      },
    );

    test('should not double-notify for already notified achievements', () async {
      final unlockedAt = DateTime(2023, 1, 1);
      final achievement = Achievement(
        id: '1',
        title: 'T',
        description: 'D',
        iconPath: 'I',
        isUnlocked: true,
        isPersisted: false,
        unlockedAt: unlockedAt,
        progress: 1.0,
      );

      when(
        () => mockRepository.getAchievements(),
      ).thenAnswer((_) async => [achievement]);
      when(
        () => mockRepository.unlockAchievement(any(), any()),
      ).thenAnswer((_) async {});

      // First time
      await provider.refresh();
      verify(() => mockRepository.unlockAchievement('1', unlockedAt)).called(1);

      // Second time - should not call repository again because of session cache
      await provider.refresh();
      verifyNever(() => mockRepository.unlockAchievement('1', unlockedAt));
    });

    test(
      'clearAchievements should reset notified set and call repository',
      () async {
        when(() => mockRepository.clearAchievements()).thenAnswer((_) async {});
        when(
          () => mockRepository.getAchievements(),
        ).thenAnswer((_) async => []);

        await provider.clearAchievements();

        verify(() => mockRepository.clearAchievements()).called(1);
      },
    );
  });
}
