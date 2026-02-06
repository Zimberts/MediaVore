import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';

class MediaListManager extends StatelessWidget {
  final MediaItem item;

  const MediaListManager({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final settings = context.watch<SettingsProvider>();
    final palette = Theme.of(context).brightness == Brightness.dark
        ? settings.darkPalette
        : settings.lightPalette;

    final isInWatchlist = provider.isItemInList(item, 'watchlist');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isInWatchlist ? palette.onWatchlist : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: palette.onWatchlist,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10), // Slightly smaller to stay inside border
                onTap: () => provider.toggleInList(item, 'watchlist'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isInWatchlist ? Icons.check : Icons.add,
                        color: isInWatchlist ? palette.primaryBg : palette.onWatchlist,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isInWatchlist ? 'On Watchlist' : 'Add to Watchlist',
                        style: TextStyle(
                          color: isInWatchlist ? palette.primaryBg : palette.onWatchlist,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Divider(),
        ...provider.listNames.where((name) => name != 'watchlist').map((name) {
          final isInList = provider.isItemInList(item, name);
          return ListTile(
            title: Text(name),
            leading: Icon(
              isInList ? Icons.check : Icons.add,
              color: isInList ? palette.onWatchlist : null,
            ),
            onTap: () => provider.toggleInList(item, name),
          );
        }),
      ],
    );
  }
}
