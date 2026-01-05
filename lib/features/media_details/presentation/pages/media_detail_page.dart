import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/media_list_manager.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

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
  MediaDetails? _mediaDetails;
  bool _isLoading = true;
  int? _expandedSeason;
  final Map<int, List<dynamic>> _episodesBySeason = {};
  final Map<int, bool> _loadingSeasons = {};
  List<SeenItem> _seenStatus = [];
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to start fetching data.
    // This avoids triggering synchronous state changes (like offline status updates)
    // in parent widgets (like MainPage) during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchMediaDetails();
        _fetchSeenStatus();
      }
    });
  }

  /// Fetches the details from the repository via the provider.
  Future<void> _fetchMediaDetails() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    try {
      final provider = context.read<SearchProvider>();
      final details = await provider.getMediaDetails(
        widget.item.id,
        widget.item.mediaType,
      );
      if (mounted) {
        setState(() {
          _mediaDetails = details;
          _isLoading = false;
          _isOffline = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOffline = e.toString().contains('SocketException') || 
                       e.toString().contains('Network error') ||
                       e.toString().contains('connectionError');
        });
      }
    }
  }

  Future<void> _fetchSeenStatus() async {
    final provider = context.read<SearchProvider>();
    final status = await provider.loadSeenStatusForItem(widget.item.id, widget.item.mediaType);
    if (mounted) {
      setState(() {
        _seenStatus = status;
      });
    }
  }

  Future<void> _fetchSeasonDetails(int seasonNumber) async {
    if (_episodesBySeason.containsKey(seasonNumber)) {
       setState(() {
        _expandedSeason = _expandedSeason == seasonNumber ? null : seasonNumber;
      });
      return;
    }

    setState(() {
      _loadingSeasons[seasonNumber] = true;
      _expandedSeason = seasonNumber;
    });

    try {
      final provider = context.read<SearchProvider>();
      final data = await provider.getSeasonDetails(widget.item.id, seasonNumber);
      if (mounted) {
        setState(() {
          _episodesBySeason[seasonNumber] = data['episodes'] ?? [];
          _loadingSeasons[seasonNumber] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSeasons[seasonNumber] = false;
          _expandedSeason = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot load season details while offline.')),
        );
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
        actions: [
          if (itemToDisplay.mediaType == MediaType.movie)
            SeenManager(
              tmdbId: itemToDisplay.id,
              type: itemToDisplay.mediaType,
              title: itemToDisplay.title,
              posterPath: itemToDisplay.posterPath,
              onSeenChanged: _fetchSeenStatus,
            ),
        ],
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
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 250,
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                          ),
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
                            if (itemToDisplay.voteAverage != null && !_isOffline)
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
                        if (itemToDisplay.mediaType == MediaType.tv && itemToDisplay.numberOfEpisodes != null) ...[
                          LinearProgressIndicator(
                            value: itemToDisplay.numberOfEpisodes! > 0 
                                ? _seenStatus.length / itemToDisplay.numberOfEpisodes! 
                                : 0,
                            backgroundColor: Colors.grey[300],
                            color: Colors.green,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Progress: ${_seenStatus.length} / ${itemToDisplay.numberOfEpisodes} episodes seen',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        if (_isOffline)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            width: double.infinity,
                            child: Column(
                              children: [
                                const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
                                const SizedBox(height: 8),
                                Text(
                                  'Offline Mode',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Text(
                                  'Detailed information is unavailable without internet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchMediaDetails,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                ),
                              ],
                            ),
                          )
                        else ...[
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
                        ],
                        
                        if (itemToDisplay.mediaType == MediaType.tv && itemToDisplay.seasons != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Seasons',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itemToDisplay.seasons!.length,
                            itemBuilder: (context, index) {
                              final season = itemToDisplay.seasons![index];
                              final seasonNumber = season.seasonNumber;
                              final isExpanded = _expandedSeason == seasonNumber;
                              final isLoading = _loadingSeasons[seasonNumber] ?? false;

                              final episodesSeenInSeason = _seenStatus.where((s) => s.seasonNumber == seasonNumber).length;
                              final isComplete = episodesSeenInSeason == season.episodeCount && season.episodeCount > 0;

                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(season.name ?? 'Season $seasonNumber'),
                                    subtitle: Text(
                                      '$episodesSeenInSeason / ${season.episodeCount} episodes seen',
                                      style: TextStyle(
                                        color: isComplete ? Colors.green : null,
                                        fontWeight: isComplete ? FontWeight.bold : null,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isComplete) const Icon(Icons.check_circle, color: Colors.green),
                                        isLoading 
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                          : Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                      ],
                                    ),
                                    onTap: () => _fetchSeasonDetails(seasonNumber),
                                  ),
                                  if (isExpanded && _episodesBySeason.containsKey(seasonNumber))
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16.0),
                                      child: Column(
                                        children: _episodesBySeason[seasonNumber]!.map<Widget>((episode) {
                                          return ListTile(
                                            title: Text('E${episode['episode_number']}: ${episode['name']}'),
                                            subtitle: Text(episode['air_date'] ?? ''),
                                            trailing: SeenManager(
                                              tmdbId: itemToDisplay.id,
                                              type: MediaType.tv,
                                              title: itemToDisplay.title,
                                              posterPath: itemToDisplay.posterPath,
                                              seasonNumber: seasonNumber,
                                              episodeNumber: episode['episode_number'],
                                              onSeenChanged: _fetchSeenStatus,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],

                        if (_mediaDetails != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Cast',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
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
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            member.character,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodySmall,
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
                        MediaListManager(
                          itemId: itemToDisplay.id,
                          mediaType: itemToDisplay.mediaType,
                          title: itemToDisplay.title,
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
