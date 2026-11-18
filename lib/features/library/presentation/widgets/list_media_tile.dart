import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/media_item_poster.dart';

/// Detailed list tile for a saved [item] in list mode.
class ListMediaTile extends StatelessWidget {
  const ListMediaTile({
    super.key,
    required this.index,
    required this.item,
    required this.provider,
    required this.isEditMode,
    required this.isSelected,
    required this.isManualSort,
    required this.onTap,
    this.onLongPress,
  });

  final int index;
  final MediaItem item;
  final SearchProvider provider;
  final bool isEditMode;
  final bool isSelected;
  final bool isManualSort;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isTv = item.mediaType == MediaType.tv;
    final isLiked = provider.isLiked(item);
    final colors = context.appColors;

    String lengthText = '';
    if (isTv) {
      lengthText = (item.numberOfSeasons == null
          ? '?'
          : context.l10n.mediaSeasonCount(item.numberOfSeasons!));
    } else if (item.runtime != null) {
      lengthText = context.l10n.mediaRuntimeMinutes(item.runtime!);
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected ? colors.primary.withValues(alpha: 0.1) : null,
        child: ListTile(
          leading: SizedBox(
            width: 48,
            child: MediaPosterCard(
              compact: true,
              data: mediaItemPosterData(
                context,
                item,
                seenCount: provider.getSeenCount(item),
                imageSize: 'w92',
              ),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLiked)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Icon(
                    Icons.favorite,
                    size: 16,
                    color: colors.likeHeart,
                  ),
                ),
            ],
          ),
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isTv ? Icons.tv : Icons.movie,
                size: 12,
                color: colors.text2,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${item.releaseDate.isNotEmpty == true && item.releaseDate.length >= 4 ? item.releaseDate.substring(0, 4) : "?"} • $lengthText',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (item.voteAverage != null && item.voteAverage! > 0) ...[
                const Text(' • '),
                Icon(Icons.star, color: colors.ratingStar, size: 12),
                const SizedBox(width: 2),
                Text(item.voteAverage!.toStringAsFixed(1)),
              ],
            ],
          ),
          trailing: isEditMode
              ? AppTapTarget(
                  onTap: onTap,
                  child: Checkbox(value: isSelected, onChanged: (_) => onTap()),
                )
              : isManualSort
              ? ReorderableDragStartListener(
                  index: index,
                  child: const SizedBox(
                    width: kMinTapTarget,
                    height: kMinTapTarget,
                    child: Icon(Icons.drag_handle),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
