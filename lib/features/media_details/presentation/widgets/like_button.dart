import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class LikeButton extends StatelessWidget {
  final MediaItem item;

  const LikeButton({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final isLiked = provider.isLiked(item);

    return IconButton(
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? Colors.red : null,
      ),
      onPressed: () => provider.toggleLike(item),
      tooltip: isLiked ? 'Unlike' : 'Like',
    );
  }
}
