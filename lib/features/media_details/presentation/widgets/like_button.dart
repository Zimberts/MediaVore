import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class LikeButton extends StatelessWidget {
  final MediaItem item;
  final double? iconSize;

  const LikeButton({super.key, required this.item, this.iconSize});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider?>();
    final searchProvider = libraryProvider == null
        ? context.watch<SearchProvider>()
        : null;
    final isLiked = libraryProvider != null
        ? libraryProvider.isLiked(item)
        : searchProvider!.isLiked(item);
    final colors = context.appColors;

    return IconButton(
      iconSize: iconSize,
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? colors.likeHeart : null,
      ),
      onPressed: () {
        if (libraryProvider != null) {
          libraryProvider.toggleLike(item);
        } else {
          context.read<SearchProvider>().toggleLike(item);
        }
      },
      tooltip: isLiked ? context.l10n.likeUnlike : context.l10n.likeLike,
    );
  }
}
