import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/type_chip.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// Header of the detail page: fixed-size poster on the left; type, title,
/// "year · length", rating and personal status, production status and the
/// round like / notify / more buttons on the right.
class MediaDetailHeader extends StatelessWidget {
  const MediaDetailHeader({
    super.key,
    required this.item,
    required this.seenStatus,
    required this.onMore,
    this.showDetails = true,
  });

  final MediaItem item;

  /// Seen entries of this title (every episode for a series).
  final List<SeenItem> seenStatus;

  /// Opens the "more" menu.
  final VoidCallback onMore;

  /// `false` while offline: rating and production status are unknown.
  final bool showDetails;

  static const double posterWidth = 110;
  static const double posterHeight = 165;
  static const int titleMaxLines = 3;

  @visibleForTesting
  static const Key posterKey = Key('media_detail_poster');
  @visibleForTesting
  static const Key titleKey = Key('media_detail_title');
  @visibleForTesting
  static const Key metaKey = Key('media_detail_meta');
  @visibleForTesting
  static const Key moreKey = Key('media_detail_more');

  /// "year · length" for a film, "year · n seasons · n episodes · ~x min"
  /// for a series. The only place of the page that gives them.
  static String metaLine(AppLocalizations l10n, MediaItem item) {
    final year = item.releaseDate.length >= 4
        ? item.releaseDate.substring(0, 4)
        : item.releaseDate;
    final runtime = item.runtime ?? 0;
    final isTv = item.mediaType == MediaType.tv;
    return [
      if (year.isNotEmpty) year,
      if (isTv && item.numberOfSeasons != null)
        l10n.detailSeasonCount(item.numberOfSeasons!),
      if (isTv && item.numberOfEpisodes != null)
        l10n.detailEpisodeCount(item.numberOfEpisodes!),
      if (runtime > 0)
        isTv
            ? l10n.detailEpisodeRuntime(runtime)
            : Formatters.formatRuntime(runtime),
    ].join(' · ');
  }

