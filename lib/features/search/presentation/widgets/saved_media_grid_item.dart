import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/media_item_poster.dart';

/// Poster of a saved [item] in a list grid, with the selection state of the
/// edit mode.
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
    return MediaPosterCard(
      data: mediaItemPosterData(
        context,
        item,
        seenCount: provider.getSeenCount(item),
        liked: provider.isLiked(item),
      ),
      selected: isEditMode ? isSelected : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
