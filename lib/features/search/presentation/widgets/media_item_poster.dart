import 'package:flutter/widgets.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';

/// Caption of a poster: "year · length" (runtime of a movie, seasons of a
/// series), with whatever part is known.
String mediaItemCaption(AppLocalizations l10n, MediaItem item) {
  final year = item.releaseDate.length >= 4
      ? item.releaseDate.substring(0, 4)
      : '';
  final seasons = item.numberOfSeasons;
  final length = item.mediaType == MediaType.tv
      ? (seasons == null ? '' : l10n.mediaSeasonCount(seasons))
      : Formatters.formatRuntime(item.runtime);
  return [year, length].where((part) => part.isNotEmpty).join(' · ');
}

/// Seen state of [item] given how many of its viewings are logged: a series
/// is seen once every episode is, a movie as soon as it has one viewing.
MediaSeenState mediaItemSeenState(MediaItem item, int seenCount) {
  if (seenCount <= 0) return MediaSeenState.none;
  if (item.mediaType != MediaType.tv) return MediaSeenState.seen;
  final episodes = item.numberOfEpisodes;
  return episodes != null && seenCount >= episodes
      ? MediaSeenState.seen
      : MediaSeenState.inProgress;
}

/// Display model of [item] for a [MediaPosterCard].
///
/// [imageSize] is the TMDB poster size (`w92` for thumbnails, `w342` for
/// grids).
MediaPosterData mediaItemPosterData(
  BuildContext context,
  MediaItem item, {
  required int seenCount,
  bool liked = false,
  String imageSize = 'w342',
}) {
  return MediaPosterData(
    title: item.title,
    kind: MediaKind.fromMediaType(item.mediaType),
    imageUrl: TmdbImageUtils.buildUrlWithSizeString(
      item.posterPath,
      size: imageSize,
    ),
    caption: mediaItemCaption(context.l10n, item),
    seen: mediaItemSeenState(item, seenCount),
    rating: item.voteAverage,
    liked: liked,
  );
}
