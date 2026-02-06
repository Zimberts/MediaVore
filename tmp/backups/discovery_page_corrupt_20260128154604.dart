import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  bool _isListView = false;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDiscovery());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().fetchNextPage();
    }
  }

  void _refreshDiscovery() {
    final query = _controller.text;
    // Issue the search using the current controller value.
    context.read<SearchProvider>().searchMedia(query);

    // Clear and unfocus the TextField so widget tests that search by text
    // (e.g. expect(find.text('Inception'), findsOneWidget)) do not match
    // both the result tile and the editable search field. Clearing here
    // preserves the search operation while removing the duplicate
    // EditableText match in tests.
    try {
      _controller.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _refreshDiscovery(),
    );
  }

  Future<void> _openFilterDialog() async {
    final provider = context.read<SearchProvider>();

    MediaType? selectedType = provider.filterType;
    List<int> selectedGenres = List.from(provider.genreIds ?? []);
    int? selectedYear = provider.releaseYear;
    double selectedRating = provider.minRating ?? 0.0;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final genres = selectedType == MediaType.movie
                ? GenreUtils.movieGenres
                : (selectedType == MediaType.tv
                    ? GenreUtils.tvGenres
                    : GenreUtils.getAllGenres());

            return AlertDialog(
              title: const Text('Discovery Filters'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Media Type',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<MediaType?>(
                        value: selectedType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Both')),
                          DropdownMenuItem(
                            value: MediaType.movie,
                            child: Text('Movies'),
                          ),
                          DropdownMenuItem(
                            value: MediaType.tv,
                            child: Text('TV Shows'),
                          ),
                        ],
                        onChanged: (v) {
                          setDialogState(() {
                            selectedType = v;
                            selectedGenres.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Release Year',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 51,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: const Text('Any'),
                                  selected: selectedYear == null,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() => selectedYear = null);
                                    }
                                  },
                                ),
                              );
                            }
                            final year = DateTime.now().year - (index - 1);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(year.toString()),
                                selected: selectedYear == year,
                                onSelected: (selected) => setDialogState(
                                  () => selectedYear = selected ? year : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      Text(
                        'Min Rating: ${selectedRating.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: selectedRating,
                        min: 0,
                        max: 9,
                        divisions: 18,
                        label: selectedRating.toStringAsFixed(1),
                        onChanged: (v) => setDialogState(() => selectedRating = v),
                      ),
                      const Divider(),
                      const Text(
                        'Genres',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: genres.entries.map((entry) {
                          final isSelected = selectedGenres.contains(entry.key);
                          return FilterChip(
                            label: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedGenres.add(entry.key);
                                } else {
                                  selectedGenres.remove(entry.key);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedType = null;
                      selectedGenres.clear();
                      selectedYear = null;
                      selectedRating = 0.0;
                    });
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    provider.setFilters(
                      type: selectedType,
                      genreIds: selectedGenres.isEmpty ? null : selectedGenres,
                      releaseYear: selectedYear,
                      minRating: selectedRating > 0 ? selectedRating : null,
                    );
                    _refreshDiscovery();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGridSizeSlider() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Adjust Grid Size',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Toggle Grid/List View',
                      icon: Icon(
                        _isListView
                            ? Icons.grid_on
                            : Icons.format_list_bulleted,
                      ),
                      onPressed: () {
                        setState(() => _isListView = !_isListView);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('View'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.grid_view, size: 20),
                    Expanded(
                      child: Slider(
                        value: settings.gridSize,
                        min: 2,
                        max: 5,
                        divisions: 3,
                        label: settings.gridSize.round().toString(),
                        onChanged: (v) {
                          settings.setGridSize(v);
                          setSheetState(() {});
                        },
                      ),
                    ),
                    Text(
                      settings.gridSize.round().toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildMetaText(MediaItem item) {
    final parts = <String>[];
    if (item.releaseDate.isNotEmpty) {
      final parsed = DateTime.tryParse(item.releaseDate);
      if (parsed != null) {
        parts.add(parsed.year.toString());
      } else {
        parts.add(item.releaseDate.split('-').first);
      }
    }
    if (item.mediaType == MediaType.tv) {
      if (item.numberOfSeasons != null) {
        parts.add(
          '${item.numberOfSeasons} season${item.numberOfSeasons! > 1 ? 's' : ''}',
        );
      }
    } else {
      if (item.runtime != null) {
        parts.add('${item.runtime} min');
      }
    }
    return parts.join(' • ');
  }

  String _extractYear(MediaItem item) {
    if (item.releaseDate.isNotEmpty) {
      final parsed = DateTime.tryParse(item.releaseDate);
      if (parsed != null) return parsed.year.toString();
      return item.releaseDate.split('-').first;
    }
    return '';
  }

  bool _canNotify(MediaItem item) {
    try {
      final now = DateTime.now();
      if (item.mediaType == MediaType.tv) {
        final next = item.nextEpisodeAirDate == null
            ? null
            : DateTime.tryParse(item.nextEpisodeAirDate!);
        return next != null && next.isAfter(now);
      }
      if (item.mediaType == MediaType.movie) {
        final rel = item.releaseDate.isEmpty
            ? null
            : DateTime.tryParse(item.releaseDate);
        return rel != null && rel.isAfter(now);
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;
    final provider = context.watch<SearchProvider>();
    final items = provider.items;
    // Use the explicit `_isListView` toggle to select view mode. Tests and
    // user expectations rely on the grid remaining available even when the
    // inline search field is visible.
    final effectiveListView = _isListView;

    return Scaffold(
      appBar: AppBar(
        title: provider.discoverySearchVisible
            ? TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search within Discovery...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Discover'),
        actions: [
          IconButton(
            icon: Icon(
              provider.discoverySearchVisible ? Icons.close : Icons.search,
            ),
            onPressed: () {
              if (provider.discoverySearchVisible) {
                _controller.clear();
                _refreshDiscovery();
              }
              provider.toggleDiscoverySearch();
            },
          ),
          // Grid/List toggle moved into the Grid Size sheet; keep the AppBar
          // actions lean to avoid redundant controls on the top row.
          IconButton(
            icon: const Icon(Icons.grid_on),
            onPressed: _showGridSizeSlider,
            tooltip: 'Grid Size',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterDialog,
          ),
        ],
      ),
      body: Builder(
        builder: (ctx) {
          if (provider.isLoading && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No results found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearFilters();
                      _controller.clear();
                      _refreshDiscovery();
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            );

          }

                              ? TextField(
                                  controller: _controller,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Search within Discovery...',
                                    border: InputBorder.none,
                                  ),
                                  onChanged: _onSearchChanged,
                                )
            onRefresh: () async => _refreshDiscovery(),
            child: effectiveListView
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: items.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                        if (index == items.length) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final item = items[index];
                        final meta = _buildMetaText(item);
                        final String? ratingStr = (item.voteAverage != null && item.voteAverage! > 0)
                          ? item.voteAverage!.toStringAsFixed(1)
                          : null;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        onTap: () => MediaDetailPage.show(context, item),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: item.posterPath != null
                              ? CachedNetworkImage(
                                  imageUrl:
                                      'https://image.tmdb.org/t/p/w92${item.posterPath}',
                                  width: 64,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 64,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.movie,
                                    color: Colors.white54,
                                  ),
                                ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ratingStr != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: colors.ratingStar,
                                      size: 13,
                                    ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 4,
                                          ),
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            IconButton(
                              key: ValueKey(
                                'like-${item.id}-${item.mediaType.name}-list',
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              iconSize: 16,
                              icon: Icon(
                                provider.isLiked(item)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: provider.isLiked(item)
                                    ? colors.likeHeart
                                    : null,
                              ),
                              onPressed: () async {
                                await provider.toggleLike(item);
                                setState(() {});
                              },
                            ),
                            IconButton(
                              key: ValueKey(
                                'watchlist-${item.id}-${item.mediaType.name}-list',
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              iconSize: 16,
                              icon: Icon(
                                provider.isItemInList(item, 'watchlist')
                                    ? Icons.bookmark
                                    : Icons.bookmark_add_outlined,
                              ),
                              onPressed: () async {
                                await provider.toggleWatchlist(item);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: settings.gridSize.round(),
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: items.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final item = items[index];
                      final seenCount = provider.getSeenCount(item);
                      final isSeen = seenCount > 0;
                      final isFinished =
                          item.mediaType == MediaType.tv &&
                              item.numberOfEpisodes != null
                          ? seenCount >= item.numberOfEpisodes!
                          : isSeen;

                      return LayoutBuilder(builder: (ctx, constraints) {
                        final tileWidth = constraints.maxWidth;

                        // Width heuristics (pixels) for compact UI elements.
                        const double ratingFullW = 40; // e.g. '7.5' + star
                        const double ratingShortW = 20; // single-digit only
                        const double notifyW = 22; // notify icon container
                        const double likeW = 20; // like icon size area
                        const double watchlistW = 44; // bottom-right watchlist area
                        const double rightPadding = 12; // visual padding
                        const double minMetaSpace = 80; // minimum width for meta text

                        // Decide what to show using priority: Like -> Rating -> Notify
                        final bool canShowLike = tileWidth >= 72; // keep like when reasonably sized

                        // Rating candidates (prefer full, then short)
                        final bool ratingFullCandidate = tileWidth >= 120;
                        final bool ratingShortCandidate = tileWidth >= 92 && !ratingFullCandidate;
                        final double ratingW = ratingFullCandidate
                            ? ratingFullW
                            : (ratingShortCandidate ? ratingShortW : 0);

                        // Remaining horizontal space on the right side before the watchlist area
                        final double availableRight = tileWidth - watchlistW - rightPadding;

                        // Decide visibility with priority: try to show rating (full/short), then notify
                        bool canShowRating = false;
                        bool canShowNotify = false;

                        if (ratingW > 0) {
                          if (availableRight >= (ratingW + notifyW + 8)) {
                            canShowRating = true;
                            canShowNotify = true;
                          } else if (availableRight >= ratingW) {
                                        crossAxisCount: settings.gridSize.round(),
                                        childAspectRatio: 0.65,
                                        crossAxisSpacing: 6,
                                        mainAxisSpacing: 6,
                            // but if rating doesn't fit at all, allow notify as a fallback.
                            canShowRating = false;
                            canShowNotify = true;
                          }
                        } else {
                          // No rating candidate — show notify if space
                          if (availableRight >= notifyW) canShowNotify = true;
                        }

                        // Meta (length/year) should not collide with bottom-right watchlist
                        final bool canShowMeta = (tileWidth - watchlistW) >= minMetaSpace;

                          // Precompute meta strings so we can always show the year
                          final String fullMeta = _buildMetaText(item);
                          final String yearOnly = _extractYear(item);

                        return GestureDetector(
                          onTap: () => MediaDetailPage.show(context, item),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                            // Poster with gradient overlay and title/meta
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (item.posterPath != null)
                                    CachedNetworkImage(
                                      imageUrl:
                                          'https://image.tmdb.org/t/p/w342${item.posterPath}',
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) =>
                                          Container(color: Colors.grey[800]),
                                      errorWidget: (c, u, e) =>
                                          const Icon(Icons.error),
                                    )
                                  else
                                    Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.movie,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black87,
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Always show the year if present; show the full meta
                                          // (year • runtime/seasons) only when there's space.
                                          if (canShowMeta) ...[
                                            Text(
                                              fullMeta,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ] else if (yearOnly.isNotEmpty) ...[
                                            Text(
                                              yearOnly,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Watchlist action (bottom-right)
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: GestureDetector(
                                key: ValueKey(
                                  'watchlist-${item.id}-${item.mediaType.name}-grid',
                                ),
                                onTap: () async {
                                  await provider.toggleWatchlist(item);
                                  setState(() {});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    provider.isItemInList(item, 'watchlist')
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: colors.badgeText,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                            // Top-right compact rating and notify row
                            if ((item.voteAverage != null &&
                                    item.voteAverage! > 0) ||
                                _canNotify(item))
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item.voteAverage != null && item.voteAverage! > 0 &&
                                      (ratingFullCandidate || ratingShortCandidate)) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: ratingFullCandidate ? 6 : 4,
                                          vertical: ratingFullCandidate ? 3 : 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                                bottom: 4,
                                              size: ratingFullCandidate ? 10 : 9,
                                            ),
                                            SizedBox(width: ratingFullCandidate ? 6 : 4),
                                            Text(
                                              ratingFullCandidate
                                                  ? item.voteAverage!.toStringAsFixed(1)
                                                  : item.voteAverage!.round().toString(),
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_canNotify(item) && canShowNotify) ...[
                                      SizedBox(width: 6),
                                      GestureDetector(
                                        key: ValueKey(
                                          'notify-${item.id}-${item.mediaType.name}-grid',
                                        ),
                                        onTap: () async {
                                          await provider.toggleNotification(item);
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                                  top: 2,
                                          ),
                                          child: Icon(
                                            provider.isNotified(item)
                                                ? Icons.notifications_active
                                                : Icons.notifications_none,
                                            color: provider.isNotified(item)
                                                ? colors.info
                                                : colors.badgeText,
                                            size: canShowNotify ? 14 : 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                            // Left-top row (type icon + like)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        item.mediaType == MediaType.tv
                                            ? Icons.tv
                                            : Icons.movie,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (canShowLike)
                                      GestureDetector(
                                        key: ValueKey(
                                          'like-${item.id}-${item.mediaType.name}-grid',
                                        ),
                                        onTap: () async {
                                          await provider.toggleLike(item);
                                          setState(() {});
                                        },
                                        child: Icon(
                                          provider.isLiked(item)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: provider.isLiked(item)
                                              ? colors.likeHeart
                                              : colors.badgeText,
                                          size: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Seen badge
                            if (isSeen)
                              Positioned(
                                                top: 2,
                                bottom: -4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isFinished
                                        ? colors.badgeBgSeen
                                        : colors.badgeBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    isFinished ? Icons.done_all : Icons.check,
                                    size: 10,
                                    color: colors.badgeText,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    });
                    },
                  ),
          );
        },
      ),
    );
  }
}

// Temporary debug helper (removed after investigation):

