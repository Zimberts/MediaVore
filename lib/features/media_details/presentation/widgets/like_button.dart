import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class LikeButton extends StatelessWidget {
  final MediaItem item;
  final double? iconSize;

  const LikeButton({super.key, required this.item, this.iconSize});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final isLiked = provider.isLiked(item);
    final colors = context.appColors;

    return IconButton(
      iconSize: iconSize,
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? colors.likeHeart : null,
      ),
      onPressed: () => provider.toggleLike(item),
      tooltip: isLiked ? 'Unlike' : 'Like',
    );
  }
}
