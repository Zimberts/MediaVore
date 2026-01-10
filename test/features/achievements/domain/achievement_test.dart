import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';

void main() {
  group('Achievement Entity', () {
    test('should support value equality', () {
      final unlockedAt = DateTime(2023, 1, 1);
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
  });
}
