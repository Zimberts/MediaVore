import 'package:isar/isar.dart';

part 'achievement_model.g.dart';

@collection
class AchievementModel {
  Id? isarId;

  @Index(unique: true, replace: true)
  final String achievementId;

  final DateTime unlockedAt;

  AchievementModel({
    required this.achievementId,
    required this.unlockedAt,
  });
}
