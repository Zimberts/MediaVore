import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:provider/provider.dart';

class SeenHistoryPage extends StatelessWidget {
  const SeenHistoryPage({super.key});

  List<dynamic> _groupItems(List<SeenItem> items) {
    final List<dynamic> grouped = [];
    if (items.isNotEmpty) {
      DateTime? lastDate;
      for (final item in items) {
        final date = DateTime(item.seenDate.year, item.seenDate.month, item.seenDate.day);
        if (lastDate == null || date != lastDate) {
          grouped.add(date);
          lastDate = date;
        }
        grouped.add(item);
      }
    }
    return grouped;
  }

  Future<bool?> _confirmDeletion(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove log?'),
        content: const Text('Are you sure you want to remove this viewing entry from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final seenItems = provider.seenItems;
    final groupedItems = _groupItems(seenItems);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seen History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadAllSeenStatus(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: seenItems.isEmpty
          ? const Center(child: Text('No items seen yet.'))
          : ListView.builder(
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final item = groupedItems[index];

                if (item is DateTime) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    child: Text(
                      DateFormat.yMMMMEEEEd().format(item),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final seenItem = item as SeenItem;
                final isTv = seenItem.type == MediaType.tv;
                final isLiked = provider.likedIds.contains('${seenItem.tmdbId}:${seenItem.type.name}');
                
                String subtitle = '';
                if (isTv && seenItem.seasonNumber != null) {
                  subtitle = 'S${seenItem.seasonNumber} E${seenItem.episodeNumber}';
                }

                return Dismissible(
                  key: Key('seen_${seenItem.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) => _confirmDeletion(context),
                  onDismissed: (direction) {
                    provider.deleteSeenEntry(seenItem.id!);
                  },
                  child: ListTile(
                    leading: seenItem.posterPath != null && !Platform.environment.containsKey('FLUTTER_TEST')
                        ? CachedNetworkImage(
                            imageUrl: 'https://image.tmdb.org/t/p/w92${seenItem.posterPath}',
                            width: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 50,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) {
                              provider.notifyNetworkError();
                              return SizedBox(
                                width: 50,
                                child: Icon(isTv ? Icons.tv : Icons.movie),
                              );
                            },
                          )
                        : SizedBox(
                            width: 50,
                            child: Icon(isTv ? Icons.tv : Icons.movie),
                          ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text(seenItem.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (isLiked)
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.favorite, size: 16, color: Colors.red),
                          ),
                      ],
                    ),
                    subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MediaDetailPage(
                            item: MediaItem(
                              id: seenItem.tmdbId,
                              title: seenItem.title,
                              overview: '',
                              releaseDate: '',
                              mediaType: seenItem.type,
                              posterPath: seenItem.posterPath,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
