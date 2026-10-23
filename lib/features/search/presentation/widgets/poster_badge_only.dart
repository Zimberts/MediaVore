import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';

class PosterBadgeOnly extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;

  const PosterBadgeOnly({
    super.key,
    required this.item,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final seenCount = provider.getSeenCount(item);
    if (seenCount <= 0) return const SizedBox.shrink();

    final isTv = item.mediaType == MediaType.tv;
    bool isFinished = isTv && item.numberOfEpisodes != null
        ? seenCount >= item.numberOfEpisodes!
        : !isTv;

    final colors = context.appColors;

    return Positioned(
      right: -4,
      bottom: -4,
      child: Container(
        decoration: BoxDecoration(
          color: isFinished ? colors.badgeBgSeen : colors.badgeBg,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        padding: const EdgeInsets.all(2),
        child: Icon(
          isFinished ? Icons.done_all : Icons.check,
          size: 10,
          color: colors.badgeText,
        ),
      ),
    );
  }
}
