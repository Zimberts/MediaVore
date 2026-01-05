import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:provider/provider.dart';

class SavedMediaPage extends StatefulWidget {
  const SavedMediaPage({super.key});

  @override
  State<SavedMediaPage> createState() => SavedMediaPageState();
}

class SavedMediaPageState extends State<SavedMediaPage> {
  late final MediaRepository _mediaRepository;
  String _selectedList = 'watchlist';
  Future<List<MediaItem>>? _savedMediaFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadLists();
      loadSavedMedia();
    });
  }

  Future<void> loadSavedMedia({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    if (forceRefresh) {
      // Temporarily clear the offline status to allow network attempts
      context.read<SearchProvider>().setOffline(false);
    }

    setState(() {
      _savedMediaFuture = _fetchSavedMedia();
    });
  }

  void resetToDefault() {
    if (_selectedList != 'watchlist') {
      setState(() {
        _selectedList = 'watchlist';
      });
      loadSavedMedia();
    }
  }

  Future<List<MediaItem>> _fetchSavedMedia() async {
    final provider = context.read<SearchProvider>();
    final entries = await _mediaRepository.getListEntries(_selectedList);
    final localItems = await _mediaRepository.getListPreviews(_selectedList, limit: 1000);

    // If we are already offline, skip network requests entirely for speed,
    // UNLESS we are explicitly trying to refresh (which clears the offline flag first).
    if (provider.isOffline) {
      return entries.map((entry) {
        final parts = entry.split(':');
        final id = int.parse(parts[0]);
        final typeStr = parts.length > 1 ? parts[1] : 'movie';
        final type = typeStr == 'tv' ? MediaType.tv : MediaType.movie;
        
        final local = localItems.firstWhere(
          (l) => l.id == id && l.type == type.name,
          orElse: () => MediaItemPreview(id: id, title: 'Unknown', type: typeStr),
        );
        
        return MediaItem(
          id: local.id,
          title: local.title,
          overview: '', 
          releaseDate: '', 
          mediaType: type,
          posterPath: local.posterPath,
        );
      }).toList();
    }

    final itemFutures = entries.map((entry) async {
      try {
        final parts = entry.split(':');
        final id = int.parse(parts[0]);
        final typeStr = parts.length > 1 ? parts[1] : 'movie';
        final type = typeStr == 'tv' ? MediaType.tv : MediaType.movie;
            
        try {
          final details = await provider.getMediaDetails(id, type);
          return details.item;
        } catch (e) {
          final local = localItems.firstWhere(
            (l) => l.id == id && l.type == typeStr,
            orElse: () => MediaItemPreview(id: id, title: 'Unknown', type: typeStr),
          );
          return MediaItem(
            id: local.id,
            title: local.title,
            overview: '', 
            releaseDate: '', 
            mediaType: type,
            posterPath: local.posterPath,
          );
        }
      } catch (e) {
        return const MediaItem(id: 0, title: 'Error', overview: '', releaseDate: '');
      }
    });
    
    final items = await Future.wait(itemFutures);
    
    if (mounted) {
      provider.loadAllSeenStatus();
    }
    
    return items.where((item) => item.id != 0).toList();
  }

  Future<void> _removeItem(MediaItem item) async {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    await provider.toggleInList(item, _selectedList);
    loadSavedMedia();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showListPicker(context, provider),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedList == 'watchlist' ? 'Watchlist' : _selectedList),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () async {
              setState(() => _isRefreshing = true);
              await loadSavedMedia(forceRefresh: true);
              if (mounted) setState(() => _isRefreshing = false);
            },
            tooltip: 'Refresh List',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showCreateListDialog(context, provider),
            tooltip: 'Create New List',
          ),
          if (_selectedList != 'watchlist')
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteListConfirm(context, provider),
              tooltip: 'Delete Current List',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MediaItem>>(
        future: _savedMediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _savedMediaFuture != null) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No items in this list.'),
                  if (_selectedList != 'watchlist') ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showDeleteListConfirm(context, provider),
                      child: const Text('Delete Empty List'),
                    ),
                  ],
                ],
              ),
            );
          } else {
            final savedItems = snapshot.data!;
            return ListView.builder(
              itemCount: savedItems.length,
              itemBuilder: (context, index) {
                final item = savedItems[index];
                final isTv = item.mediaType == MediaType.tv;
                final seenCount = provider.getSeenCount(item);
                final isSeen = seenCount > 0;
                
                bool isFinished = false;
                if (isSeen) {
                  if (isTv && item.numberOfEpisodes != null && item.numberOfEpisodes! > 0) {
                    isFinished = seenCount >= item.numberOfEpisodes!;
                  } else if (!isTv) {
                    isFinished = true;
                  }
                }

                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaDetailPage(item: item),
                      ),
                    );
                    if (mounted) {
                      loadSavedMedia();
                    }
                  },
                  child: ListTile(
                    leading: Stack(
                      children: [
                        item.posterPath != null
                            ? CachedNetworkImage(
                                imageUrl: 'https://image.tmdb.org/t/p/w92${item.posterPath}',
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
                            : Icon(isTv ? Icons.tv : Icons.movie, size: 50),
                        if (isSeen)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isFinished ? Colors.blue : Colors.green,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                isFinished ? Icons.done_all : Icons.check, 
                                size: 12, 
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(item.title)),
                        if (isTv)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Badge(label: Text('TV')),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.releaseDate.isNotEmpty)
                          Text(
                            item.releaseDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (isTv && isSeen)
                          Text(
                            isFinished 
                                ? 'Finished ($seenCount episodes)' 
                                : '$seenCount / ${item.numberOfEpisodes ?? "?"} episodes seen',
                            style: TextStyle(
                              color: isFinished ? Colors.blue : Colors.green, 
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (!isTv && isSeen)
                          const Text(
                            'Seen',
                            style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeItem(item),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showListPicker(BuildContext context, SearchProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(16.0), child: Text('Switch List', style: Theme.of(context).textTheme.titleLarge)),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.listNames.length,
                  itemBuilder: (context, index) {
                    final name = provider.listNames[index];
                    final previews = provider.getPreviewsForList(name);
                    
                    return ListTile(
                      leading: _buildListPreviewIcon(previews, provider),
                      title: Text(name == 'watchlist' ? 'Watchlist' : name),
                      subtitle: Text('${provider.getPreviewsForList(name).length} items'),
                      selected: name == _selectedList,
                      trailing: name == _selectedList ? const Icon(Icons.check) : null,
                      onTap: () {
                        setState(() {
                          _selectedList = name;
                        });
                        loadSavedMedia();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create New List'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateListDialog(context, provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListPreviewIcon(List<MediaItemPreview> previews, SearchProvider provider) {
    if (previews.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
        child: const Icon(Icons.movie_outlined, size: 20),
      );
    }
    if (previews.length == 1) {
       return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: 'https://image.tmdb.org/t/p/w92${previews[0].posterPath}',
          width: 40, height: 40, fit: BoxFit.cover,
          errorWidget: (context, url, error) {
            provider.notifyNetworkError();
            return const Icon(Icons.movie);
          },
        ),
      );
    }
    return SizedBox(
      width: 40, height: 40,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 1, mainAxisSpacing: 1),
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index >= previews.length || previews[index].posterPath == null) return Container(color: Colors.grey[200]);
          return CachedNetworkImage(
            imageUrl: 'https://image.tmdb.org/t/p/w92${previews[index].posterPath}',
            fit: BoxFit.cover, 
            errorWidget: (context, url, error) {
              provider.notifyNetworkError();
              return Container(color: Colors.grey);
            },
          );
        },
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, SearchProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New List'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'List name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newName = controller.text;
                await provider.createList(newName);
                setState(() { _selectedList = newName; });
                loadSavedMedia();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteListConfirm(BuildContext context, SearchProvider provider) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "$_selectedList"? This will also remove all items from this list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final toDelete = _selectedList;
              setState(() { _selectedList = 'watchlist'; });
              await provider.deleteList(toDelete);
              if (context.mounted) Navigator.pop(context);
              loadSavedMedia();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
