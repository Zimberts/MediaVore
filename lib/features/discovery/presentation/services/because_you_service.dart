import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:mediavore/core/domain/entities/because_you_data.dart';
import 'package:mediavore/core/domain/entities/liked_item_info.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Candidate source title for recommendations.
class BecauseYouCandidate extends Equatable {
  final int id;
  final MediaType type;
  final String title;
  final BecauseYouReason reason;

  const BecauseYouCandidate({
    required this.id,
    required this.type,
    required this.title,
    required this.reason,
  });

  @override
  List<Object?> get props => [id, type, title, reason];
}

/// Service handling candidate selection, recommendation filtering, and daily caching.
class BecauseYouService {
  static const String cachePrefKey = 'because_you_cache';

  /// Selects candidate titles in priority: liked titles first, else recently watched/in-progress.
  static List<BecauseYouCandidate> selectCandidates({
    required List<LikedItemInfo> likedItems,
    required List<SeenItem> seenItems,
    required List<InProgressItem> inProgressItems,
  }) {
    if (likedItems.isNotEmpty) {
      return likedItems
          .map(
            (e) => BecauseYouCandidate(
              id: e.tmdbId,
              type: e.type,
              title: e.title,
              reason: BecauseYouReason.liked,
            ),
          )
          .toList();
    }

    final candidates = <BecauseYouCandidate>[];

    // Watched movies
    final movies = seenItems.where((s) => s.type == MediaType.movie).toList()
      ..sort((a, b) => b.seenDate.compareTo(a.seenDate));

    // In-progress series
    final series = List<InProgressItem>.from(inProgressItems)
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    var movieIdx = 0;
    var seriesIdx = 0;
    while (movieIdx < movies.length || seriesIdx < series.length) {
      if (movieIdx < movies.length && seriesIdx < series.length) {
        if (movies[movieIdx].seenDate.isAfter(series[seriesIdx].lastActivity)) {
          final m = movies[movieIdx++];
          candidates.add(
            BecauseYouCandidate(
              id: m.tmdbId,
              type: m.type,
              title: m.title,
              reason: BecauseYouReason.watched,
            ),
          );
        } else {
          final s = series[seriesIdx++];
          if (s.title != null && s.title!.isNotEmpty) {
            candidates.add(
              BecauseYouCandidate(
                id: s.tmdbId,
                type: MediaType.tv,
                title: s.title!,
                reason: BecauseYouReason.watched,
              ),
            );
          }
        }
      } else if (movieIdx < movies.length) {
        final m = movies[movieIdx++];
        candidates.add(
          BecauseYouCandidate(
            id: m.tmdbId,
            type: m.type,
            title: m.title,
            reason: BecauseYouReason.watched,
          ),
        );
      } else {
        final s = series[seriesIdx++];
        if (s.title != null && s.title!.isNotEmpty) {
          candidates.add(
            BecauseYouCandidate(
              id: s.tmdbId,
              type: MediaType.tv,
              title: s.title!,
              reason: BecauseYouReason.watched,
            ),
          );
        }
      }
    }

    return candidates;
  }

  /// Filters out items that are already seen or in any user list, taking at most 10.
  ///
  /// Returns empty list if fewer than 3 items remain after filtering.
  static List<MediaItem> filterRecommendations(
    List<MediaItem> rawRecommendations, {
    required bool Function(int id, MediaType type) isSeenOrInList,
  }) {
    final filtered = rawRecommendations
        .where((item) => !isSeenOrInList(item.id, item.mediaType))
        .take(10)
        .toList();

    if (filtered.length < 3) {
      return const [];
    }
    return filtered;
  }

  /// Loads cached recommendations for the day if still valid.
  static Future<BecauseYouData?> loadCached({
    required SharedPreferences prefs,
    required DateTime now,
    required bool Function(int id, MediaType type) isSeenOrInList,
  }) async {
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final raw = prefs.getString(cachePrefKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['date'] != todayStr) return null;
      final cachedData = BecauseYouData.fromJson(
        Map<String, dynamic>.from(map['data'] as Map),
      );
      final validItems = filterRecommendations(
        cachedData.items,
        isSeenOrInList: isSeenOrInList,
      );
      if (validItems.length < 3) return null;
      return BecauseYouData(
        sourceId: cachedData.sourceId,
        sourceType: cachedData.sourceType,
        sourceTitle: cachedData.sourceTitle,
        reason: cachedData.reason,
        items: validItems,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves recommendation data to cache for the current day.
  static Future<void> saveCached({
    required SharedPreferences prefs,
    required DateTime now,
    required BecauseYouData data,
  }) async {
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await prefs.setString(
      cachePrefKey,
      jsonEncode({'date': todayStr, 'data': data.toJson()}),
    );
  }
}
