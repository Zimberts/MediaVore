import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';

/// "Seasons" section of a series: overall progress, then one expandable row
/// per season with its episodes.
class MediaDetailSeasons extends StatelessWidget {
  const MediaDetailSeasons({
    super.key,
    required this.item,
    required this.seenStatus,
    required this.expandedSeason,
    required this.episodesBySeason,
    required this.loadingSeasons,
    required this.onToggleSeason,
  });

  final MediaItem item;
  final List<SeenItem> seenStatus;
  final int? expandedSeason;
  final Map<int, List<dynamic>> episodesBySeason;
  final Map<int, bool> loadingSeasons;
  final ValueChanged<int> onToggleSeason;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final seasons = item.seasons ?? const <TVSeason>[];
    final total = item.numberOfEpisodes;
    final seenTotal = seenStatus
        .where((s) => s.seasonNumber != null && s.episodeNumber != null)
        .map((s) => '${s.seasonNumber}:${s.episodeNumber}')
        .toSet()
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.detailSeasons),
        if (total != null) ...[
          LinearProgressIndicator(
            value: total > 0 ? seenTotal / total : 0,
            backgroundColor: colors.placeholder,
            color: colors.onWatchlist,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.detailProgress(seenTotal, total),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onWatchlist,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        for (final season in seasons) _season(context, season),
      ],
    );
  }

  Widget _season(BuildContext context, TVSeason season) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final seasonNumber = season.seasonNumber;
    final isExpanded = expandedSeason == seasonNumber;
    final isLoading = loadingSeasons[seasonNumber] ?? false;
    final seenInSeason = seenStatus
        .where((s) => s.seasonNumber == seasonNumber && s.episodeNumber != null)
        .map((s) => s.episodeNumber)
        .toSet()
        .length;
    final isComplete =
        seenInSeason == season.episodeCount && season.episodeCount > 0;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(season.name ?? l10n.detailSeasonName(seasonNumber)),
          subtitle: Text(
            l10n.detailSeasonProgress(seenInSeason, season.episodeCount),
            style: TextStyle(
              color: isComplete ? colors.onWatchlist : null,
              fontWeight: isComplete ? FontWeight.bold : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isComplete)
                Icon(Icons.check_circle, color: colors.onWatchlist),
              isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
          onTap: () => onToggleSeason(seasonNumber),
        ),
        if (isExpanded && episodesBySeason.containsKey(seasonNumber))
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Column(
              children: [
                for (final episode in episodesBySeason[seasonNumber]!)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'E${episode['episode_number']}: ${episode['name']}',
                    ),
                    subtitle: Text(episode['air_date'] ?? ''),
                    trailing: SeenManager(
                      key: ValueKey(
                        'seen_ep_${item.id}_${seasonNumber}_${episode['episode_number']}',
                      ),
                      item: item,
                      seasonNumber: seasonNumber,
                      episodeNumber: episode['episode_number'] as int,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
