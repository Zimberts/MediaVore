import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

enum SeenSort { dateDesc, dateAsc, nameAsc, nameDesc }
enum SeenViewMode { history, library }

class SeenHistoryPage extends StatefulWidget {
  const SeenHistoryPage({super.key});

  @override
  State<SeenHistoryPage> createState() => SeenHistoryPageState();
}

class SeenHistoryPageState extends State<SeenHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SeenSort _currentSort = SeenSort.dateDesc;
  SeenViewMode _viewMode = SeenViewMode.history;
  MediaType? _filterType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  List<SeenItem> _getFilteredAndSortedItems(List<SeenItem> items, SearchProvider provider) {
    List<SeenItem> processed = List.from(items);

    if (_viewMode == SeenViewMode.library) {
      // Group by ID and Type
      final Map<String, SeenItem> uniqueItems = {};
      for (final item in processed) {
        final key = '${item.tmdbId}:${item.type.name}';
        if (!uniqueItems.containsKey(key)) {
          uniqueItems[key] = item;
        } else {
          // Keep the most recent one
          if (item.seenDate.isAfter(uniqueItems[key]!.seenDate)) {
            uniqueItems[key] = item;
          }
        }
      }
      processed = uniqueItems.values.toList();
    }

    List<SeenItem> filtered = processed.where((item) {
      final matchesQuery = item.title.toLowerCase().contains(_searchQuery);
      final matchesType = _filterType == null || item.type == _filterType;
      return matchesQuery && matchesType;
    }).toList();

    switch (_currentSort) {
      case SeenSort.dateDesc:
        filtered.sort((a, b) => b.seenDate.compareTo(a.seenDate));
        break;
      case SeenSort.dateAsc:
        filtered.sort((a, b) => a.seenDate.compareTo(b.seenDate));
        break;
      case SeenSort.nameAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SeenSort.nameDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    return filtered;
  }

  List<dynamic> _groupItems(List<SeenItem> items) {
    final List<dynamic> grouped = [];
    if (items.isNotEmpty) {
      if (_currentSort == SeenSort.dateDesc || _currentSort == SeenSort.dateAsc) {
        DateTime? lastDate;
        for (final item in items) {
          final date = DateTime(item.seenDate.year, item.seenDate.month, item.seenDate.day);
          if (lastDate == null || date != lastDate) {
            grouped.add(date);
            lastDate = date;
          }
          grouped.add(item);
        }
      } else {
        return items;
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

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Filter & Sort', style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              title: const Text('View Mode'),
              trailing: DropdownButton<SeenViewMode>(
                value: _viewMode,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _viewMode = val);
                    setModalState(() {});
                  }
                },
                items: const [
                  DropdownMenuItem(value: SeenViewMode.history, child: Text('History (All episodes)')),
                  DropdownMenuItem(value: SeenViewMode.library, child: Text('Library (Unique titles)')),
                ],
              ),
            ),
            ListTile(
              title: const Text('Sort by'),
              trailing: DropdownButton<SeenSort>(
                value: _currentSort,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _currentSort = val);
                    setModalState(() {});
                  }
                },
                items: const [
                  DropdownMenuItem(value: SeenSort.dateDesc, child: Text('Date (Newest)')),
                  DropdownMenuItem(value: SeenSort.dateAsc, child: Text('Date (Oldest)')),
                  DropdownMenuItem(value: SeenSort.nameAsc, child: Text('Name (A-Z)')),
                  DropdownMenuItem(value: SeenSort.nameDesc, child: Text('Name (Z-A)')),
                ],
              ),
            ),
            ListTile(
              title: const Text('Media Type'),
              trailing: DropdownButton<MediaType?>(
                value: _filterType,
                onChanged: (val) {
                  setState(() => _filterType = val);
                  setModalState(() {});
                },
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: MediaType.movie, child: Text('Movies')),
                  DropdownMenuItem(value: MediaType.tv, child: Text('TV Shows')),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final allSeenItems = provider.seenItems;
    final filteredItems = _getFilteredAndSortedItems(allSeenItems, provider);
    final groupedItems = _groupItems(filteredItems);

    final settings = context.watch<SettingsProvider>();
    final palette = Theme.of(context).brightness == Brightness.dark
        ? settings.darkPalette
        : settings.lightPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seen History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: _showFilterOptions,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MediaStatsPage()),
              );
            },
            tooltip: 'Statistics',
          ),
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
      body: allSeenItems.isEmpty
          ? const Center(child: Text('No items seen yet.'))
          : filteredItems.isEmpty
              ? const Center(child: Text('No matches found.'))
              : ListView.builder(
                  controller: _scrollController,
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
                    if (_viewMode == SeenViewMode.history && isTv && seenItem.seasonNumber != null) {
                      subtitle = 'S${seenItem.seasonNumber} E${seenItem.episodeNumber}';
                    } else if (_viewMode == SeenViewMode.library && isTv) {
                      final count = provider.getSeenCount(MediaItem(
                        id: seenItem.tmdbId, 
                        title: seenItem.title, 
                        overview: '', 
                        releaseDate: '', 
                        mediaType: seenItem.type,
                      ));
                      subtitle = '$count episodes seen';
                    }

                    if (_currentSort == SeenSort.nameAsc || _currentSort == SeenSort.nameDesc) {
                      subtitle += (subtitle.isNotEmpty ? ' • ' : '') + DateFormat.yMd().format(seenItem.seenDate);
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
                      confirmDismiss: (direction) {
                        if (_viewMode == SeenViewMode.library) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cannot delete from Library mode. Switch to History to remove entries.')),
                          );
                          return Future.value(false);
                        }
                        return _confirmDeletion(context);
                      },
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
                              Padding(
                                padding: EdgeInsets.only(left: 4.0),
                                child: Icon(Icons.favorite, size: 16, color: palette.likeHeart),
                              ),
                          ],
                        ),
                        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                        onTap: () {
                          MediaDetailPage.show(
                            context,
                            MediaItem(
                              id: seenItem.tmdbId,
                              title: seenItem.title,
                              overview: '',
                              releaseDate: '',
                              mediaType: seenItem.type,
                              posterPath: seenItem.posterPath,
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
