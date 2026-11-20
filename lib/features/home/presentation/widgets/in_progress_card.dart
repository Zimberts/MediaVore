import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/core/widgets/app_card.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/media_progress_bar.dart';
import 'package:mediavore/core/widgets/type_chip.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// URL of a TMDB poster, or `null` without a path.
String? tmdbPosterUrl(String? posterPath, {String size = 'w185'}) =>
    TmdbImageUtils.buildUrlWithSizeString(posterPath, size: size);

/// "Resume" card of a series: poster, next episode, progress and the button
/// that marks this episode as seen.
class InProgressCard extends StatelessWidget {
  const InProgressCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onMarkSeen,
  });

  final InProgressItem item;

  /// Opens the title.
  final VoidCallback onOpen;

  /// Marks the next episode as seen; `null` while it is being marked.
  final VoidCallback? onMarkSeen;

  static const double _posterWidth = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final title = item.title ?? l10n.commonUnknown;
    final episode = l10n.homeEpisodeCode(item.seasonNumber, item.episodeNumber);
    final runtime = Formatters.formatRuntime(item.runtime);
    final label = [
      l10n.homeNextEpisode(episode),
      if (runtime.isNotEmpty) runtime,
    ].join(' · ');
    final progress = item.progress;
    final total = item.totalEpisodes;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: _posterWidth,
            child: MediaPosterCard(
              compact: true,
              onTap: onOpen,
              data: MediaPosterData(
                title: title,
                kind: MediaKind.series,
                imageUrl: tmdbPosterUrl(item.posterPath),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const TypeChip(kind: MediaKind.series),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(label, style: textTheme.bodySmall),
                // No bar rather than a misleading 0 % when the number of
                // episodes is not known.
                if (progress != null && total != null) ...[
                  const SizedBox(height: 6),
                  MediaProgressBar(
                    value: progress,
                    kind: MediaKind.series,
                    semanticLabel: l10n.detailSeasonProgress(
                      item.seenEpisodes,
                      total,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: l10n.homeMarkEpisodeSeen(episode, title),
            child: Semantics(
              button: true,
              enabled: onMarkSeen != null,
              label: l10n.homeMarkEpisodeSeen(episode, title),
              excludeSemantics: true,
              onTap: onMarkSeen,
              child: Material(
                color: colors.primary,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onMarkSeen,
                  child: SizedBox.square(
                    dimension: kMinTapTarget,
                    child: Icon(Icons.check, size: 20, color: colors.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
