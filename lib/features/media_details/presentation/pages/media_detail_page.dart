import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/media_list_manager.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/media_details/presentation/widgets/like_button.dart';
import 'package:mediavore/features/media_details/presentation/widgets/notify_button.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watch_next_button.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watchlist_icon_button.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaDetailPage extends StatefulWidget {
  final MediaItem item;
  final bool isSheet;
  final ScrollController? scrollController;

  const MediaDetailPage({
    super.key,
    required this.item,
    this.isSheet = false,
    this.scrollController,
  });

  static Future<void> show(BuildContext context, MediaItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: MediaDetailPage(
            item: item,
            isSheet: true,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

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
        Icon(icon, size: 16, color: context.appColors.comments),
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
    _fetchMediaDetails();
    _fetchSeenStatus();
  }

  Future<void> _fetchMediaDetails() async {
    if (!mounted) return;
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
          _isOffline =
              e.toString().contains('SocketException') ||
              e.toString().contains('Network error') ||
              e.toString().contains('connectionError');
        });
      }
    }
  }

  Future<void> _fetchSeenStatus() async {
    final provider = context.read<SearchProvider>();
    final status = await provider.loadSeenStatusForItem(
      widget.item.id,
      widget.item.mediaType,
    );
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
      final data = await provider.getSeasonDetails(
        widget.item.id,
        seasonNumber,
      );
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
          const SnackBar(
            content: Text('Cannot load season details while offline.'),
          ),
        );
      }
    }
  }

  Future<void> _exportHistory() async {
    final provider = context.read<SearchProvider>();
    final data = await provider.exportSeenData(
      tmdbId: widget.item.id,
      type: widget.item.mediaType,
    );

    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No history to export for this item.')),
        );
      }
      return;
    }

    final jsonString = jsonEncode(data);
    final fileName =
        'mediavore_${widget.item.title.replaceAll(' ', '_')}_history.json';

    if (mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: const Text('Save to device'),
                onTap: () async {
                  Navigator.pop(context);
                  await _saveFileToDevice(context, jsonString, fileName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share via System'),
                onTap: () async {
                  Navigator.pop(context);
                  final tempDir = await getTemporaryDirectory();
                  final tempFile = File('${tempDir.path}/$fileName');
                  await tempFile.writeAsString(jsonString);
                  await Share.shareXFiles([
                    XFile(tempFile.path, mimeType: 'application/json'),
                  ], text: 'Seen history for ${widget.item.title}');
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _saveFileToDevice(
    BuildContext context,
    String jsonString,
    String fileName,
  ) async {
    try {
      final bytes = utf8.encode(jsonString);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save History',
        fileName: fileName,
        initialDirectory: '/storage/emulated/0/Download/MediaVore',
        bytes: bytes,
      );

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  void _onGenreTapped(String genreName) {
    final genreId = GenreUtils.getGenreIdByName(genreName);
    if (genreId != null) {
      final provider = context.read<SearchProvider>();
      provider.clearFilters();
      provider.setFilters(genreIds: [genreId], type: widget.item.mediaType);
      provider.searchMedia('');
      provider.setSelectedTab(0); // Switch to Discover tab

      if (widget.isSheet) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemToDisplay = _mediaDetails?.item ?? widget.item;
    final colors = context.appColors;

    final String directorLabel = itemToDisplay.mediaType == MediaType.tv
        ? 'Creator'
        : 'Director';

    final int uniqueEpisodesSeenTotal = _seenStatus
        .where((s) => s.seasonNumber != null && s.episodeNumber != null)
        .map((s) => '${s.seasonNumber}:${s.episodeNumber}')
        .toSet()
        .length;

    return Scaffold(
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: widget.isSheet ? 300 : 400,
            pinned: true,
            leading: widget.isSheet
                ? IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(itemToDisplay.title),
            actions: [
              LikeButton(item: itemToDisplay),
              NotifyButton(item: itemToDisplay),
              WatchlistIconButton(item: itemToDisplay),
              if (itemToDisplay.mediaType == MediaType.movie)
                SeenManager(
                  key: ValueKey('seen_movie_${itemToDisplay.id}'),
                  item: itemToDisplay,
                  compact: true,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  itemToDisplay.posterPath != null &&
                      !Platform.environment.containsKey('FLUTTER_TEST')
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w500${itemToDisplay.posterPath}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: colors.placeholder,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: colors.comments,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: colors.placeholder,
                      child: Center(
                        child: Icon(
                          Icons.movie,
                          size: 100,
                          color: colors.comments,
                        ),
                      ),
                    ),
            ),
          ),
          if (widget.isSheet)
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
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
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: colors.badgeText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  itemToDisplay.voteAverage!.toStringAsFixed(1),
                                  style: TextStyle(color: colors.badgeText),
                                ),
                              ],
                            ),
                            backgroundColor: colors.ratingStar,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _buildWatchProviders(),
                    const SizedBox(height: 8),

                    if (itemToDisplay.mediaType == MediaType.tv &&
                        itemToDisplay.numberOfEpisodes != null) ...[
                      LinearProgressIndicator(
                        value: itemToDisplay.numberOfEpisodes! > 0
                            ? uniqueEpisodesSeenTotal /
                                  itemToDisplay.numberOfEpisodes!
                            : 0,
                        backgroundColor: colors.placeholder,
                        color: colors.onWatchlist,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progress: $uniqueEpisodesSeenTotal / ${itemToDisplay.numberOfEpisodes} episodes seen',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onWatchlist,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (itemToDisplay.mediaType == MediaType.tv)
                      WatchNextButton(item: itemToDisplay),

                    if (_isOffline)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: colors.warning,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Offline Mode',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Detailed information is unavailable without internet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.comments),
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
                          _SearchIconText(
                            icon: Icons.calendar_today,
                            text: itemToDisplay.releaseDate,
                          ),
                          if (itemToDisplay.status != null)
                            _SearchIconText(
                              icon: Icons.info_outline,
                              text: itemToDisplay.status!,
                            ),
                          if (itemToDisplay.mediaType == MediaType.movie &&
                              itemToDisplay.runtime != null)
                            _SearchIconText(
                              icon: Icons.access_time,
                              text: Formatters.formatRuntime(
                                itemToDisplay.runtime,
                              ),
                            ),
                          if (itemToDisplay.mediaType == MediaType.tv &&
                              itemToDisplay.numberOfSeasons != null)
                            _SearchIconText(
                              icon: Icons.tv,
                              text: '${itemToDisplay.numberOfSeasons} Seasons',
                            ),
                          if (itemToDisplay.mediaType == MediaType.tv &&
                              itemToDisplay.numberOfEpisodes != null)
                            _SearchIconText(
                              icon: Icons.subscriptions,
                              text:
                                  '${itemToDisplay.numberOfEpisodes} Episodes',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (itemToDisplay.genres != null &&
                          itemToDisplay.genres!.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: itemToDisplay.genres!
                              .map(
                                (genre) => ActionChip(
                                  label: Text(
                                    genre,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _onGenreTapped(genre),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 8),

                      _buildTrailers(),

                      if (_mediaDetails?.director != null)
                        Text(
                          '$directorLabel: ${_mediaDetails!.director!.name}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        itemToDisplay.overview,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],

                    if (itemToDisplay.mediaType == MediaType.tv &&
                        itemToDisplay.seasons != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Seasons',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: itemToDisplay.seasons!.length,
                        itemBuilder: (context, index) {
                          final season = itemToDisplay.seasons![index];
                          final seasonNumber = season.seasonNumber;
                          final isExpanded = _expandedSeason == seasonNumber;
                          final isLoading =
                              _loadingSeasons[seasonNumber] ?? false;

                          final episodesSeenInSeason = _seenStatus
                              .where(
                                (s) =>
                                    s.seasonNumber == seasonNumber &&
                                    s.episodeNumber != null,
                              )
                              .map((s) => s.episodeNumber)
                              .toSet()
                              .length;
                          final isComplete =
                              episodesSeenInSeason == season.episodeCount &&
                              season.episodeCount > 0;

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  season.name ?? 'Season $seasonNumber',
                                ),
                                subtitle: Text(
                                  '$episodesSeenInSeason / ${season.episodeCount} episodes seen',
                                  style: TextStyle(
                                    color: isComplete
                                        ? colors.onWatchlist
                                        : null,
                                    fontWeight: isComplete
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isComplete)
                                      Icon(
                                        Icons.check_circle,
                                        color: colors.onWatchlist,
                                      ),
                                    isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            isExpanded
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                          ),
                                  ],
                                ),
                                onTap: () => _fetchSeasonDetails(seasonNumber),
                              ),
                              if (isExpanded &&
                                  _episodesBySeason.containsKey(seasonNumber))
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Column(
                                    children: _episodesBySeason[seasonNumber]!
                                        .map<Widget>((episode) {
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              'E${episode['episode_number']}: ${episode['name']}',
                                            ),
                                            subtitle: Text(
                                              episode['air_date'] ?? '',
                                            ),
                                            trailing: SeenManager(
                                              key: ValueKey(
                                                'seen_ep_${itemToDisplay.id}_${seasonNumber}_${episode['episode_number']}',
                                              ),
                                              item: itemToDisplay,
                                              seasonNumber: seasonNumber,
                                              episodeNumber:
                                                  episode['episode_number']
                                                      as int,
                                            ),
                                          );
                                        })
                                        .toList(),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                                margin: const EdgeInsets.only(right: 12.0),
                                child: Column(
                                  children: [
                                    member.profilePath != null &&
                                            !Platform.environment.containsKey(
                                              'FLUTTER_TEST',
                                            )
                                        ? CircleAvatar(
                                            radius: 40,
                                            backgroundImage: NetworkImage(
                                              'https://image.tmdb.org/t/p/w185${member.profilePath}',
                                            ),
                                          )
                                        : CircleAvatar(
                                            radius: 40,
                                            backgroundColor: colors.placeholder,
                                            child: Icon(
                                              Icons.person,
                                              color: colors.comments,
                                            ),
                                          ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      member.character,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      _buildHorizontalList('Similar', _mediaDetails!.similar),
                      _buildHorizontalList(
                        'Recommendations',
                        _mediaDetails!.recommendations,
                      ),
                    ],
                    const SizedBox(height: 24),
                    MediaListManager(item: itemToDisplay),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: _exportHistory,
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text('Export history'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchProviders() {
    if (_mediaDetails?.watchProviders == null) return const SizedBox.shrink();

    final results = _mediaDetails!.watchProviders!;
    if (results.isEmpty) return const SizedBox.shrink();

    final countryCode = results.containsKey('US') ? 'US' : results.keys.first;
    final countryData = results[countryCode] as Map<String, dynamic>;

    final List<dynamic>? flatrate = countryData['flatrate'];
    if (flatrate == null || flatrate.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Watch on:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: flatrate.map((provider) {
            return Tooltip(
              message: provider['provider_name'],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl:
                      'https://image.tmdb.org/t/p/original${provider['logo_path']}',
                  width: 40,
                  height: 40,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrailers() {
    if (_mediaDetails?.videos == null || _mediaDetails!.videos!.isEmpty) {
      return const SizedBox.shrink();
    }

    final trailers = _mediaDetails!.videos!
        .where((v) => v['type'] == 'Trailer' && v['site'] == 'YouTube')
        .toList();
    if (trailers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trailers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trailers.length,
              itemBuilder: (context, index) {
                final trailer = trailers[index];
                final key = trailer['key'];
                return GestureDetector(
                  onTap: () {
                    Share.share(
                      'https://www.youtube.com/watch?v=$key',
                      subject: 'Watch Trailer',
                    );
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: 'https://img.youtube.com/vi/$key/0.jpg',
                            fit: BoxFit.cover,
                            width: 160,
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(String title, List<MediaItem>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  MediaDetailPage.show(context, item);
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.posterPath != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    'https://image.tmdb.org/t/p/w185${item.posterPath}',
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => Icon(
                                  item.mediaType == MediaType.tv
                                      ? Icons.tv
                                      : Icons.movie,
                                ),
                              )
                            : Container(
                                height: 120,
                                color: Colors.grey[300],
                                child: Icon(
                                  item.mediaType == MediaType.tv
                                      ? Icons.tv
                                      : Icons.movie,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
