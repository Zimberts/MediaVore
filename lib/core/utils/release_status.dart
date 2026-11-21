import 'package:mediavore/core/domain/entities/media_item.dart';

/// Whether [item] is already out on [now]'s calendar day, in local time.
///
/// Uses [MediaItem.releaseDate] (TMDB `release_date` for a movie,
/// `first_air_date` for a series). A title released today counts as out,
/// whatever the time. An empty or unparsable date counts as not out: TMDB
/// leaves it empty for announced titles without a date.
bool isReleased(MediaItem item, DateTime now) {
  final date = DateTime.tryParse(item.releaseDate);
  if (date == null) return false;
  final local = now.toLocal();
  final today = DateTime(local.year, local.month, local.day);
  final day = DateTime(date.year, date.month, date.day);
  return !day.isAfter(today);
}
