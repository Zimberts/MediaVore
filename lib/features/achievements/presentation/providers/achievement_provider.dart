import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement_family.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';

@lazySingleton
class AchievementProvider with ChangeNotifier {
  final AchievementRepository _repository;
  List<Achievement> _achievements = [];
  List<AchievementFamily> _families = [];
  StreamSubscription? _subscription;

  // Track IDs we've already sent a notification for in this session
  // to avoid redundant triggers while persistence is in progress.
  final Set<String> _notifiedIds = {};

  final _unlockController = StreamController<Achievement>.broadcast();
  Stream<Achievement> get onAchievementUnlocked => _unlockController.stream;

  AchievementProvider(this._repository) {
    _init();
  }

  List<Achievement> get achievements => _achievements;
  List<AchievementFamily> get families => _families;

  void _setAchievements(List<Achievement> achievements) {
    _achievements = achievements;
    _families = groupAchievements(achievements);
  }

  void _init() {
    _subscription = _repository.watchAchievements().listen((
      updatedAchievements,
    ) {
      _setAchievements(updatedAchievements);
      _autoUnlock();
      notifyListeners();
    });
    refresh();
  }

  Future<void> refresh() async {
    _setAchievements(await _repository.getAchievements());
    _autoUnlock();
    notifyListeners();
  }

  Future<void> clearAchievements() async {
    _notifiedIds.clear();
    await _repository.clearAchievements();
    await refresh();
  }

  void _autoUnlock() {
    // Newly unlocked tiers of the same family are all persisted, but only the
    // highest one is announced, so reaching several levels at once (or new
    // lower tiers added by an update) produces a single notification.
    final toAnnounce = <String, Achievement>{};
    for (final achievement in _achievements) {
      // If it's unlocked in history but not yet persisted in DB
      if (achievement.isUnlocked &&
          !achievement.isPersisted &&
          achievement.unlockedAt != null) {
        if (!_notifiedIds.contains(achievement.id)) {
          _notifiedIds.add(achievement.id);
          _repository.unlockAchievement(
            achievement.id,
            achievement.unlockedAt!,
          );
          final key = achievement.group ?? achievement.id;
          final previous = toAnnounce[key];
          if (previous == null ||
              (achievement.tier ?? 0) > (previous.tier ?? 0)) {
            toAnnounce[key] = achievement;
          }
        }
      } else if (achievement.isPersisted) {
        // Once it is confirmed persisted, we can keep it in notified set
        // or just let the isPersisted check handle it next time.
        _notifiedIds.add(achievement.id);
      }
    }
    toAnnounce.values.forEach(_unlockController.add);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _unlockController.close();
    super.dispose();
  }
}
