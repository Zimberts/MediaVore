import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/saga_sort.dart';

/// Display entry in a list: either a single [MediaItem] or a collapsible
/// [SagaListEntry] grouping >= 2 movies from the same TMDB collection.
sealed class ListEntry {
  const ListEntry();

  /// All [MediaItem]s represented by this entry.
  List<MediaItem> get items;

  /// Stable widget key identifier.
  String get key;
}

/// A standalone item (movie without saga, single-movie saga, or TV series).
final class SingleListEntry extends ListEntry {
  const SingleListEntry(this.item);

  final MediaItem item;

  @override
  List<MediaItem> get items => [item];

  @override
  String get key => '${item.id}_${item.mediaType.name}';
}

/// A collapsible stack of movies belonging to the same TMDB collection.
final class SagaListEntry extends ListEntry {
  const SagaListEntry({
    required this.collectionId,
    required this.name,
    required this.movies,
  });

  final int collectionId;
  final String name;

  /// Movies in this saga present in the list, sorted chronologically.
  final List<MediaItem> movies;

  @override
  List<MediaItem> get items => movies;

  @override
  String get key => 'saga_$collectionId';

  /// Returns the first unseen movie in chronological order, or the first movie
  /// when all parts have been seen.
  MediaItem representativeMovie(bool Function(MediaItem) isSeen) {
    return movies.firstWhere((m) => !isSeen(m), orElse: () => movies.first);
  }
}

/// Groups movies sharing the same [MediaItem.collectionId] into [SagaListEntry]
/// when at least two movies from that collection are present in [items].
///
/// Each stack is placed at the position of its first member in [items], and its
/// movies are sorted chronologically via [sortSagaByDate]. TV series, items
/// without a collection, and single-movie sagas remain [SingleListEntry].
List<ListEntry> groupMoviesBySaga(
  List<MediaItem> items, {
  required bool enabled,
}) {
  if (!enabled) {
    return [for (final item in items) SingleListEntry(item)];
  }

  final moviesByCollection = <int, List<MediaItem>>{};
  for (final item in items) {
    final collectionId = item.collectionId;
    if (item.mediaType == MediaType.movie && collectionId != null) {
      moviesByCollection.putIfAbsent(collectionId, () => []).add(item);
    }
  }

  final emittedCollections = <int>{};
  final result = <ListEntry>[];

  for (final item in items) {
    final collectionId = item.collectionId;
    if (item.mediaType != MediaType.movie || collectionId == null) {
      result.add(SingleListEntry(item));
      continue;
    }

    final sagaMovies = moviesByCollection[collectionId]!;
    if (sagaMovies.length < 2) {
      result.add(SingleListEntry(item));
      continue;
    }

    if (!emittedCollections.add(collectionId)) {
      continue;
    }

    final sorted = sortSagaByDate(sagaMovies);
    final name =
        sorted
            .map((m) => m.collectionName)
            .firstWhere((n) => n != null && n.isNotEmpty, orElse: () => null) ??
        item.title;

    result.add(
      SagaListEntry(collectionId: collectionId, name: name, movies: sorted),
    );
  }

  return result;
}

/// Reorders [allItems] after moving a [ListEntry] from [oldIndex] to [newIndex]
/// in [visibleEntries], preserving the relative slots of any items filtered out
/// of [visibleEntries] (e.g. by type filter or unreleased filter).
List<MediaItem> reorderCurrentItemsByEntry({
  required List<MediaItem> allItems,
  required List<ListEntry> visibleEntries,
  required int oldIndex,
  required int newIndex,
}) {
  final reorderedEntries = List<ListEntry>.from(visibleEntries);
  final moved = reorderedEntries.removeAt(oldIndex);
  reorderedEntries.insert(newIndex, moved);

  final reorderedVisible = <MediaItem>[
    for (final entry in reorderedEntries) ...entry.items,
  ];
  final visibleSet = reorderedVisible.toSet();

  var visibleCursor = 0;
  return [
    for (final item in allItems)
      if (visibleSet.contains(item))
        reorderedVisible[visibleCursor++]
      else
        item,
  ];
}
