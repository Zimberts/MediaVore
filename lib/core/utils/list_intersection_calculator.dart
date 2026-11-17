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
}
