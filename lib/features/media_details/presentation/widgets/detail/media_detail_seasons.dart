import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Cumulative duration info calculated from a season's episodes.
class SeasonDurationInfo {
  final int totalMinutes;
  final bool isApproximate;
  final bool hasKnownDurations;

  const SeasonDurationInfo({
    required this.totalMinutes,
    required this.isApproximate,
    required this.hasKnownDurations,
  });

  /// Calculates total runtime from [episodes].
  ///
  /// Marks [isApproximate] as true when some (but not all) episodes have a known
  /// duration. [hasKnownDurations] is false when no episode has a positive runtime.
  static SeasonDurationInfo calculate(List<dynamic>? episodes) {
    if (episodes == null || episodes.isEmpty) {
      return const SeasonDurationInfo(
        totalMinutes: 0,
        isApproximate: false,
        hasKnownDurations: false,
      );
    }
    final runtimes = episodes
        .map((e) => e is Map ? e['runtime'] : null)
        .whereType<num>()
        .where((r) => r > 0)
        .toList();
    if (runtimes.isEmpty) {
      return const SeasonDurationInfo(
        totalMinutes: 0,
        isApproximate: false,
        hasKnownDurations: false,
      );
    }
    final total = runtimes.fold<int>(0, (sum, r) => sum + r.toInt());
    final isApprox = runtimes.length < episodes.length;
    return SeasonDurationInfo(
      totalMinutes: total,
      isApproximate: isApprox,
      hasKnownDurations: true,
    );
  }
}

