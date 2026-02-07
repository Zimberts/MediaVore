import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';

@lazySingleton
class AchievementProvider with ChangeNotifier {
  final AchievementRepository _repository;
  List<Achievement> _achievements = [];
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

  void _init() {
    _subscription = _repository.watchAchievements().listen((
      updatedAchievements,
    ) {
      _achievements = updatedAchievements;
      _autoUnlock();
      notifyListeners();
    });
    refresh();
  }

  Future<void> refresh() async {
    _achievements = await _repository.getAchievements();
    _autoUnlock();
    notifyListeners();
  }

  Future<void> clearAchievements() async {
    _notifiedIds.clear();
    await _repository.clearAchievements();
    await refresh();
  }

  void _autoUnlock() {
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
          _unlockController.add(achievement);
        }
      } else if (achievement.isPersisted) {
        // Once it is confirmed persisted, we can keep it in notified set
        // or just let the isPersisted check handle it next time.
        _notifiedIds.add(achievement.id);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _unlockController.close();
    super.dispose();
  }
}
