import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/poster_badge_only.dart';

class PosterWithBadge extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final double? width;
  final double? height;
  final bool showBadge;

  const PosterWithBadge({
    super.key,
    required this.item,
    required this.provider,
    this.width = 50,
    this.height,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final seenCount = provider.getSeenCount(item);
    final isSeen = seenCount > 0;
    final isTv = item.mediaType == MediaType.tv;
    final colors = context.appColors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.posterPath != null
              ? CachedNetworkImage(
                  imageUrl: 'https://image.tmdb.org/t/p/w342${item.posterPath}',
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    isTv ? Icons.tv : Icons.movie,
                    size: (width?.isFinite == true) ? width : 48,
                  ),
                )
              : Container(
                  width: width,
                  height: height,
                  color: colors.placeholder,
                  child: Icon(
                    isTv ? Icons.tv : Icons.movie,
                    size: (width?.isFinite == true) ? (width! / 2) : 24,
                  ),
                ),
        ),
        if (isSeen && showBadge)
          PosterBadgeOnly(item: item, provider: provider),
      ],
    );
  }
}

// Extract the badge into its own widget
