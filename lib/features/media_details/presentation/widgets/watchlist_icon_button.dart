import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class WatchlistIconButton extends StatelessWidget {
  final MediaItem item;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  /// Drawn over a poster: white icon on a dark disc instead of the theme
  /// colors.
  final bool onImage;

  const WatchlistIconButton({
    super.key,
    required this.item,
    this.iconSize,
    this.padding,
    this.constraints,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider?>();
    final searchProvider =
        libraryProvider == null ? context.watch<SearchProvider>() : null;
    final isInWatchlist = libraryProvider != null
        ? libraryProvider.isItemInList(item, 'watchlist')
        : searchProvider!.isItemInList(item, 'watchlist');
    final colors = context.appColors;

    return IconButton(
      iconSize: iconSize,
      padding: padding ?? const EdgeInsets.all(8.0),
      constraints: constraints,
      icon: onImage
          ? Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: MediaPosterCard.badgeBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                color: MediaPosterCard.onImage,
              ),
            )
          : Icon(
              isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
              color: isInWatchlist ? colors.onWatchlist : null,
            ),
      onPressed: () {
        if (libraryProvider != null) {
          libraryProvider.toggleInList(item, 'watchlist');
        } else {
          context.read<SearchProvider>().toggleInList(item, 'watchlist');
        }
      },
      tooltip: isInWatchlist
          ? context.l10n.watchlistRemove
          : context.l10n.watchlistAdd,
    );
  }
}
