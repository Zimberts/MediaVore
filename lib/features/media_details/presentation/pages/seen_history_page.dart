import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

class SeenHistoryPage extends StatefulWidget {
  const SeenHistoryPage({super.key});

  @override
  State<SeenHistoryPage> createState() => _SeenHistoryPageState();
}

class _SeenHistoryPageState extends State<SeenHistoryPage> {
  late final MediaRepository _mediaRepository;
  List<SeenItem> _seenItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    _loadSeenItems();
  }

  Future<void> _loadSeenItems() async {
    setState(() => _isLoading = true);
    final items = await _mediaRepository.getSeenItems();
    if (mounted) {
      setState(() {
        _seenItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          : _seenItems.isEmpty
              ? const Center(child: Text('No items seen yet.'))
              : ListView.builder(
                  itemCount: _seenItems.length,
                  itemBuilder: (context, index) {
                    final item = _seenItems[index];
                    final dateStr = DateFormat.yMMMd().format(item.seenDate);
                    
                    String subtitle = dateStr;
                    if (item.type == MediaType.tv && item.seasonNumber != null) {
                      subtitle = 'S${item.seasonNumber} E${item.episodeNumber} • $dateStr';
                    }

                    final isTv = item.type == MediaType.tv;

                    return ListTile(
                      leading: item.posterPath != null && !Platform.environment.containsKey('FLUTTER_TEST')
                          ? CachedNetworkImage(
                              imageUrl: 'https://image.tmdb.org/t/p/w92${item.posterPath}',
                              width: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                width: 50,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => SizedBox(
                                width: 50,
                                child: Icon(isTv ? Icons.tv : Icons.movie),
                              ),
                            )
                          : SizedBox(
                              width: 50,
                              child: Icon(isTv ? Icons.tv : Icons.movie),
                            ),
                      title: Text(item.title),
                      subtitle: Text(subtitle),
                      onTap: () {
                        // Navigate to detail page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MediaDetailPage(
                              item: MediaItem(
                                id: item.tmdbId,
                                title: item.title,
                                overview: '',
                                releaseDate: '',
                                mediaType: item.type,
                                posterPath: item.posterPath,
                              ),
                            ),
                          ),
                        ).then((_) => _loadSeenItems());
                      },
                    );
                  },
                ),
    );
  }
}
