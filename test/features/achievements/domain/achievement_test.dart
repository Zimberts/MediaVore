import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';

void main() {
  group('Achievement Entity', () {
    test('should support value equality', () {
      final unlockedAt = DateTime(2023);
      final a1 = Achievement(
        id: '1',
        title: 'Title',
        description: 'Desc',
        iconPath: 'icon',
        isUnlocked: true,
        isPersisted: true,
        unlockedAt: unlockedAt,
        progress: 1.0,
        progressLabel: '1/1',
      );
      final a2 = Achievement(
        id: '1',
        title: 'Title',
        description: 'Desc',
        iconPath: 'icon',
        isUnlocked: true,
        isPersisted: true,
        unlockedAt: unlockedAt,
        progress: 1.0,
        progressLabel: '1/1',
      );

      expect(a1, equals(a2));
    });

    test('should mask only when hidden and locked', () {
      const visibleLocked = Achievement(
        id: '1',
        title: 'Title',
        description: 'Desc',
        iconPath: 'icon',
      );
      const hiddenLocked = Achievement(
        id: '2',
        title: 'Secret',
        description: 'Secret desc',
        iconPath: 'icon',
        isHidden: true,
      );
      const hiddenUnlocked = Achievement(
        id: '3',
        title: 'Secret',
        description: 'Secret desc',
        iconPath: 'icon',
        isHidden: true,
        isUnlocked: true,
      );

      expect(visibleLocked.isHidden, isFalse);
      expect(visibleLocked.isMasked, isFalse);
      expect(hiddenLocked.isHidden, isTrue);
      expect(hiddenLocked.isMasked, isTrue);
      expect(hiddenUnlocked.isHidden, isTrue);
      expect(hiddenUnlocked.isMasked, isFalse);
      expect(hiddenLocked, isNot(equals(visibleLocked)));
    });
  });
}
