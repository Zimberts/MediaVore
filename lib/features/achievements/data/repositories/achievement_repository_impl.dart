import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:rxdart/rxdart.dart';

@LazySingleton(as: AchievementRepository)
class AchievementRepositoryImpl implements AchievementRepository {
  final Isar _isar;
  final MediaListLocalDataSource _localDataSource;

  AchievementRepositoryImpl(this._isar, this._localDataSource);

  static final List<Achievement> _definitions = [
    // --- Movies ---
    const Achievement(id: 'movie_1', title: 'Movie Starter', description: 'Watch your first movie', iconPath: 'assets/achievements/movie_1.png'),
    const Achievement(id: 'movie_10', title: 'Movie Enthusiast', description: 'Watch 10 movies', iconPath: 'assets/achievements/movie_10.png'),
    const Achievement(id: 'movie_50', title: 'Film Fanatic', description: 'Watch 50 movies', iconPath: 'assets/achievements/movie_50.png'),
    const Achievement(id: 'movie_100', title: 'Cinema Buff', description: 'Watch 100 movies', iconPath: 'assets/achievements/movie_100.png'),
    const Achievement(id: 'movie_500', title: 'Cinema Legend', description: 'Watch 500 movies', iconPath: 'assets/achievements/movie_500.png'),
    const Achievement(id: 'movie_1000', title: 'Cinematic Guru', description: 'Watch 1000 movies', iconPath: 'assets/achievements/movie_1000.png'),

    // --- TV Shows ---
    const Achievement(id: 'tv_1', title: 'Series Starter', description: 'Watch your first episode', iconPath: 'assets/achievements/tv_1.png'),
    const Achievement(id: 'tv_50', title: 'TV Regular', description: 'Watch 50 episodes', iconPath: 'assets/achievements/tv_50.png'),
    const Achievement(id: 'tv_250', title: 'Binge Watcher', description: 'Watch 250 episodes', iconPath: 'assets/achievements/tv_250.png'),
    const Achievement(id: 'tv_1000', title: 'TV Master', description: 'Watch 1000 episodes', iconPath: 'assets/achievements/tv_1000.png'),
    const Achievement(id: 'tv_5000', title: 'TV Addict', description: 'Watch 5000 episodes', iconPath: 'assets/achievements/tv_5000.png'),

    // --- Repeat Viewing ---
    const Achievement(id: 'rewatch_movie_2', title: 'Encore!', description: 'Watch the same movie twice', iconPath: 'assets/achievements/rewatch_movie_2.png'),
    const Achievement(id: 'rewatch_movie_5', title: 'Obsessed', description: 'Watch the same movie 5 times', iconPath: 'assets/achievements/rewatch_movie_5.png'),
    const Achievement(id: 'rewatch_movie_10', title: 'Cult Follower', description: 'Watch the same movie 10 times', iconPath: 'assets/achievements/rewatch_movie_10.png'),
    const Achievement(id: 'rewatch_ep_2', title: 'Double Take', description: 'Watch the same episode twice', iconPath: 'assets/achievements/rewatch_ep_2.png'),
    const Achievement(id: 'rewatch_ep_5', title: 'Déjà Vu', description: 'Watch the same episode 5 times', iconPath: 'assets/achievements/rewatch_ep_5.png'),

    // --- Loyalists ---
    const Achievement(id: 'loyalist_100', title: 'Super Fan', description: 'Watch 100 episodes of the same show', iconPath: 'assets/achievements/loyalist_100.png'),
    const Achievement(id: 'loyalist_500', title: 'Ultimate Stalker', description: 'Watch 500 episodes of the same show', iconPath: 'assets/achievements/loyalist_500.png'),

    // --- Genres ---
    const Achievement(id: 'genre_horror', title: 'Scream Queen/King', description: 'Watch 10 horror movies', iconPath: 'assets/achievements/horror.png'),
    const Achievement(id: 'genre_horror_50', title: 'Horror Harvester', description: 'Watch 50 horror movies', iconPath: 'assets/achievements/horror_50.png'),
    const Achievement(id: 'genre_comedy', title: 'Laugh Riot', description: 'Watch 20 comedy movies', iconPath: 'assets/achievements/comedy.png'),
    const Achievement(id: 'genre_comedy_100', title: 'King of Comedy', description: 'Watch 100 comedy movies', iconPath: 'assets/achievements/comedy_100.png'),
    const Achievement(id: 'genre_action', title: 'Adrenaline Junkie', description: 'Watch 20 action movies', iconPath: 'assets/achievements/action.png'),
    const Achievement(id: 'genre_action_100', title: 'Action Hero', description: 'Watch 100 action movies', iconPath: 'assets/achievements/action_100.png'),
    const Achievement(id: 'genre_scifi', title: 'Future Explorer', description: 'Watch 20 sci-fi movies', iconPath: 'assets/achievements/scifi.png'),
    const Achievement(id: 'genre_scifi_100', title: 'Galactic Traveler', description: 'Watch 100 sci-fi movies', iconPath: 'assets/achievements/scifi_100.png'),
    const Achievement(id: 'genre_doc', title: 'Scholar', description: 'Watch 10 documentaries', iconPath: 'assets/achievements/doc.png'),
    const Achievement(id: 'genre_doc_50', title: 'Professor', description: 'Watch 50 documentaries', iconPath: 'assets/achievements/doc_50.png'),
    const Achievement(id: 'genre_romance', title: 'Hopeless Romantic', description: 'Watch 15 romance movies', iconPath: 'assets/achievements/romance.png'),

    // --- Time/Behavioral ---
    const Achievement(id: 'night_owl', title: 'Night Owl', description: 'Watch 10 items between 12 AM and 4 AM', iconPath: 'assets/achievements/night_owl.png'),
    const Achievement(id: 'night_owl_100', title: 'Creature of the Night', description: 'Watch 100 items between 12 AM and 4 AM', iconPath: 'assets/achievements/night_owl_100.png'),
    const Achievement(id: 'weekend_warrior', title: 'Weekend Warrior', description: 'Watch 15 items in a single weekend', iconPath: 'assets/achievements/weekend.png'),
    const Achievement(id: 'marathon', title: 'Marathon Runner', description: 'Watch 10 episodes of the same show in one day', iconPath: 'assets/achievements/marathon.png'),
    const Achievement(id: 'marathon_pro', title: 'Marathon Pro', description: 'Watch 20 episodes of the same show in one day', iconPath: 'assets/achievements/marathon_pro.png'),
    const Achievement(id: 'streak_7', title: 'Consistent', description: 'Watch something every day for a week', iconPath: 'assets/achievements/streak_7.png'),
    const Achievement(id: 'streak_30', title: 'Dedicated', description: 'Watch something every day for a month', iconPath: 'assets/achievements/streak_30.png'),
    const Achievement(id: 'streak_365', title: 'Unstoppable', description: 'Watch something every day for a year', iconPath: 'assets/achievements/streak_365.png'),
    
    // --- Total Runtime ---
    const Achievement(id: 'runtime_1000', title: '1000 Minutes Club', description: 'Spend 1000 minutes watching media', iconPath: 'assets/achievements/time_1000.png'),
    const Achievement(id: 'runtime_hour_100', title: 'Seasoned Viewer', description: 'Watch for 100 hours total', iconPath: 'assets/achievements/time_100h.png'),
    const Achievement(id: 'runtime_10000', title: '10,000 Minutes Club', description: 'Spend 10,000 minutes watching media', iconPath: 'assets/achievements/time_10000.png'),
    const Achievement(id: 'runtime_day_10', title: 'Ten Day Marathon', description: 'Watch for 10 full days total', iconPath: 'assets/achievements/time_10d.png'),
    const Achievement(id: 'runtime_hour_1000', title: 'The Millennial', description: 'Watch for 1,000 hours total', iconPath: 'assets/achievements/time_1000h.png'),
    const Achievement(id: 'runtime_100000', title: '100,000 Minutes Club', description: 'Spend 100,000 minutes watching media', iconPath: 'assets/achievements/time_100000.png'),
    const Achievement(id: 'runtime_year_1', title: 'Double Life', description: 'Watch for 1 full year total', iconPath: 'assets/achievements/time_1y.png'),
  ];

