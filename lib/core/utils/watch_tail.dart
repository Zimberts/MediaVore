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

/// Keys ([episodeKey]) of the episodes present in [seen].
///
/// When [seenSince] is set, only entries seen at or after that instant count,
/// which scopes the set to the viewing streak starting at [seenSince].
/// Entries without a season/episode are ignored.
Set<String> seenEpisodeKeys(
  Iterable<SeenItemModel> seen, {
  DateTime? seenSince,
}) => {
  for (final s in seen)
    if (s.seasonNumber != null &&
        s.episodeNumber != null &&
        (seenSince == null || !s.seenDate.isBefore(seenSince)))
      episodeKey(s.seasonNumber!, s.episodeNumber!),
};

/// Whether [episode] has a known air date that is not after [now].
bool isAired(EpisodeRef episode, DateTime now) {
  final airDate = episode.airDate;
  return airDate != null && !airDate.isAfter(now);
}

/// The most recently watched episode of a series — the "tail" of the latest
/// viewing streak.
///
/// [seenDate] determines recency; when two entries share the same date, the one
/// with the later season, then episode, wins.
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

/// Returns the latest watched streak's tail from [seenTvItems], or `null` when
/// there is no episode-level seen entry.
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

    final dateCmp = item.seenDate.compareTo(tail.seenDate);
    final isLater =
        dateCmp > 0 ||
        (dateCmp == 0 &&
            (season > tail.seasonNumber ||
                (season == tail.seasonNumber && episode > tail.episodeNumber)));

    if (isLater) {
      tail = WatchTail(
        seasonNumber: season,
        episodeNumber: episode,
        seenDate: item.seenDate,
      );
    }
  }
  return tail;
}

/// Returns the first episode after [tail] that the viewer has not seen yet.
///
/// [episodes] must be in viewing order (ascending season, then episode); season
/// 0 (specials) is ignored. Episodes at or before the tail's position are
/// skipped so the result always follows the latest watching streak rather than
/// an older gap the user already moved past. Episodes present in
/// [seenEpisodeKeys] (from [episodeKey]) are skipped too, since the viewer has
/// already watched them. When [where] is given, episodes it rejects are
/// skipped as well.
///
/// The returned episode may have a `null` [EpisodeRef.airDate] — TMDB often
/// lists an announced episode before it has an air date, which surfaces in the
/// UI as "Episode — date TBA".
EpisodeRef? findNextEpisodeAfterTail({
  required WatchTail tail,
  required Iterable<EpisodeRef> episodes,
  required Set<String> seenEpisodeKeys,
  bool Function(EpisodeRef episode)? where,
}) {
  for (final episode in episodes) {
    if (episode.seasonNumber == 0) continue;
    if (!_isAfterTail(episode, tail)) continue;
    if (where != null && !where(episode)) continue;
    if (seenEpisodeKeys.contains(
      episodeKey(episode.seasonNumber, episode.episodeNumber),
    )) {
      continue;
    }
    return episode;
  }
  return null;
}

bool _isAfterTail(EpisodeRef episode, WatchTail tail) {
  if (episode.seasonNumber != tail.seasonNumber) {
    return episode.seasonNumber > tail.seasonNumber;
  }
  return episode.episodeNumber > tail.episodeNumber;
}
