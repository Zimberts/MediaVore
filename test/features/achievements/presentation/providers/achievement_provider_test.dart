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
      'should persist every new tier but notify only the highest per family',
      () async {
        final unlockedAt = DateTime(2023, 1, 1);
        Achievement tier(String id, String group, int tier) => Achievement(
          id: id,
          title: id,
          description: 'D',
          iconPath: 'I',
          group: group,
          tier: tier,
          isUnlocked: true,
          unlockedAt: unlockedAt,
          progress: 1.0,
        );
        when(() => mockRepository.getAchievements()).thenAnswer(
          (_) async => [
            tier('movie_1', 'movies', 1),
            tier('movie_10', 'movies', 2),
            tier('tv_1', 'episodes', 1),
            Achievement(
              id: 'tv_10',
              title: 'tv_10',
              description: 'D',
              iconPath: 'I',
              group: 'episodes',
              tier: 2,
              isUnlocked: true,
              isPersisted: true,
              unlockedAt: unlockedAt,
            ),
          ],
        );
        when(
          () => mockRepository.unlockAchievement(any(), any()),
        ).thenAnswer((_) async {});

        final notified = <String>[];
        final sub = provider.onAchievementUnlocked.listen(
          (a) => notified.add(a.id),
        );
        await provider.refresh();
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        verify(
          () => mockRepository.unlockAchievement('movie_1', unlockedAt),
        ).called(1);
        verify(
          () => mockRepository.unlockAchievement('movie_10', unlockedAt),
        ).called(1);
        verify(
          () => mockRepository.unlockAchievement('tv_1', unlockedAt),
        ).called(1);
        verifyNever(() => mockRepository.unlockAchievement('tv_10', any()));
        expect(notified, unorderedEquals(['movie_10', 'tv_1']));
        expect(provider.families.map((f) => f.id), ['movies', 'episodes']);
      },
    );

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