  @override
  Future<List<Achievement>> getAchievements() async {
    final seenItems = await _localDataSource.getAllSeenItems();
    final chronologicalItems = List<SeenItemModel>.from(seenItems)
      ..sort((a, b) => a.seenDate.compareTo(b.seenDate));

    final unlockedModels = await _isar.achievementModels.where().findAll();
    final unlockedMap = {for (var m in unlockedModels) m.achievementId: m.unlockedAt};

    return _definitions.map((def) {
      final progressData = _calculateProgress(def.id, chronologicalItems);
      final persistedUnlockDate = unlockedMap[def.id];
      final calculatedUnlockDate = progressData.milestoneReachedAt;
      
      return Achievement(
        id: def.id,
        title: def.title,
        description: def.description,
        iconPath: def.iconPath,
        isUnlocked: calculatedUnlockDate != null, // Reached in history
        isPersisted: persistedUnlockDate != null, // Saved in DB
        unlockedAt: persistedUnlockDate ?? calculatedUnlockDate,
        progress: progressData.progress,
        progressLabel: progressData.label,
      );
    }).toList();
  }

  @override
  Future<void> unlockAchievement(String achievementId, DateTime unlockedAt) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.achievementModels
          .filter()
          .achievementIdEqualTo(achievementId)
          .findFirst();
      
