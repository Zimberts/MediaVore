import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement_family.dart';

Achievement _a(String id, {String? group, int? tier, bool unlocked = false}) =>
    Achievement(
      id: id,
      title: id,
      description: '',
      iconPath: '',
      group: group,
      tier: tier,
      isUnlocked: unlocked,
    );

void main() {
  group('groupAchievements', () {
    test('should group by family in first-appearance order', () {
      final families = groupAchievements([
        _a('m2', group: 'movies', tier: 2),
        _a('solo'),
        _a('m1', group: 'movies', tier: 1, unlocked: true),
        _a('t1', group: 'tv', tier: 1),
      ]);

      expect(families.map((f) => f.id), ['movies', 'solo', 'tv']);
      expect(families.first.tiers.map((a) => a.id), ['m1', 'm2']);
      expect(families[1].isTiered, isFalse);
    });
  });

  group('AchievementFamily', () {
    test('should expose highest unlocked and next tier', () {
      final family = groupAchievements([
        _a('m1', group: 'movies', tier: 1, unlocked: true),
        _a('m2', group: 'movies', tier: 2, unlocked: true),
        _a('m3', group: 'movies', tier: 3),
      ]).single;

      expect(family.highestUnlocked?.id, 'm2');
      expect(family.current.id, 'm2');
      expect(family.next?.id, 'm3');
      expect(family.unlockedCount, 2);
      expect(family.isCompleted, isFalse);
      expect(family.contains('m3'), isTrue);
    });

    test('should fall back to the first tier when nothing is unlocked', () {
      final family = groupAchievements([
        _a('m1', group: 'movies', tier: 1),
        _a('m2', group: 'movies', tier: 2),
      ]).single;

      expect(family.highestUnlocked, isNull);
      expect(family.current.id, 'm1');
      expect(family.next?.id, 'm1');
    });

    test('should be completed when every tier is unlocked', () {
      final family = groupAchievements([
        _a('m1', group: 'movies', tier: 1, unlocked: true),
        _a('m2', group: 'movies', tier: 2, unlocked: true),
      ]).single;

      expect(family.isCompleted, isTrue);
      expect(family.next, isNull);
    });
  });
}
