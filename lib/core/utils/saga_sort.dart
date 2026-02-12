import 'package:mediavore/core/domain/entities/media_item.dart';

/// Utilities to sort and rotate saga/collection elements.
///
/// Primary sort key:
/// - For TV: `lastEpisodeAirDate` if available
/// - For movies: `releaseDate`
///
/// Sorting is ascending by date (older -> newer).
DateTime? _parseItemDate(MediaItem item) {
  final src = item.mediaType == MediaType.tv
      ? item.lastEpisodeAirDate
      : item.releaseDate;
  if (src == null || src.isEmpty) return null;
  try {
    return DateTime.tryParse(src);
  } catch (_) {
    return null;
  }
}

List<MediaItem> sortSagaByDate(List<MediaItem> items) {
  final copy = List<MediaItem>.from(items);
  copy.sort((a, b) {
    final da = _parseItemDate(a);
    final db = _parseItemDate(b);
    if (da == null && db == null) return 0;
    if (da == null) return 1; // nulls go last
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return copy;
}

/// Rotate a chronologically-sorted saga list so items after the `currentId`
/// come first, then the preceding items. The current item is omitted from
/// the returned list.
///
/// Example: sorted = [1,2,3,4,5], currentId=3 -> returns [4,5,1,2]
List<MediaItem> rotateSagaElements(List<MediaItem> items, int currentId) {
  if (items.isEmpty) return items;
  final sorted = sortSagaByDate(items);
  final index = sorted.indexWhere((i) => i.id == currentId);
  if (index == -1) return sorted;

  final after = index + 1 < sorted.length ? sorted.sublist(index + 1) : <MediaItem>[];
  final before = sorted.sublist(0, index);
  return [...after, ...before];
}