  /// What the user did with the title: "Seen", "Seen 3 times", "Finished",
  /// "Watched 2 times", or "2nd watch · Next: S1 E1".
  String? _personalStatus(
    BuildContext context,
    AppLocalizations l10n,
    SearchProvider provider,
  ) {
    if (item.mediaType == MediaType.tv) {
      final total = item.numberOfEpisodes ?? 0;
      final episodeSeen = seenStatus
          .where(
            (s) =>
                s.seasonNumber != null &&
                s.episodeNumber != null &&
                s.seasonNumber! > 0,
          )
          .toList();
      final completedCycles = SearchProvider.calculateCompletedCycles(
        item,
        episodeSeen,
      );
      final rewatchStart = provider.getSeriesRewatchStart(item.id);

      if (rewatchStart != null) {
        final cycle = (completedCycles > 0 ? completedCycles : 1) + 1;
        final inCycleKeys = episodeSeen
            .where((s) => !s.seenDate.isBefore(rewatchStart))
            .map((s) => '${s.seasonNumber}:${s.episodeNumber}')
            .toSet();
        if (total > 0 && inCycleKeys.length >= total) {
          final totalCompleted = completedCycles + 1;
          return totalCompleted > 1
              ? l10n.detailSeriesWatchedTimes(totalCompleted)
              : l10n.detailSeriesFinished;
        }

        int nextS = 1;
        int nextE = 1;
        if (inCycleKeys.isNotEmpty) {
          final inCycleList = episodeSeen
              .where((s) => !s.seenDate.isBefore(rewatchStart))
              .toList();
          inCycleList.sort((a, b) {
            final sc = b.seasonNumber!.compareTo(a.seasonNumber!);
            if (sc != 0) return sc;
            return b.episodeNumber!.compareTo(a.episodeNumber!);
          });
          final latest = inCycleList.first;
          final seasons = item.seasons;
          final currentSeason = seasons?.firstWhere(
            (s) => s.seasonNumber == latest.seasonNumber,
            orElse: () =>
                const TVSeason(id: -1, seasonNumber: -1, episodeCount: 0),
          );
          if (currentSeason != null &&
              currentSeason.seasonNumber != -1 &&
              latest.episodeNumber! < currentSeason.episodeCount) {
            nextS = latest.seasonNumber!;
            nextE = latest.episodeNumber! + 1;
          } else {
            nextS = latest.seasonNumber! + 1;
            nextE = 1;
          }
        }
        return l10n.detailSeriesRewatching(cycle.toString(), nextS, nextE);
      }

      if (completedCycles > 1) {
        return l10n.detailSeriesWatchedTimes(completedCycles);
      } else if (total > 0 &&
          episodeSeen
                  .map((s) => '${s.seasonNumber}:${s.episodeNumber}')
                  .toSet()
                  .length >=
              total) {
        return l10n.detailSeriesFinished;
      }
      return null;
    }
    if (seenStatus.isEmpty) return null;
    return seenStatus.length > 1
        ? l10n.detailSeenTimes(seenStatus.length)
        : l10n.seenSeen;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<SearchProvider>();
    final kind = MediaKind.fromMediaType(item.mediaType);
    final meta = metaLine(l10n, item);
    final rating = item.voteAverage;
    final personal = _personalStatus(context, l10n, provider);
    final isLiked = provider.isLiked(item);
    final isNotified = provider.isNotified(item);
    final muted = textTheme.bodySmall?.copyWith(color: colors.text2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          key: posterKey,
          width: posterWidth,
          height: posterHeight,
          child: MediaPosterCard(
            compact: true,
            showType: false,
            data: MediaPosterData(
              title: item.title,
              kind: kind,
              imageUrl: TmdbImageUtils.buildUrl(
                item.posterPath,
                size: TmdbImageSize.w342,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypeChip(kind: kind),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text(
                  item.title,
                  key: titleKey,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(height: 1.15),
                ),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  meta,
                  key: metaKey,
                  style: textTheme.bodyMedium?.copyWith(color: colors.text2),
                ),
              ],
              if ((showDetails && rating != null && rating > 0) ||
                  personal != null) ...[
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      if (showDetails && rating != null && rating > 0) ...[
                        TextSpan(
                          text:
                              '★ ${NumberFormat('0.0', l10n.localeName).format(rating)} ',
                          semanticsLabel: l10n.detailRating(
                            NumberFormat('0.0', l10n.localeName).format(rating),
                          ),
                        ),
                        TextSpan(text: 'TMDB', style: muted),
                        if (personal != null) const TextSpan(text: ' · '),
                      ],
                      if (personal != null)
                        TextSpan(
                          text: personal,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                  style: textTheme.bodyMedium,
                ),
              ],
              if (showDetails && item.status != null) ...[
                const SizedBox(height: 2),
                Text(localizedMediaStatus(l10n, item.status!), style: muted),
              ],
              const SizedBox(height: 4),
              Material(
                type: MaterialType.transparency,
                child: Wrap(
                  children: [
                    DetailRoundButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? colors.likeHeart : null,
                      selected: isLiked,
                      tooltip: isLiked ? l10n.likeUnlike : l10n.likeLike,
                      onTap: () => provider.toggleLike(item),
                    ),
                    if (item.canBeNotified || isNotified)
                      DetailRoundButton(
                        icon: isNotified
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        color: isNotified ? colors.warning : null,
                        selected: isNotified,
                        tooltip: isNotified
                            ? l10n.notifyDisable
                            : l10n.notifyEnable,
                        onTap: () => provider.toggleNotification(item),
                      ),
                    DetailRoundButton(
                      key: moreKey,
                      icon: Icons.more_vert,
                      tooltip: l10n.detailMoreActions,
                      onTap: onMore,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Round icon button of the header: 44 dp visible, 48 dp touch area.
class DetailRoundButton extends StatelessWidget {
  const DetailRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.selected,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final bool? selected;

  static const double visibleSize = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppTapTarget(
      onTap: onTap,
      tooltip: tooltip,
      semanticLabel: tooltip,
      selected: selected,
      child: Container(
        width: visibleSize,
        height: visibleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface,
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: 20, color: color ?? colors.text),
      ),
    );
  }
}
