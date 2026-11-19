import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';

/// Result of an intersection between two lists.
class ListIntersectionResult {
  /// All items present in both lists.
  final List<SharedMediaEntry> commonEntries;

  /// Subset of [commonEntries] that are not in the user's seen history.
  final List<SharedMediaEntry> unseenCommonEntries;

  /// Number of common entries that the user has already seen.
  final int seenCount;

  const ListIntersectionResult({
    required this.commonEntries,
    required this.unseenCommonEntries,
    required this.seenCount,
  });

  bool get isEmpty => commonEntries.isEmpty;
  int get totalCount => commonEntries.length;
}

/// Pure utility that computes the intersection of two lists without a backend.
class ListIntersectionCalculator {
  /// Computes the intersection of [listA] and [listB] based on `(mediaType, tmdbId)`.
  ///
  /// Preserves the order of [listA].
  /// Differentiates between movies and TV shows having the same numeric TMDB ID.
  /// Categorizes matches as seen or unseen based on [seenKeys].
  static ListIntersectionResult intersect({
    required List<SharedMediaEntry> listA,
    required List<SharedMediaEntry> listB,
    Set<(int id, MediaType type)> seenKeys = const {},
  }) {
    final setB = {for (final e in listB) (e.id, e.type)};
    final common = <SharedMediaEntry>[];
    final seen = <SharedMediaEntry>[];
    final unseen = <SharedMediaEntry>[];
    final seenSoFar = <(int id, MediaType type)>{};

    for (final item in listA) {
      final key = (item.id, item.type);
      if (setB.contains(key) && seenSoFar.add(key)) {
        common.add(item);
        if (seenKeys.contains(key)) {
          seen.add(item);
        } else {
          unseen.add(item);
        }
      }
    }

    return ListIntersectionResult(
      commonEntries: common,
      unseenCommonEntries: unseen,
      seenCount: seen.length,
    );
  }

  /// Computes the intersection of N lists for a Together session.
  ///
  /// - [commonEntries]: items present in ALL N lists.
  /// - [almostEntries]: items present in N-1 lists (present only when N >= 3).
  /// - [participantInitials]: participant initials for each item.
  static MultiIntersectionResult multiIntersect({
    required List<({String name, String initials, List<SharedMediaEntry> entries})> lists,
    MediaType? typeFilter,
    bool hideSeen = false,
    Set<(int id, MediaType type)> seenKeys = const {},
  }) {
    if (lists.isEmpty) {
      return const MultiIntersectionResult(
        commonEntries: [],
        almostEntries: [],
        participantInitials: {},
      );
    }

    final totalParticipants = lists.length;
    final Map<SharedMediaEntry, Set<String>> entryToInitials = {};

    for (final participant in lists) {
      final seenForParticipant = <SharedMediaEntry>{};
      for (final entry in participant.entries) {
        if (typeFilter != null && entry.type != typeFilter) continue;
        if (hideSeen && seenKeys.contains((entry.id, entry.type))) continue;
        if (seenForParticipant.add(entry)) {
          entryToInitials.putIfAbsent(entry, () => <String>{}).add(participant.initials);
        }
      }
    }

    final common = <SharedMediaEntry>[];
    final almost = <SharedMediaEntry>[];
    final initialsMap = <String, List<String>>{};

    for (final entry in entryToInitials.entries) {
      final key = '${entry.key.id}:${entry.key.type.name}';
      initialsMap[key] = entry.value.toList();

      final count = entry.value.length;
      if (count == totalParticipants) {
        common.add(entry.key);
      } else if (totalParticipants >= 3 && count == totalParticipants - 1) {
        almost.add(entry.key);
      }
    }

    return MultiIntersectionResult(
      commonEntries: common,
      almostEntries: almost,
      participantInitials: initialsMap,
    );
  }
}

/// Result of multi-participant intersection.
class MultiIntersectionResult {
  /// Titles present in ALL lists (N out of N).
  final List<SharedMediaEntry> commonEntries;

  /// Titles present in N-1 lists (for N >= 3). Empty if N < 3.
  final List<SharedMediaEntry> almostEntries;

  /// Initials of participants who have each title, keyed by `"$id:${type.name}"`.
  final Map<String, List<String>> participantInitials;

  const MultiIntersectionResult({
    required this.commonEntries,
    required this.almostEntries,
    required this.participantInitials,
  });

  bool get isEmpty => commonEntries.isEmpty;
  int get totalCommon => commonEntries.length;
}
