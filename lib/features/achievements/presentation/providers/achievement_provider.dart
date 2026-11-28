import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement_family.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';

@lazySingleton
class AchievementProvider with ChangeNotifier {
  /// Maximum number of achievement families announced individually before
  /// collapsing into a single grouped notification.
  static const int groupThreshold = 3;

  /// Debounce window used to collect unlocks across rapid DB emissions (e.g.
  /// multi-transaction imports) into a single batch.
  static const Duration defaultBatchWindow = Duration(milliseconds: 500);

  final AchievementRepository _repository;
  final Duration _batchWindow;
  List<Achievement> _achievements = [];
  List<AchievementFamily> _families = [];
  StreamSubscription<void>? _subscription;

  // Track IDs we've already sent a notification for in this session
  // to avoid redundant triggers while persistence is in progress.
  final Set<String> _notifiedIds = {};
  final Map<String, Achievement> _pendingBatch = {};
  Timer? _batchTimer;

  final _unlockController = StreamController<List<Achievement>>.broadcast();
  Stream<List<Achievement>> get onAchievementUnlocked =>
      _unlockController.stream;

  AchievementProvider(
    this._repository, {
    @ignoreParam Duration batchWindow = defaultBatchWindow,
  }) : _batchWindow = batchWindow {
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

  /// Logs a completed export (backup) and re-evaluates the achievements; the
  /// export log is not watched.
  Future<void> recordExport() async {
    await _repository.recordExport(DateTime.now());
    await refresh();
  }

  Future<void> clearAchievements() async {
    _batchTimer?.cancel();
    _batchTimer = null;
    _pendingBatch.clear();
    _notifiedIds.clear();
    await _repository.clearAchievements();
    await refresh();
  }

  void _autoUnlock() {
    // Newly unlocked tiers of the same family are all persisted, but only the
    // highest one is announced, so reaching several levels at once (or new
    // lower tiers added by an update) produces a single notification.
    var added = false;
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
          final previous = _pendingBatch[key];
          if (previous == null ||
              (achievement.tier ?? 0) > (previous.tier ?? 0)) {
            _pendingBatch[key] = achievement;
          }
          added = true;
        }
      } else if (achievement.isPersisted) {
        // Once it is confirmed persisted, we can keep it in notified set
        // or just let the isPersisted check handle it next time.
        _notifiedIds.add(achievement.id);
      }
    }
    if (added) {
      _batchTimer?.cancel();
      if (_batchWindow == Duration.zero) {
        _flushBatch();
      } else {
        _batchTimer = Timer(_batchWindow, _flushBatch);
      }
    }
  }

  void _flushBatch() {
    _batchTimer?.cancel();
    _batchTimer = null;
    if (_pendingBatch.isEmpty || _unlockController.isClosed) return;
    final batch = _pendingBatch.values.toList();
    _pendingBatch.clear();
    if (batch.length > groupThreshold) {
      _unlockController.add(batch);
    } else {
      for (final achievement in batch) {
        _unlockController.add([achievement]);
      }
    }
  }

  @override
  void dispose() {
    _batchTimer?.cancel();
    _subscription?.cancel();
    _unlockController.close();
    super.dispose();
  }
}
