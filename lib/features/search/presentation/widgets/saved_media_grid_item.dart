import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/poster_badge_only.dart';
import 'package:mediavore/features/search/presentation/widgets/poster_with_badge.dart';

class MediaGridItem extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final bool isSelected;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MediaGridItem({
    super.key,
    required this.item,
    required this.provider,
    required this.isSelected,
    required this.isEditMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isTv = item.mediaType == MediaType.tv;

    String lengthText = '';
    if (isTv) {
      lengthText = '${item.numberOfSeasons ?? "?"} S';
    } else if (item.runtime != null) {
      lengthText = '${item.runtime}m';
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PosterWithBadge(
                  item: item,
                  provider: provider,
                  width: double.infinity,
                  height: double.infinity,
                  showBadge: false,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      left: 6,
                      top: 24,
                      bottom: 6,
                      right: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (provider.isLiked(item))
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Icon(
                                  Icons.favorite,
                                  size: 10,
                                  color: colors.likeHeart,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.releaseDate.isNotEmpty == true && item.releaseDate.length >= 4 ? item.releaseDate.substring(0, 4) : ""} • $lengthText',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.voteAverage != null && item.voteAverage! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          item.voteAverage!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                item.mediaType == MediaType.tv ? Icons.tv : Icons.movie,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.logicFlow, width: 3),
                ),
              ),
            ),
          PosterBadgeOnly(item: item, provider: provider),
          if (isEditMode)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(1),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected ? colors.logicFlow : colors.placeholder,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
