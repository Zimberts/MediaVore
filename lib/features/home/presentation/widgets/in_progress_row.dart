import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/media_progress_bar.dart';
import 'package:mediavore/core/widgets/type_chip.dart';
import 'package:mediavore/features/home/presentation/home_formatters.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_card.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Row of the "In progress" page: poster, next episode, last activity,
/// progress, the button that marks the episode as seen and the menu.
class InProgressRow extends StatelessWidget {
  const InProgressRow({
    super.key,
    required this.item,
    required this.now,
    required this.onOpen,
    required this.onMarkSeen,
    required this.onMenu,
  });

  final InProgressItem item;
  final DateTime now;

  /// Opens the title.
  final VoidCallback onOpen;

  /// Marks the next episode as seen; `null` while it is being marked.
  final VoidCallback? onMarkSeen;

  /// Opens the menu of the series.
  final VoidCallback onMenu;

  static const double _posterWidth = 40;

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
      formatLastActivity(l10n, item.lastActivity, now),
    ].join(' · ');
    final progress = item.progress;
    final total = item.totalEpisodes;

    return Material(
      color: colors.surface,
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(
              child: InkWell(
                onTap: onOpen,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: kMinTapTarget),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      10,
                      8,
                      10,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: _posterWidth,
                          child: ExcludeSemantics(
                            child: MediaPosterCard(
                              compact: true,
                              data: MediaPosterData(
                                title: title,
                                kind: MediaKind.series,
                                imageUrl: tmdbPosterUrl(
                                  item.posterPath,
                                  size: 'w92',
                                ),
                              ),
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
                              // No bar rather than a misleading 0 % when the
                              // number of episodes is not known.
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
            ),
            tooltip: l10n.homeMarkEpisodeSeen(episode, title),
            onPressed: onMarkSeen,
            icon: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.stateOutline),
              ),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(Icons.check, size: 20, color: colors.text),
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
            ),
            tooltip: l10n.inProgressMoreActions(title),
            onPressed: onMenu,
            icon: Icon(Icons.more_vert, size: 20, color: colors.text2),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
