import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
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
  Set<int>? _lastWatchlistIds;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadLists();
      loadSavedMedia();
    });
  }

  Future<void> loadSavedMedia() async {
    if (!mounted) return;
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
    final entries = await _mediaRepository.getListEntries(_selectedList);
    final items = <MediaItem>[];
    for (final entry in entries) {
      try {
        final parts = entry.split(':');
        final id = int.parse(parts[0]);
        final type = parts.length > 1 
            ? MediaType.values.firstWhere((e) => e.name == parts[1], orElse: () => MediaType.movie)
            : MediaType.movie;
            
        final details = await _mediaRepository.getMediaDetails(id, type: type);
        items.add(details.item);
      } catch (e) {
        // Skip if failed to load
      }
    }
    return items;
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
                    leading: item.posterPath != null
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w92${item.posterPath}',
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : Icon(isTv ? Icons.tv : Icons.movie),
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
                    subtitle: Text(
                      item.releaseDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Switch List', style: Theme.of(context).textTheme.titleLarge),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.listNames.length,
                  itemBuilder: (context, index) {
                    final name = provider.listNames[index];
                    final previews = provider.getPreviewsForList(name);
                    
                    return ListTile(
                      leading: _buildListPreviewIcon(previews),
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

  Widget _buildListPreviewIcon(List<MediaItemPreview> previews) {
    if (previews.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.movie_outlined, size: 20),
      );
    }

    if (previews.length == 1) {
       return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          'https://image.tmdb.org/t/p/w92${previews[0].posterPath}',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie),
        ),
      );
    }

    // Grid of 4 posters (2x2)
    return SizedBox(
      width: 40,
      height: 40,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index >= previews.length || previews[index].posterPath == null) {
            return Container(color: Colors.grey[200]);
          }
          return Image.network(
            'https://image.tmdb.org/t/p/w92${previews[index].posterPath}',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
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
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'List name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newName = controller.text;
                await provider.createList(newName);
                setState(() {
                  _selectedList = newName;
                });
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
              setState(() {
                _selectedList = 'watchlist';
              });
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
