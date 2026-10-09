import 'package:equatable/equatable.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';

/// The ordered tiers of one challenge (e.g. movies watched 1 → 1000).
/// A standalone achievement is a family with a single tier.
class AchievementFamily extends Equatable {
  final String id;
  final List<Achievement> tiers;

  const AchievementFamily({required this.id, required this.tiers});

  bool get isTiered => tiers.length > 1;

  int get unlockedCount => tiers.where((a) => a.isUnlocked).length;

  bool get isCompleted => tiers.every((a) => a.isUnlocked);

  /// Highest unlocked tier, or null when nothing is unlocked yet.
  Achievement? get highestUnlocked {
    for (final a in tiers.reversed) {
      if (a.isUnlocked) return a;
    }
    return null;
  }

  /// First locked tier (the next goal), or null when the family is completed.
  Achievement? get next {
    for (final a in tiers) {
      if (!a.isUnlocked) return a;
    }
    return null;
  }

  /// Tier shown on the family card.
  Achievement get current => highestUnlocked ?? tiers.first;

  bool contains(String achievementId) =>
      tiers.any((a) => a.id == achievementId);

  @override
  List<Object?> get props => [id, tiers];
}

/// Groups achievements by [Achievement.group], keeping the order in which
/// each family first appears. Tiers are sorted by [Achievement.tier].
List<AchievementFamily> groupAchievements(List<Achievement> achievements) {
  final byGroup = <String, List<Achievement>>{};
  for (final a in achievements) {
    byGroup.putIfAbsent(a.group ?? a.id, () => []).add(a);
  }
  return byGroup.entries.map((e) {
    final tiers = List<Achievement>.from(e.value)
      ..sort((a, b) => (a.tier ?? 0).compareTo(b.tier ?? 0));
    return AchievementFamily(id: e.key, tiers: tiers);
  }).toList();
}
