/// Represents an episode candidate for unseen checks and batch marking.
class CandidateEpisode {
  final int seasonNumber;
  final int episodeNumber;
  final String? name;
  final int? runtime;
  final String? airDate;

  const CandidateEpisode({
    required this.seasonNumber,
    required this.episodeNumber,
    this.name,
    this.runtime,
    this.airDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandidateEpisode &&
          seasonNumber == other.seasonNumber &&
          episodeNumber == other.episodeNumber;

  @override
  int get hashCode => Object.hash(seasonNumber, episodeNumber);
}

/// Lists all previous unseen episodes before [targetSeason] and [targetEpisode].
///
/// Rules:
/// - Excludes Season 0 ("hors saison 0").
/// - Excludes episodes already seen in [seenEpisodeKeys] (keys formatted as `"$season:$episode"`).
/// - Excludes un-aired episodes based on [now] and [CandidateEpisode.airDate] ("hors épisodes non diffusés").
/// - Only includes episodes strictly anterior to the target:
///   `season < targetSeason || (season == targetSeason && episode < targetEpisode)`.
/// - Returned list is sorted in chronological watching order (season ascending, then episode ascending).
List<CandidateEpisode> findPreviousUnseenEpisodes({
  required int targetSeason,
  required int targetEpisode,
  required Iterable<CandidateEpisode> allEpisodes,
  required Set<String> seenEpisodeKeys,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final unseen = <CandidateEpisode>[];

  for (final ep in allEpisodes) {
    if (ep.seasonNumber <= 0) continue;

    // Must be strictly anterior
    if (ep.seasonNumber > targetSeason) continue;
    if (ep.seasonNumber == targetSeason && ep.episodeNumber >= targetEpisode) {
      continue;
    }

    final key = '${ep.seasonNumber}:${ep.episodeNumber}';
    if (seenEpisodeKeys.contains(key)) continue;

    if (ep.airDate != null && ep.airDate!.isNotEmpty) {
      try {
        final airDateTime = DateTime.parse(ep.airDate!);
        if (airDateTime.isAfter(effectiveNow)) continue;
      } catch (_) {
        // If unparseable air date, treat as aired
      }
    }

    unseen.add(ep);
  }

  unseen.sort((a, b) {
    final sComp = a.seasonNumber.compareTo(b.seasonNumber);
    if (sComp != 0) return sComp;
    return a.episodeNumber.compareTo(b.episodeNumber);
  });

  return unseen;
}
