import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/poster_with_badge.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';

class MediaListTile extends StatelessWidget {
  final MediaItem item;
  final int index;
  final SearchProvider provider;
  final SettingsProvider settings;
  final bool isEditMode;
  final bool isSelected;
  final bool isManualSort;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MediaListTile({
    super.key,
    required this.index,
    required this.item,
    required this.provider,
    required this.settings,
    required this.isEditMode,
    required this.isSelected,
    required this.isManualSort,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isTv = item.mediaType == MediaType.tv;
    final isLiked = provider.isLiked(item);

    String lengthText = '';
    if (isTv) {
      lengthText = '${item.numberOfSeasons ?? "?"} seasons';
    } else if (item.runtime != null) {
      lengthText = '${item.runtime} min';
    }

    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected ? colors.logicFlow.withValues(alpha: 0.1) : null,
        child: ListTile(
          leading: PosterWithBadge(item: item, provider: provider),
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
              Icon(isTv ? Icons.tv : Icons.movie, size: 12, color: Colors.grey),
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
                const Icon(Icons.star, color: Colors.amber, size: 12),
                const SizedBox(width: 2),
                Text(item.voteAverage!.toStringAsFixed(1)),
              ],
            ],
          ),
          trailing: isEditMode
              ? Checkbox(value: isSelected, onChanged: (_) => onTap())
              : isManualSort
              ? ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                )
              : null,
        ),
      ),
    );
  }
}
