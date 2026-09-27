import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Why a notified release item is not shown in the Notification Center list.
enum ReleaseOmissionReason {
  /// The user already marked the movie, or the notified episode, as seen.
  alreadySeen,

  /// TV episode whose stored release date is older than the stale window.
  olderThan30Days,
}

/// A release that exists in the notification list but is hidden from the UI,
/// together with the reason it is hidden.
class ReleaseOmission {
  final NotifiedItem item;
  final ReleaseOmissionReason reason;

  const ReleaseOmission({required this.item, required this.reason});
}

/// Result of splitting notified items into visible and omitted groups.
class ReleaseFilterResult {
  final List<NotifiedItem> visible;
  final List<ReleaseOmission> omitted;

  const ReleaseFilterResult({required this.visible, required this.omitted});
}

/// Whether [item] has already been seen according to [seenItems].
///
/// - Movies are considered seen if any seen entry exists for the same tmdbId.
/// - TV episodes with season/episode info require that exact episode to be seen.
/// - TV entries without episode info fall back to a date-based check.
bool isReleaseSeen(NotifiedItem item, List<SeenItem> seenItems) {
  if (item.type == MediaType.movie) {
    return seenItems.any((s) => s.tmdbId == item.tmdbId);
  }

  if (item.type == MediaType.tv) {
    if (item.seasonNumber != null && item.episodeNumber != null) {
      return seenItems.any(
        (s) =>
            s.tmdbId == item.tmdbId &&
            s.type == MediaType.tv &&
            s.seasonNumber == item.seasonNumber &&
            s.episodeNumber == item.episodeNumber,
      );
    }

    if (item.releaseDate != null) {
      final releaseDay = DateTime(
        item.releaseDate!.year,
        item.releaseDate!.month,
        item.releaseDate!.day,
      );
      return seenItems.any(
        (s) =>
            s.tmdbId == item.tmdbId &&
            s.type == MediaType.tv &&
            (s.seenDate.isAfter(releaseDay) ||
                _isSameDay(s.seenDate, releaseDay)),
      );
    }
  }

  return false;
}

/// Splits [items] into the releases that should be shown and the ones that are
/// hidden, tagging each hidden item with the reason it was omitted.
///
/// This mirrors the filtering previously performed inline in the Notification
/// Center's releases tab. It is pure (no I/O, no Flutter dependency) so it can
/// be unit tested in isolation.
ReleaseFilterResult filterReleases({
  required List<NotifiedItem> items,
  required List<SeenItem> seenItems,
  required DateTime now,
  Duration staleAfter = const Duration(days: 30),
}) {
  final visible = <NotifiedItem>[];
  final omitted = <ReleaseOmission>[];

  for (final item in items) {
    if (isReleaseSeen(item, seenItems)) {
      omitted.add(
        ReleaseOmission(item: item, reason: ReleaseOmissionReason.alreadySeen),
      );
      continue;
    }

    // Hide old TV releases to reduce clutter, but keep them notified.
    if (item.type == MediaType.tv && item.releaseDate != null) {
      final staleBefore = now.subtract(staleAfter);
      if (item.releaseDate!.isBefore(staleBefore)) {
        omitted.add(
          ReleaseOmission(
            item: item,
            reason: ReleaseOmissionReason.olderThan30Days,
          ),
        );
        continue;
      }
    }

    visible.add(item);
  }

  return ReleaseFilterResult(visible: visible, omitted: omitted);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