      if (existing == null) {
        await _isar.achievementModels.put(AchievementModel(
          achievementId: achievementId,
          unlockedAt: unlockedAt,
        ));
      }
    });
  }

  @override
  Future<void> clearAchievements() async {
    await _isar.writeTxn(() async {
      await _isar.achievementModels.where().deleteAll();
    });
  }

  @override
  Stream<List<Achievement>> watchAchievements() {
    return Rx.merge([
      _isar.achievementModels.watchLazy(),
      _isar.seenItemModels.watchLazy(),
    ]).asyncMap((_) => getAchievements());
  }

  _ProgressData _calculateProgress(String id, List<SeenItemModel> seenItems) {
    final movies = seenItems.where((i) => i.type == 'movie').toList();
    final episodes = seenItems.where((i) => i.type == 'tv').toList();

    switch (id) {
      // --- Movies ---
      case 'movie_1': return _countMilestone(movies, 1);
      case 'movie_10': return _countMilestone(movies, 10);
      case 'movie_50': return _countMilestone(movies, 50);
      case 'movie_100': return _countMilestone(movies, 100);
      case 'movie_500': return _countMilestone(movies, 500);
      case 'movie_1000': return _countMilestone(movies, 1000);

      // --- TV ---
      case 'tv_1': return _countMilestone(episodes, 1);
      case 'tv_50': return _countMilestone(episodes, 50);
      case 'tv_250': return _countMilestone(episodes, 250);
      case 'tv_1000': return _countMilestone(episodes, 1000);
      case 'tv_5000': return _countMilestone(episodes, 5000);

      // --- Rewatches ---
      case 'rewatch_movie_2': return _rewatchMilestone(movies, 2);
      case 'rewatch_movie_5': return _rewatchMilestone(movies, 5);
      case 'rewatch_movie_10': return _rewatchMilestone(movies, 10);
      case 'rewatch_ep_2': return _rewatchMilestone(episodes, 2, isTv: true);
      case 'rewatch_ep_5': return _rewatchMilestone(episodes, 5, isTv: true);

      // --- Loyalists ---
      case 'loyalist_100': return _loyalistMilestone(episodes, 100);
      case 'loyalist_500': return _loyalistMilestone(episodes, 500);

      // --- Genres ---
      case 'genre_horror': return _genreMilestone(movies, 'Horror', 10);
      case 'genre_horror_50': return _genreMilestone(movies, 'Horror', 50);
      case 'genre_comedy': return _genreMilestone(movies, 'Comedy', 20);
      case 'genre_comedy_100': return _genreMilestone(movies, 'Comedy', 100);
      case 'genre_action': return _genreMilestone(movies, 'Action', 20);
      case 'genre_action_100': return _genreMilestone(movies, 'Action', 100);
      case 'genre_scifi': return _genreMilestone(movies, 'Science Fiction', 20);
      case 'genre_scifi_100': return _genreMilestone(movies, 'Science Fiction', 100);
      case 'genre_doc': return _genreMilestone(movies, 'Documentary', 10);
      case 'genre_doc_50': return _genreMilestone(movies, 'Documentary', 50);
      case 'genre_romance': return _genreMilestone(movies, 'Romance', 15);

      // --- Behavioral ---
      case 'night_owl':
        final nightItems = seenItems.where((i) => i.seenDate.hour >= 0 && i.seenDate.hour < 4).toList();
        return _countMilestone(nightItems, 10);
      case 'night_owl_100':
        final nightItems = seenItems.where((i) => i.seenDate.hour >= 0 && i.seenDate.hour < 4).toList();
        return _countMilestone(nightItems, 100);
      case 'streak_7': return _streakMilestone(seenItems, 7);
      case 'streak_30': return _streakMilestone(seenItems, 30);
      case 'streak_365': return _streakMilestone(seenItems, 365);

      // --- Runtime ---
      case 'runtime_1000': return _runtimeMilestone(seenItems, 1000);
      case 'runtime_hour_100': return _runtimeMilestone(seenItems, 100 * 60);
      case 'runtime_10000': return _runtimeMilestone(seenItems, 10000);
      case 'runtime_day_10': return _runtimeMilestone(seenItems, 10 * 24 * 60);
      case 'runtime_hour_1000': return _runtimeMilestone(seenItems, 1000 * 60);
      case 'runtime_100000': return _runtimeMilestone(seenItems, 100000);
      case 'runtime_year_1': return _runtimeMilestone(seenItems, 365 * 24 * 60);
      
      default:
        return const _ProgressData(0.0, '0/0');
    }
  }

  _ProgressData _countMilestone(List<SeenItemModel> items, int target) {
    final count = items.length;
    return _ProgressData(
      (count / target).clamp(0.0, 1.0),
      '$count/$target',
      milestoneReachedAt: count >= target ? items[target - 1].seenDate : null,
    );
  }

  _ProgressData _genreMilestone(List<SeenItemModel> items, String genre, int target) {
    final filtered = items.where((i) => i.genres?.contains(genre) ?? false).toList();
    final count = filtered.length;
    return _ProgressData(
      (count / target).clamp(0.0, 1.0),
      '$count/$target',
      milestoneReachedAt: count >= target ? filtered[target - 1].seenDate : null,
    );
  }

  _ProgressData _runtimeMilestone(List<SeenItemModel> items, int targetMinutes) {
    int total = 0;
    DateTime? reachedAt;
    for (final item in items) {
      total += item.runtime ?? 0;
      if (total >= targetMinutes && reachedAt == null) {
        reachedAt = item.seenDate;
      }
    }
    return _ProgressData(
      (total / targetMinutes).clamp(0.0, 1.0),
      '$total/$targetMinutes min',
      milestoneReachedAt: reachedAt,
    );
  }

  _ProgressData _rewatchMilestone(List<SeenItemModel> items, int target, {bool isTv = false}) {
    final counts = <String, int>{};
    int maxCount = 0;
    DateTime? reachedAt;

    for (final item in items) {
      final key = isTv ? '${item.tmdbId}_${item.seasonNumber}_${item.episodeNumber}' : '${item.tmdbId}';
      counts[key] = (counts[key] ?? 0) + 1;
      if (counts[key]! >= target && reachedAt == null) {
        reachedAt = item.seenDate;
      }
      if (counts[key]! > maxCount) maxCount = counts[key]!;
    }

    return _ProgressData(
      (maxCount / target).clamp(0.0, 1.0),
      '$maxCount/$target',
      milestoneReachedAt: reachedAt,
    );
  }

  _ProgressData _loyalistMilestone(List<SeenItemModel> episodes, int target) {
    final counts = <int, int>{};
    int maxCount = 0;
    DateTime? reachedAt;

    for (final item in episodes) {
      counts[item.tmdbId] = (counts[item.tmdbId] ?? 0) + 1;
      if (counts[item.tmdbId]! >= target && reachedAt == null) {
        reachedAt = item.seenDate;
      }
      if (counts[item.tmdbId]! > maxCount) maxCount = counts[item.tmdbId]!;
    }

    return _ProgressData(
      (maxCount / target).clamp(0.0, 1.0),
      '$maxCount/$target',
      milestoneReachedAt: reachedAt,
    );
  }

  _ProgressData _streakMilestone(List<SeenItemModel> items, int target) {
    if (items.isEmpty) return const _ProgressData(0.0, '0/0');
    
    final dates = items.map((i) => DateTime(i.seenDate.year, i.seenDate.month, i.seenDate.day)).toSet().toList()
      ..sort();

    int currentStreak = 1;
    int maxStreak = 1;
    DateTime? reachedAt;

    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        currentStreak++;
        if (currentStreak >= target && reachedAt == null) {
          reachedAt = dates[i];
        }
      } else {
        currentStreak = 1;
      }
      if (currentStreak > maxStreak) maxStreak = currentStreak;
    }

    return _ProgressData(
      (maxStreak / target).clamp(0.0, 1.0),
      '$maxStreak/$target days',
      milestoneReachedAt: reachedAt,
    );
  }
}

class _ProgressData {
  final double progress;
  final String label;
  final DateTime? milestoneReachedAt;
  const _ProgressData(this.progress, this.label, {this.milestoneReachedAt});
}
