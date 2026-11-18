import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/media_progress_bar.dart';
import 'package:mediavore/features/home/presentation/home_formatters.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_card.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Width of the thumbnails of the "Also in progress" row.
const double kInProgressThumbnailWidth = 96;

/// Thumbnail of a series in progress: poster, progress, title and
/// "next episode · last activity".
class InProgressThumbnail extends StatelessWidget {
  const InProgressThumbnail({
    super.key,
    required this.item,
    required this.now,
    required this.onOpen,
  });

  final InProgressItem item;
  final DateTime now;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final title = item.title ?? l10n.commonUnknown;
    final progress = item.progress;
    final total = item.totalEpisodes;
    final caption = [
      l10n.homeEpisodeCode(item.seasonNumber, item.episodeNumber),
      formatLastActivity(l10n, item.lastActivity, now),
    ].join(' · ');

    return SizedBox(
      width: kInProgressThumbnailWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MediaPosterCard(
            compact: true,
            onTap: onOpen,
            data: MediaPosterData(
              title: title,
              kind: MediaKind.series,
              imageUrl: tmdbPosterUrl(item.posterPath),
              caption: caption,
            ),
          ),
          const SizedBox(height: 4),
          if (progress != null && total != null)
            MediaProgressBar(
              value: progress,
              kind: MediaKind.series,
              height: 4,
              semanticLabel: l10n.detailSeasonProgress(
                item.seenEpisodes,
                total,
              ),
            )
          else
            const SizedBox(height: 4),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Last tile of the "Also in progress" row: how many more, leading to the
/// full list.
class MoreInProgressTile extends StatelessWidget {
  const MoreInProgressTile({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(color: colors.border),
    );

    return SizedBox(
      width: kInProgressThumbnailWidth,
      child: AspectRatio(
        aspectRatio: MediaPosterCard.aspectRatio,
        child: Semantics(
          button: true,
          label: l10n.homeMoreInProgress(count),
          excludeSemantics: true,
          onTap: onTap,
          child: Material(
            color: colors.surface2,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+$count',
                      style: textTheme.titleLarge?.copyWith(color: colors.text),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        l10n.commonSeeAll,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.text,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
