import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';

/// A TV episode used to find the next release to surface.
class EpisodeRef {
  final int seasonNumber;
  final int episodeNumber;
  final DateTime? airDate;
  final int? runtime;

  const EpisodeRef({
    required this.seasonNumber,
    required this.episodeNumber,
    this.airDate,
    this.runtime,
  });

  @override
  String toString() => 'EpisodeRef(S$seasonNumber E$episodeNumber)';
}

/// Canonical key for an episode, used in seen-episode lookup sets.
String episodeKey(int seasonNumber, int episodeNumber) =>
    '$seasonNumber:$episodeNumber';

/// The furthest-along watched episode of a series — the "tail" of the viewing
/// progress.
///
/// Position (season, then episode) determines the tail; [seenDate] only breaks
/// ties between entries for the same episode, so marking an older episode later
/// (a rewatch) never moves the tail backwards.
class WatchTail {
  final int seasonNumber;
  final int episodeNumber;
  final DateTime seenDate;

  const WatchTail({
    required this.seasonNumber,
    required this.episodeNumber,
    required this.seenDate,
  });

  @override
  String toString() => 'WatchTail(S$seasonNumber E$episodeNumber @ $seenDate)';
}

/// Returns the furthest-along watched episode from [seenTvItems], or `null` when
/// there is no episode-level seen entry.
///
/// The highest position (season, then episode) wins regardless of the order the
/// entries were created; [SeenItemModel.seenDate] only decides between entries
/// for the same episode. This keeps the tail on the furthest progress rather
/// than on whichever episode was marked most recently.
///
/// Entries without a season/episode (e.g. a generic "show" mark) are ignored.
WatchTail? findLatestTail(Iterable<SeenItemModel> seenTvItems) {
  WatchTail? tail;
  for (final item in seenTvItems) {
    final season = item.seasonNumber;
    final episode = item.episodeNumber;
    if (season == null || episode == null) continue;

    if (tail == null) {
      tail = WatchTail(
        seasonNumber: season,
        episodeNumber: episode,
        seenDate: item.seenDate,
      );
      continue;
    }

    final isFurthest = season > tail.seasonNumber ||
        (season == tail.seasonNumber && episode > tail.episodeNumber);
    final isSameEpisode = season == tail.seasonNumber &&
        episode == tail.episodeNumber &&
        item.seenDate.isAfter(tail.seenDate);

    if (isFurthest || isSameEpisode) {
      tail = WatchTail(
        seasonNumber: season,
        episodeNumber: episode,
        seenDate: item.seenDate,
      );
    }
  }
  return tail;
}

/// Sentinel tail that sits before every episode of a series.
///
/// Used when the viewer has no episode-level history at all: every aired
/// episode then counts as unwatched, so the next episode to surface is the
/// first aired one of the show.
WatchTail seriesStartTail() => WatchTail(
  seasonNumber: 0,
  episodeNumber: 0,
  seenDate: DateTime.fromMillisecondsSinceEpoch(0),
);

/// Returns the first episode after [tail] that the viewer has not seen yet.
///
/// [episodes] must be in viewing order (ascending season, then episode); season
/// 0 (specials) is ignored. Episodes at or before the tail's position are
/// skipped so the result always follows the latest watching streak rather than
/// an older gap the user already moved past. Episodes present in
/// [seenEpisodeKeys] (from [episodeKey]) are skipped too, since the viewer has
/// already watched them.
///
/// The returned episode may have a `null` [EpisodeRef.airDate] — TMDB often
/// lists an announced episode before it has an air date, which surfaces in the
/// UI as "Episode — date TBA".
EpisodeRef? findNextEpisodeAfterTail({
  required WatchTail tail,
  required Iterable<EpisodeRef> episodes,
  required Set<String> seenEpisodeKeys,
}) {
  for (final episode in episodes) {
    if (episode.seasonNumber == 0) continue;
    if (!isEpisodeAfterTail(episode, tail)) continue;
    if (seenEpisodeKeys.contains(
      episodeKey(episode.seasonNumber, episode.episodeNumber),
    )) {
      continue;
    }
    return episode;
  }
  return null;
}

/// Whether [episode] comes after [tail] in viewing order.
bool isEpisodeAfterTail(EpisodeRef episode, WatchTail tail) {
  if (episode.seasonNumber != tail.seasonNumber) {
    return episode.seasonNumber > tail.seasonNumber;
  }
  return episode.episodeNumber > tail.episodeNumber;
}

/// Returns the first episode after [tail] that has already aired and has not
/// been seen, or `null` when the viewer is caught up on everything aired.
///
/// Same ordering rules as [findNextEpisodeAfterTail] (viewing order, season 0
/// ignored, nothing at or before the tail qualifies), with two extra filters:
/// the episode must be absent from [seenEpisodeKeys] and its
/// [EpisodeRef.airDate] must be known and not after [now]. Use this to anchor a
/// release to aired-but-unwatched episodes so an announced upcoming episode can
/// never shadow them.
EpisodeRef? findFirstAiredUnseenAfterTail({
  required WatchTail tail,
  required Iterable<EpisodeRef> episodes,
  required Set<String> seenEpisodeKeys,
  required DateTime now,
}) {
  for (final episode in episodes) {
    if (episode.seasonNumber == 0) continue;
    if (!isEpisodeAfterTail(episode, tail)) continue;
    if (seenEpisodeKeys.contains(
      episodeKey(episode.seasonNumber, episode.episodeNumber),
    )) {
      continue;
    }
    final airDate = episode.airDate;
    if (airDate == null || airDate.isAfter(now)) continue;
    return episode;
  }
  return null;
}
