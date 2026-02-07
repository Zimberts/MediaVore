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

    final otherLists = provider.listNames
        .where((name) => name != 'watchlist')
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (otherLists.isNotEmpty) ...[
          const Divider(),
          ...otherLists.map((name) {
            final isInList = provider.isItemInList(item, name);
            return ListTile(
              title: Text(name),
              leading: Icon(
                isInList ? Icons.check : Icons.add,
                color: isInList ? palette.onWatchlist : null,
              ),
              onTap: () => provider.toggleInList(item, name),
            );
          }).toList(),
        ],
      ],
    );
  }
}
