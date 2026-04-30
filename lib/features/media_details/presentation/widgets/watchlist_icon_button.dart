import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/core/theme/app_palette.dart';

class WatchlistIconButton extends StatelessWidget {
  final MediaItem item;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  const WatchlistIconButton({
    super.key,
    required this.item,
    this.iconSize,
    this.padding,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final isInWatchlist = provider.isItemInList(item, 'watchlist');
    final colors = context.appColors;

    return IconButton(
      iconSize: iconSize,
      padding: padding ?? const EdgeInsets.all(8.0),
      constraints: constraints,
      icon: Icon(
        isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
        color: isInWatchlist ? colors.onWatchlist : null,
      ),
      onPressed: () => provider.toggleInList(item, 'watchlist'),
      tooltip: isInWatchlist ? 'Remove from watchlist' : 'Add to watchlist',
    );
  }
}
