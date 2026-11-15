import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Orders offered on the "In progress" page.
enum InProgressSort {
  /// Most recent activity first.
  recent,

  /// Largest share seen first; titles without a known progress come last.
  almostDone,

  /// By title, ignoring case.
  alphabetical,
}

/// [items] in the order of [sort], as a new list. Ties keep the most recent
/// activity first, then the smallest id, so the order is stable.
List<InProgressItem> sortInProgress(
  Iterable<InProgressItem> items,
  InProgressSort sort,
) {
  int byRecent(InProgressItem a, InProgressItem b) {
    final byDate = b.lastActivity.compareTo(a.lastActivity);
    return byDate != 0 ? byDate : a.tmdbId.compareTo(b.tmdbId);
  }

  int compare(InProgressItem a, InProgressItem b) {
    switch (sort) {
      case InProgressSort.recent:
        return byRecent(a, b);
      case InProgressSort.almostDone:
        final byProgress = (b.progress ?? -1).compareTo(a.progress ?? -1);
        return byProgress != 0 ? byProgress : byRecent(a, b);
      case InProgressSort.alphabetical:
        final byTitle = (a.title ?? '').toLowerCase().compareTo(
          (b.title ?? '').toLowerCase(),
        );
        return byTitle != 0 ? byTitle : byRecent(a, b);
    }
  }

  return items.toList()..sort(compare);
}
