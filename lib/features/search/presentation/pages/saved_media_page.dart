import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

class SavedMediaPage extends StatefulWidget {
  const SavedMediaPage({super.key});

  @override
  State<SavedMediaPage> createState() => _SavedMediaPageState();
}

class _SavedMediaPageState extends State<SavedMediaPage> {
  late final MediaRepository _mediaRepository;
  Future<List<MediaItem>>? _savedMediaFuture;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    _loadSavedMedia();
  }

  Future<void> _loadSavedMedia() async {
    setState(() {
      _savedMediaFuture = _fetchSavedMedia();
    });
  }

  Future<List<MediaItem>> _fetchSavedMedia() async {
    final entries = await _mediaRepository.getWatchlistEntries();
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

  Future<void> _toggleWatchlist(MediaItem item) async {
    try {
      await _mediaRepository.removeFromWatchlist(item.id, item.mediaType);
      _loadSavedMedia(); // Reload the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove from watchlist: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
      ),
      body: FutureBuilder<List<MediaItem>>(
        future: _savedMediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items saved yet.'));
          } else {
            final savedItems = snapshot.data!;
            return ListView.builder(
              itemCount: savedItems.length,
              itemBuilder: (context, index) {
                final item = savedItems[index];
                final isTv = item.mediaType == MediaType.tv;
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaDetailPage(item: item),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: item.posterPath != null
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w92${item.posterPath}',
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(isTv ? Icons.tv : Icons.movie),
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
                      onPressed: () => _toggleWatchlist(item),
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
}