/// "Seasons" section of a series: overall progress, then styled season cards
/// with duration, progress bar, and expandable episode list (#318).
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
    final provider = context.watch<SearchProvider>();
    final rewatchStart = provider.getSeriesRewatchStart(item.id);
    final effectiveSeen = rewatchStart != null
        ? seenStatus.where((s) => !s.seenDate.isBefore(rewatchStart)).toList()
        : seenStatus;
    final seasons = item.seasons ?? const <TVSeason>[];
    final total = item.numberOfEpisodes;
    final seenTotal = effectiveSeen
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
            color: colors.series,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.detailProgress(seenTotal, total),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.series,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        for (final season in seasons)
          _season(context, season, rewatchStart: rewatchStart),
      ],
    );
  }

  Widget _season(
    BuildContext context,
    TVSeason season, {
    DateTime? rewatchStart,
  }) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider?>(context);
    final hideNonReleased = settings?.hideNonReleased ?? false;
    final advanced = settings?.advancedTracking ?? false;

    final seasonNumber = season.seasonNumber;
    final isExpanded = expandedSeason == seasonNumber;
    final isLoading = loadingSeasons[seasonNumber] ?? false;
    final effectiveSeen = rewatchStart != null
        ? seenStatus.where((s) => !s.seenDate.isBefore(rewatchStart)).toList()
        : seenStatus;
    final seenInSeason = effectiveSeen
        .where((s) => s.seasonNumber == seasonNumber && s.episodeNumber != null)
        .map((s) => s.episodeNumber)
        .toSet()
        .length;
    final episodeCount = season.episodeCount;
    final isComplete = seenInSeason == episodeCount && episodeCount > 0;

    final episodes = episodesBySeason[seasonNumber];
    final durationInfo = SeasonDurationInfo.calculate(episodes);
    final String? durationStr = durationInfo.hasKnownDurations
        ? Formatters.formatSeasonDuration(
            durationInfo.totalMinutes,
            isApproximate: durationInfo.isApproximate,
            locale: l10n.localeName,
          )
        : null;

    final episodesCountStr = l10n.detailSeasonEpisodes(episodeCount);
    final progressShortStr = l10n.detailSeasonSeenShort(
      seenInSeason,
      episodeCount,
    );
    final subtitle = [
      episodesCountStr,
      if (durationStr != null && durationStr.isNotEmpty) durationStr,
      progressShortStr,
    ].join(' · ');

    final progressValue = episodeCount > 0
        ? (seenInSeason / episodeCount)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? colors.series.withValues(alpha: 0.3)
              : colors.placeholder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            onTap: () => onToggleSeason(seasonNumber),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              season.name ??
                                  l10n.detailSeasonName(seasonNumber),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isComplete
                                    ? colors.series
                                    : colors.text2,
                                fontWeight: isComplete ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isComplete) ...[
                        Icon(
                          Icons.check_circle,
                          color: colors.series,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: colors.text2,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 4,
                      backgroundColor: colors.placeholder,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.series),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && episodes != null) ...[
            const Divider(height: 1),
            _buildEpisodesList(
              context: context,
              seasonNumber: seasonNumber,
              episodes: episodes,
              hideNonReleased: hideNonReleased,
              advanced: advanced,
              rewatchStart: rewatchStart,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEpisodesList({
    required BuildContext context,
    required int seasonNumber,
    required List<dynamic> episodes,
    required bool hideNonReleased,
    required bool advanced,
    DateTime? rewatchStart,
  }) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final filtered = episodes.where((ep) {
      if (!hideNonReleased) return true;
      final airDateStr = ep['air_date'] as String?;
      if (airDateStr == null || airDateStr.isEmpty) return true;
      final airDate = DateTime.tryParse(airDateStr);
      return airDate == null || !airDate.isAfter(now);
    }).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final episode = filtered[index];
        final epNum = episode['episode_number'] as int? ?? (index + 1);
        final epName = (episode['name'] as String?)?.trim() ?? '';
        final airDateStr = episode['air_date'] as String?;
        final airDate = airDateStr != null && airDateStr.isNotEmpty
            ? DateTime.tryParse(airDateStr)
            : null;
        final isUnreleased = airDate != null && airDate.isAfter(now);

        final epRuntime = episode['runtime'] is num
            ? (episode['runtime'] as num).toInt()
            : null;
        final formattedRuntime = Formatters.formatEpisodeDuration(epRuntime);
        final formattedAirDate = airDate != null
            ? Formatters.formatSeenDate(airDate, l10n.localeName)
            : (airDateStr ?? '');

        // Seen history for this specific episode
        final history = seenStatus
            .where(
              (s) => s.seasonNumber == seasonNumber && s.episodeNumber == epNum,
            )
            .toList();
        history.sort((a, b) => b.seenDate.compareTo(a.seenDate));

        final hasSeenInCurrentCycle = rewatchStart != null
            ? history.any((s) => !s.seenDate.isBefore(rewatchStart))
            : history.isNotEmpty;

        final String? seenSubtitle;
        if (history.isNotEmpty) {
          final mostRecent = history.first.seenDate;
          final dateStr = advanced
              ? Formatters.formatSeenDateTime(mostRecent, l10n.localeName)
              : Formatters.formatSeenDate(mostRecent, l10n.localeName);
          if (rewatchStart != null && !hasSeenInCurrentCycle) {
            seenSubtitle = l10n.episodeAlreadySeenOn(dateStr);
          } else {
            seenSubtitle = history.length > 1
                ? l10n.seenSummaryMultiple(history.length, dateStr)
                : l10n.seenSummaryOnce(dateStr);
          }
        } else {
          seenSubtitle = null;
        }

        final metaParts = [
          if (formattedRuntime.isNotEmpty) formattedRuntime,
          if (formattedAirDate.isNotEmpty) formattedAirDate,
          if (seenSubtitle != null) seenSubtitle,
        ].join(' · ');

        final overview = (episode['overview'] as String?)?.trim();

        return Opacity(
          opacity: isUnreleased ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E$epNum: $epName',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (metaParts.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          metaParts,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasSeenInCurrentCycle
                                ? colors.series
                                : colors.text2,
                          ),
                        ),
                      ],
                      if (overview != null && overview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          overview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.text2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SeenManager(
                  key: ValueKey('seen_ep_${item.id}_${seasonNumber}_$epNum'),
                  item: item,
                  seasonNumber: seasonNumber,
                  episodeNumber: epNum,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
