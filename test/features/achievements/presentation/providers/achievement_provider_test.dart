import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAchievementRepository mockRepository;
  late AchievementProvider provider;
  const batchWindow = Duration(milliseconds: 30);

  Achievement unlocked(
    String id, {
    String? group,
    int? tier,
    bool isPersisted = false,
    DateTime? unlockedAt,
  }) => Achievement(
    id: id,
    title: id,
    description: 'D',
    iconPath: 'I',
    group: group,
    tier: tier,
    isUnlocked: true,
    isPersisted: isPersisted,
    unlockedAt: unlockedAt ?? DateTime(2023),
    progress: 1.0,
  );

  setUp(() {
    mockRepository = MockAchievementRepository();
    // Default mock behavior for constructor init
    when(
      () => mockRepository.watchAchievements(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockRepository.getAchievements()).thenAnswer((_) async => []);
    when(
      () => mockRepository.unlockAchievement(any(), any()),
    ).thenAnswer((_) async {});

    provider = AchievementProvider(mockRepository, batchWindow: batchWindow);
  });

  tearDown(() {
    provider.dispose();
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
        final unlockedAt = DateTime(2023);
        final achievements = [
          Achievement(
            id: 'unlocked_but_not_saved',
            title: 'T',
            description: 'D',
            iconPath: 'I',
            isUnlocked: true,
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
      final unlockedAt = DateTime(2023);
      final achievement = Achievement(
        id: '1',
        title: 'T',
        description: 'D',
        iconPath: 'I',
        isUnlocked: true,
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
        final unlockedAt = DateTime(2023);
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

        final notified = <List<String>>[];
        final sub = provider.onAchievementUnlocked.listen(
          (batch) => notified.add(batch.map((a) => a.id).toList()),
        );
        await provider.refresh();
        await Future<void>.delayed(batchWindow * 2);
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
        expect(notified, hasLength(2));
        expect(
          notified.expand((e) => e),
          unorderedEquals(['movie_10', 'tv_1']),
        );
        expect(provider.families.map((f) => f.id), ['movies', 'episodes']);
      },
    );

    test(
      'should emit individual events when <= 3 achievement families unlock',
      () async {
        when(() => mockRepository.getAchievements()).thenAnswer(
          (_) async => [
            unlocked('a1', group: 'g1', tier: 1),
            unlocked('a2', group: 'g2', tier: 1),
            unlocked('a3', group: 'g3', tier: 1),
          ],
        );

        final batches = <List<String>>[];
        final sub = provider.onAchievementUnlocked.listen(
          (batch) => batches.add(batch.map((a) => a.id).toList()),
        );
        await provider.refresh();
        await Future<void>.delayed(batchWindow * 2);
        await sub.cancel();

        expect(batches, [
          ['a1'],
          ['a2'],
          ['a3'],
        ]);
      },
    );

    test(
      'should emit one grouped event when > 3 achievement families unlock',
      () async {
        when(() => mockRepository.getAchievements()).thenAnswer(
          (_) async => [
            unlocked('a1', group: 'g1', tier: 1),
            unlocked('a2', group: 'g2', tier: 1),
            unlocked('a3', group: 'g3', tier: 1),
            unlocked('a4', group: 'g4', tier: 1),
          ],
        );

        final batches = <List<String>>[];
        final sub = provider.onAchievementUnlocked.listen(
          (batch) => batches.add(batch.map((a) => a.id).toList()),
        );
        await provider.refresh();
        await Future<void>.delayed(batchWindow * 2);
        await sub.cancel();

        expect(batches, hasLength(1));
        expect(batches.single, unorderedEquals(['a1', 'a2', 'a3', 'a4']));
      },
    );

    test(
      'should group unlocks spread across multiple watchAchievements emissions within the batch window',
      () async {
        final watchController = StreamController<List<Achievement>>();
        when(
          () => mockRepository.watchAchievements(),
        ).thenAnswer((_) => watchController.stream);

        final watchedProvider = AchievementProvider(
          mockRepository,
          batchWindow: const Duration(milliseconds: 50),
        );
        final batches = <List<String>>[];
        final sub = watchedProvider.onAchievementUnlocked.listen(
          (batch) => batches.add(batch.map((a) => a.id).toList()),
        );

        watchController.add([
          unlocked('a1', group: 'g1', tier: 1),
          unlocked('a2', group: 'g2', tier: 1),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        watchController.add([
          unlocked('a1', group: 'g1', tier: 1),
          unlocked('a2', group: 'g2', tier: 1),
          unlocked('a3', group: 'g3', tier: 1),
          unlocked('a4', group: 'g4', tier: 1),
        ]);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await sub.cancel();
        await watchController.close();
        watchedProvider.dispose();

        expect(batches, hasLength(1));
        expect(batches.single, unorderedEquals(['a1', 'a2', 'a3', 'a4']));
      },
    );

    test(
      'should collapse same-family tiers across multiple watchAchievements emissions within the batch window',
      () async {
        final watchController = StreamController<List<Achievement>>();
        when(
          () => mockRepository.watchAchievements(),
        ).thenAnswer((_) => watchController.stream);

        final watchedProvider = AchievementProvider(
          mockRepository,
          batchWindow: const Duration(milliseconds: 50),
        );
        final batches = <List<String>>[];
        final sub = watchedProvider.onAchievementUnlocked.listen(
          (batch) => batches.add(batch.map((a) => a.id).toList()),
        );

        watchController.add([unlocked('movie_1', group: 'movies', tier: 1)]);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        watchController.add([
          unlocked('movie_1', group: 'movies', tier: 1),
          unlocked('movie_10', group: 'movies', tier: 2),
        ]);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await sub.cancel();
        await watchController.close();
        watchedProvider.dispose();

        expect(batches, [
          ['movie_10'],
        ]);
      },
    );

    test(
      'clearAchievements should reset notified set, cancel pending batch, and call repository',
      () async {
        when(
          () => mockRepository.getAchievements(),
        ).thenAnswer((_) async => [unlocked('a1')]);
        when(() => mockRepository.clearAchievements()).thenAnswer((_) async {});

        final batches = <List<String>>[];
        final sub = provider.onAchievementUnlocked.listen(
          (batch) => batches.add(batch.map((a) => a.id).toList()),
        );

        await provider.refresh();
        when(
          () => mockRepository.getAchievements(),
        ).thenAnswer((_) async => []);
        await provider.clearAchievements();
        await Future<void>.delayed(batchWindow * 2);
        await sub.cancel();

        verify(() => mockRepository.clearAchievements()).called(1);
        expect(batches, isEmpty);
      },
    );
  });
}
