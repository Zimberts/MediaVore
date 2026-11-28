import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/library/presentation/utils/list_entry.dart';
import 'package:mediavore/features/library/presentation/widgets/list_media_tile.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/media_item_poster.dart';

/// Detailed list tile for a [SagaListEntry], expanding inline to show its
/// movies in chronological order.
class ListSagaTile extends StatelessWidget {
  const ListSagaTile({
    super.key,
    required this.index,
    required this.entry,
    required this.provider,
    required this.isExpanded,
    required this.isEditMode,
    required this.selectedItems,
    required this.isManualSort,
    required this.onToggleExpand,
    required this.onToggleSelectEntry,
    required this.onToggleSelectItem,
    required this.onTapMovie,
    this.onLongPress,
  });

  final int index;
  final SagaListEntry entry;
  final SearchProvider provider;
  final bool isExpanded;
  final bool isEditMode;
  final Set<String> selectedItems;
  final bool isManualSort;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleSelectEntry;
  final ValueChanged<MediaItem> onToggleSelectItem;
  final ValueChanged<MediaItem> onTapMovie;
  final VoidCallback? onLongPress;

  String _itemKey(MediaItem item) => '${item.id}:${item.mediaType.name}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    final totalCount = entry.movies.length;
    final seenCount = entry.movies
        .where((m) => provider.getSeenCount(m) > 0)
        .length;
    final representative = entry.representativeMovie(
      (m) => provider.getSeenCount(m) > 0,
    );

    final selectedInSaga = entry.movies
        .where((m) => selectedItems.contains(_itemKey(m)))
        .length;
    final allSelected = selectedInSaga == totalCount;
    final someSelected = selectedInSaga > 0 && !allSelected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isEditMode ? onToggleSelectEntry : onToggleExpand,
          onLongPress: onLongPress,
          child: Container(
            color: allSelected
                ? colors.primary.withValues(alpha: 0.1)
                : (isExpanded ? colors.surface2.withValues(alpha: 0.5) : null),
            child: ListTile(
              leading: SizedBox(
                width: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 3,
                      top: -2,
                      right: -3,
                      bottom: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface2,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colors.text2.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                    MediaPosterCard(
                      compact: true,
                      data: mediaItemPosterData(
                        context,
                        representative,
                        seenCount: provider.getSeenCount(representative),
                        imageSize: 'w92',
                      ),
                    ),
                  ],
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.collections_bookmark_outlined,
                    size: 12,
                    color: colors.text2,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${l10n.listsSagaMovieCount(totalCount)} · ${l10n.listsSagaSeenProgress(seenCount, totalCount)}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              trailing: isEditMode
                  ? AppTapTarget(
                      onTap: onToggleSelectEntry,
                      child: Checkbox(
                        tristate: true,
                        value: allSelected
                            ? true
                            : (someSelected ? null : false),
                        onChanged: (_) => onToggleSelectEntry(),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          semanticLabel: isExpanded
                              ? l10n.listsSagaCollapseTooltip
                              : l10n.listsSagaExpandTooltip,
                        ),
                        if (isManualSort && !isExpanded)
                          ReorderableDragStartListener(
                            index: index,
                            child: const SizedBox(
                              width: kMinTapTarget,
                              height: kMinTapTarget,
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
        if (isExpanded)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colors.primary.withValues(alpha: 0.35),
                  width: 3,
                ),
              ),
              color: colors.surface2.withValues(alpha: 0.25),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < entry.movies.length; i++)
                    ListMediaTile(
                      key: ValueKey(
                        '${entry.key}_${entry.movies[i].id}_${entry.movies[i].mediaType.name}',
                      ),
                      index: i,
                      item: entry.movies[i],
                      provider: provider,
                      isEditMode: isEditMode,
                      isSelected: selectedItems.contains(
                        _itemKey(entry.movies[i]),
                      ),
                      isManualSort: false,
                      onTap: () {
                        if (isEditMode) {
                          onToggleSelectItem(entry.movies[i]);
                        } else {
                          onTapMovie(entry.movies[i]);
                        }
                      },
                      onLongPress: onLongPress,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
