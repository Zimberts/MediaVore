import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watchlist_button.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// A page that displays the details of a specific media item.
class MediaDetailPage extends StatefulWidget {
  /// The media item to display.
  final MediaItem item;

  const MediaDetailPage({super.key, required this.item});

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _SearchIconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SearchIconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  late final MediaRepository _mediaRepository;
  MediaDetails? _mediaDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    _fetchMediaDetails();
  }

  /// Fetches the details from the repository.
  Future<void> _fetchMediaDetails() async {
    try {
      final mediaDetails = await _mediaRepository.getMediaDetails(
        widget.item.id,
        type: widget.item.mediaType,
      );
      if (mounted) {
        setState(() {
          _mediaDetails = mediaDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load details: $e')),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemToDisplay = _mediaDetails?.item ?? widget.item;
    
    final mediaQuery = MediaQuery.of(context);
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final bool isAndroidButtons = isAndroid && 
        (mediaQuery.systemGestureInsets.bottom < 8 || mediaQuery.padding.bottom > 30);

    final String directorLabel = itemToDisplay.mediaType == MediaType.tv ? 'Creator' : 'Director';

    return Scaffold(
      appBar: AppBar(
        title: Text(itemToDisplay.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  itemToDisplay.posterPath != null && !Platform.environment.containsKey('FLUTTER_TEST')
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w500${itemToDisplay.posterPath}',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 250,
                          color: Colors.grey,
                          child: const Center(
                            child: Icon(Icons.movie, size: 100),
                          ),
                        ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                itemToDisplay.title,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            if (itemToDisplay.voteAverage != null)
                               Badge(
                                label: Row(
                                  children: [
                                    const Icon(Icons.star, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(itemToDisplay.voteAverage!.toStringAsFixed(1)),
                                  ],
                                ),
                                backgroundColor: Colors.amber[800],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _SearchIconText(icon: Icons.calendar_today, text: itemToDisplay.releaseDate),
                            if (itemToDisplay.status != null)
                              _SearchIconText(icon: Icons.info_outline, text: itemToDisplay.status!),
                            if (itemToDisplay.mediaType == MediaType.movie && itemToDisplay.runtime != null)
                              _SearchIconText(icon: Icons.access_time, text: Formatters.formatRuntime(itemToDisplay.runtime)),
                            if (itemToDisplay.mediaType == MediaType.tv && itemToDisplay.numberOfSeasons != null)
                              _SearchIconText(icon: Icons.tv, text: '${itemToDisplay.numberOfSeasons} Seasons'),
                            if (itemToDisplay.mediaType == MediaType.tv && itemToDisplay.numberOfEpisodes != null)
                              _SearchIconText(icon: Icons.subscriptions, text: '${itemToDisplay.numberOfEpisodes} Episodes'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (itemToDisplay.genres != null && itemToDisplay.genres!.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children: itemToDisplay.genres!.map((genre) => Chip(
                              label: Text(genre, style: const TextStyle(fontSize: 12)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            )).toList(),
                          ),
                        const SizedBox(height: 8),
                        if (_mediaDetails?.director != null)
                          Text(
                            '$directorLabel: ${_mediaDetails!.director!.name}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Overview',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          itemToDisplay.overview,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_mediaDetails == null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load additional details.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Cast',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _mediaDetails!.cast.length,
                              itemBuilder: (context, index) {
                                final member = _mediaDetails!.cast[index];
                                return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ActorDetailPage(
                                            actorId: member.id,
                                            actorName: member.name,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 100,
                                      margin:
                                          const EdgeInsets.only(right: 12.0),
                                      child: Column(
                                        children: [
                                          member.profilePath != null && !Platform.environment.containsKey('FLUTTER_TEST')
                                              ? CircleAvatar(
                                                  radius: 40,
                                                  backgroundImage: NetworkImage(
                                                      'https://image.tmdb.org/t/p/w185${member.profilePath}'),
                                                )
                                              : const CircleAvatar(
                                                  radius: 40,
                                                  child: Icon(Icons.person),
                                                ),
                                          const SizedBox(height: 4),
                                          Text(
                                            member.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    )
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Center(
                          child: WatchlistButton(
                            mediaRepository: _mediaRepository,
                            itemId: itemToDisplay.id,
                            mediaType: itemToDisplay.mediaType,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAndroidButtons) const SizedBox(height: 80) else const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
