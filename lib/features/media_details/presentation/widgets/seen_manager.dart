import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class SeenManager extends StatelessWidget {
  final MediaItem item;
  final int? seasonNumber;
  final int? episodeNumber;
  final bool compact;

  const SeenManager({
    super.key,
    required this.item,
    this.seasonNumber,
    this.episodeNumber,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final colors = context.appColors;

    // Determine seen status
    bool isSeen;
    int? count;

    if (seasonNumber != null && episodeNumber != null) {
      final history = provider.seenItems.where((s) =>
        s.tmdbId == item.id &&
        s.type == item.mediaType &&
        s.seasonNumber == seasonNumber &&
        s.episodeNumber == episodeNumber
      ).toList();
      isSeen = history.isNotEmpty;
      count = history.length;
    } else {
      count = provider.getSeenCount(item);
      isSeen = count > 0;
    }

    final isTv = item.mediaType == MediaType.tv;
    final bool isSpecificEpisode = seasonNumber != null && episodeNumber != null;

    if (isSpecificEpisode || compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSeen && !isSpecificEpisode)
            IconButton(
              icon: Icon(Icons.history, color: colors.logicFlow),
              onPressed: () => _showSeenHistory(context, provider),
              tooltip: 'View History',
            ),
          IconButton(
            icon: Icon(
              isSeen ? (isSpecificEpisode ? Icons.check_circle : Icons.add_circle) : Icons.check_circle_outline,
              color: isSeen ? colors.success : colors.comments,
            ),
            tooltip: isSeen ? (isSpecificEpisode ? 'Seen' : 'Add viewing') : 'Mark as seen',
            onPressed: () {
              if (isSpecificEpisode && isSeen) {
                _showSeenHistory(context, provider);
              } else if (isTv && !isSpecificEpisode) {
                _showAddMultipleDialog(context, provider);
              } else {
                provider.markAsSeen(SeenItem(
                  tmdbId: item.id,
                  type: item.mediaType,
                  title: item.title,
                  posterPath: item.posterPath,
                  seasonNumber: seasonNumber,
                  episodeNumber: episodeNumber,
                  seenDate: DateTime.now(),
                ));
              }
            },
          ),
        ],
      );
    }

    return ListTile(
      title: Text(isTv ? 'Episodes Seen' : 'Seen'),
      subtitle: Text(isTv ? '$count episodes' : (isSeen ? 'Yes' : 'No')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSeen)
            IconButton(
              icon: Icon(Icons.history, color: colors.logicFlow),
              onPressed: () => _showSeenHistory(context, provider),
            ),
          IconButton(
            icon: Icon(
              isSeen ? Icons.add_circle : Icons.check_circle_outline,
              color: isSeen ? colors.success : colors.comments,
            ),
            onPressed: () => isTv
              ? _showAddMultipleDialog(context, provider)
              : provider.markAsSeen(SeenItem(
                  tmdbId: item.id,
                  type: item.mediaType,
                  title: item.title,
                  posterPath: item.posterPath,
                  seenDate: DateTime.now(),
                )),
          ),
        ],
      ),
      onLongPress: isSeen ? () => _confirmClear(context, provider) : null,
    );
  }

  void _showAddMultipleDialog(BuildContext context, SearchProvider provider) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Multiple Viewings'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Number of episodes'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final count = int.tryParse(controller.text) ?? 1;
              for (int i = 0; i < count; i++) {
                provider.markAsSeen(SeenItem(
                  tmdbId: item.id,
                  type: item.mediaType,
                  title: item.title,
                  posterPath: item.posterPath,
                  seenDate: DateTime.now(),
                ));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, SearchProvider provider) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: Text('Are you sure you want to clear all viewing history for "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.removeFromSeen(item.id, item.mediaType);
              Navigator.pop(context);
            },
            child: Text('Clear All', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  void _showSeenHistory(BuildContext context, SearchProvider provider) {
    final history = provider.seenItems.where((s) =>
      s.tmdbId == item.id &&
      s.type == item.mediaType &&
      s.seasonNumber == seasonNumber &&
      s.episodeNumber == episodeNumber
    ).toList();

    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Viewing History', style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No viewing history found for this item.'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final seenEntry = history[index];
                    return ListTile(
                      leading: Icon(Icons.event, color: colors.comments),
                      title: Text(DateFormat('MMM dd, yyyy - HH:mm').format(seenEntry.seenDate)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: colors.error),
                        onPressed: () {
                          provider.deleteSeenEntry(seenEntry.id!);
                          if (history.length <= 1) Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: colors.error),
                onPressed: () {
                  Navigator.pop(context);
                  _confirmClear(context, provider);
                },
                child: const Text('Remove All History'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
