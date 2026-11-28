import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/library/presentation/utils/list_entry.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';

/// Collapsed poster card for a [SagaListEntry] in a list grid.
class ListSagaGridItem extends StatelessWidget {
  const ListSagaGridItem({
    super.key,
    required this.entry,
    required this.provider,
    required this.isSelected,
    required this.isEditMode,
    required this.onTap,
    this.onLongPress,
  });

  final SagaListEntry entry;
  final SearchProvider provider;
  final bool isSelected;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalCount = entry.movies.length;
    final seenCount = entry.movies
        .where((m) => provider.getSeenCount(m) > 0)
        .length;
    final representative = entry.representativeMovie(
      (m) => provider.getSeenCount(m) > 0,
    );

    final seenState = seenCount == 0
        ? MediaSeenState.none
        : (seenCount == totalCount
              ? MediaSeenState.seen
              : MediaSeenState.inProgress);

    final data = MediaPosterData(
      title: entry.name,
      kind: MediaKind.movie,
      imageUrl: TmdbImageUtils.buildUrlWithSizeString(
        representative.posterPath,
        size: 'w342',
      ),
      caption: l10n.listsSagaSeenProgress(seenCount, totalCount),
      seen: seenState,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        MediaPosterCard(
          data: data,
          showType: false,
          selected: isEditMode ? isSelected : null,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
        PositionedDirectional(
          top: 6,
          start: 6,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: MediaPosterCard.badgeBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.collections_bookmark,
                      size: 12,
                      color: MediaPosterCard.onImage,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalCount',
                      style: const TextStyle(
                        color: MediaPosterCard.onImage,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width header bar for an expanded [SagaListEntry] in grid mode.
class ListSagaGridHeader extends StatelessWidget {
  const ListSagaGridHeader({
    super.key,
    required this.entry,
    required this.provider,
    required this.isEditMode,
    required this.selectedItems,
    required this.onCollapse,
    required this.onToggleSelectEntry,
  });

  final SagaListEntry entry;
  final SearchProvider provider;
  final bool isEditMode;
  final Set<String> selectedItems;
  final VoidCallback onCollapse;
  final VoidCallback onToggleSelectEntry;

  String _itemKey(MediaItem item) => '${item.id}:${item.mediaType.name}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    final totalCount = entry.movies.length;
    final seenCount = entry.movies
        .where((m) => provider.getSeenCount(m) > 0)
        .length;
    final selectedInSaga = entry.movies
        .where((m) => selectedItems.contains(_itemKey(m)))
        .length;
    final allSelected = selectedInSaga == totalCount;
    final someSelected = selectedInSaga > 0 && !allSelected;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Material(
        color: allSelected
            ? colors.primary.withValues(alpha: 0.12)
            : colors.surface2,
        borderRadius: BorderRadius.circular(10),
        child: AppTapTarget(
          tooltip: l10n.listsSagaCollapseTooltip,
          onTap: isEditMode ? onToggleSelectEntry : onCollapse,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.collections_bookmark_outlined,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${l10n.listsSagaMovieCount(totalCount)} · ${l10n.listsSagaSeenProgress(seenCount, totalCount)}',
                        style: TextStyle(fontSize: 12, color: colors.text2),
                      ),
                    ],
                  ),
                ),
                if (isEditMode)
                  Checkbox(
                    tristate: true,
                    value: allSelected ? true : (someSelected ? null : false),
                    onChanged: (_) => onToggleSelectEntry(),
                  )
                else
                  const Icon(Icons.expand_less),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
