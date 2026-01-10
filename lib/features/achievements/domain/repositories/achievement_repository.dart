import '../entities/achievement.dart';

abstract class AchievementRepository {
  Future<List<Achievement>> getAchievements();
  Future<void> unlockAchievement(String achievementId, DateTime unlockedAt);
  Stream<List<Achievement>> watchAchievements();
  Future<void> clearAchievements();
}
