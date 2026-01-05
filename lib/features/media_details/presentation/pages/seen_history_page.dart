import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class SeenHistoryPage extends StatefulWidget {
  const SeenHistoryPage({super.key});

  @override
  State<SeenHistoryPage> createState() => _SeenHistoryPageState();
}

class _SeenHistoryPageState extends State<SeenHistoryPage> {
  late final MediaRepository _mediaRepository;
  List<dynamic> _groupedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    _loadSeenItems();
  }

  Future<void> _loadSeenItems() async {
    final items = await _mediaRepository.getSeenItems();
    
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

    if (mounted) {
      setState(() {
        _groupedItems = grouped;
        _isLoading = false;
      });
    }
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

  void _deleteEntry(SeenItem seenItem) {
    // Immediately remove from the local list to satisfy Dismissible requirement
    setState(() {
      // Use indexWhere with id for more reliability than indexOf
      final index = _groupedItems.indexWhere((item) => item is SeenItem && item.id == seenItem.id);
      if (index != -1) {
        _groupedItems.removeAt(index);
        
        // Clean up date header if it's now empty
        // Check if previous was a date and next is also a date or end of list
        if (index > 0 && _groupedItems[index - 1] is DateTime) {
          bool isLastInDay = index >= _groupedItems.length || _groupedItems[index] is DateTime;
          if (isLastInDay) {
            _groupedItems.removeAt(index - 1);
          }
        }
      }
    });

    // Perform actual deletion in background
    context.read<SearchProvider>().deleteSeenEntry(seenItem.id!).then((_) {
      if (mounted) {
        _loadSeenItems(); // Refresh full state to ensure grouping is correct
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seen History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSeenItems,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedItems.isEmpty
              ? const Center(child: Text('No items seen yet.'))
              : ListView.builder(
                  itemCount: _groupedItems.length,
                  itemBuilder: (context, index) {
                    final item = _groupedItems[index];

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
                      onDismissed: (direction) => _deleteEntry(seenItem),
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
                        title: Text(seenItem.title),
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
                          ).then((_) => _loadSeenItems());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
