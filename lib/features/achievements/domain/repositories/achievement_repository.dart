import '../entities/achievement.dart';

abstract class AchievementRepository {
  Future<List<Achievement>> getAchievements();
  Future<void> unlockAchievement(String achievementId, DateTime unlockedAt);
  Stream<List<Achievement>> watchAchievements();
  Future<void> clearAchievements();

  /// Logs a user data export (backup) done at [at].
  Future<void> recordExport(DateTime at);
}
