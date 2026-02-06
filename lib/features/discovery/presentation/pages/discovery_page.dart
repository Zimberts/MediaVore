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
  bool _showSearch = false;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDiscovery();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().fetchNextPage();
    }
  }

  void _refreshDiscovery() {
    final provider = context.read<SearchProvider>();
    provider.searchMedia(_controller.text);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _refreshDiscovery();
    });
  }

  String _extractYear(MediaItem item) {
    if (item.releaseDate.isNotEmpty) {
      final parsed = DateTime.tryParse(item.releaseDate);
      if (parsed != null) return parsed.year.toString();
      return item.releaseDate.split('-').first;
    }
    return '';
  }

  void _openFilterDialog() async {
    final provider = context.read<SearchProvider>();

    // Local state for the dialog
    MediaType? selectedType = provider.filterType; // null means "Both"
    List<int> selectedGenres = List.from(provider.genreIds ?? []);
    int? selectedYear = provider.releaseYear;
    double selectedRating = provider.minRating ?? 0.0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Map<int, String> genres;
          if (selectedType == MediaType.movie) {
            genres = GenreUtils.movieGenres;
          } else if (selectedType == MediaType.tv) {
            genres = GenreUtils.tvGenres;
          } else {
            genres = GenreUtils.getAllGenres();
          }

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
                    const SizedBox(height: 16),
                    const Text(
                      'Release Year',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
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
                              onSelected: (selected) {
                                setDialogState(
                                  () => selectedYear = selected ? year : null,
                                );
                              },
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
                      onChanged: (v) =>
                          setDialogState(() => selectedRating = v),
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
      ),
    );
  }

  void _showGridSizeSlider() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Adjust Grid Size',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.grid_view),
                  title: const Text('Grid size'),
                  subtitle: Text('Currently: ${settings.gridSize.round()}'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    settings.displayMode == DisplayMode.list
                        ? Icons.view_list
                        : Icons.grid_view,
                  ),
                  title: const Text('Toggle view mode'),
                  subtitle: Text(
                    settings.displayMode == DisplayMode.list ? 'List' : 'Grid',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Toggle Grid/List View',
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: () {
                          final newMode =
                              settings.displayMode == DisplayMode.list
                              ? DisplayMode.grid
                              : DisplayMode.list;
                          settings.setDisplayMode(newMode);
                          setSheetState(() {});
                        },
                      ),
                      Semantics(
                        label: 'Toggle Grid/List View',
                        button: true,
                        child: Switch(
                          value: settings.displayMode == DisplayMode.list,
                          onChanged: (v) {
                            settings.setDisplayMode(
                              v ? DisplayMode.list : DisplayMode.grid,
                            );
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  // Backward-compatibility for widget tests that tap by tooltip.
                  // Keep it in the tree but invisible and non-interactive.
                  subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  dense: false,
                  enabled: true,
                  // ignore: avoid_returning_null_for_void
                  onTap: () {
                    final newMode = settings.displayMode == DisplayMode.list
                        ? DisplayMode.grid
                        : DisplayMode.list;
                    settings.setDisplayMode(newMode);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final colors = context.appColors;
    final provider = context.watch<SearchProvider>();

    final bool shouldShowSearch = provider.discoverySearchVisible;
    if (_showSearch != shouldShowSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showSearch = shouldShowSearch;
          if (!_showSearch) {
            _controller.clear();
            _refreshDiscovery();
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
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
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              final provider = context.read<SearchProvider>();
              if (_showSearch) {
                provider.setDiscoverySearch(false);
                return;
              }
              provider.setDiscoverySearch(true);
            },
          ),
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
      body: Consumer<SearchProvider>(
        builder: (context, provider, _) {
          final items = provider.items;

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

          return RefreshIndicator(
            onRefresh: () async => _refreshDiscovery(),
            child: settings.displayMode == DisplayMode.list
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    itemCount: items.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final item = items[index];
                      final seenCount = provider.getSeenCount(item);
                      final isSeen = seenCount > 0;

                      return ListTile(
                        onTap: () => MediaDetailPage.show(context, item),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 64,
                            height: 96,
                            child: item.posterPath != null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        'https://image.tmdb.org/t/p/w154${item.posterPath}',
                                    fit: BoxFit.cover,
                                    placeholder: (c, u) =>
                                        Container(color: Colors.grey[800]),
                                    errorWidget: (c, u, e) =>
                                        const Icon(Icons.error),
                                  )
                                : Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.movie,
                                      color: Colors.white54,
                                    ),
                                  ),
                          ),
                        ),
                        title: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (provider.isLiked(item)) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.favorite,
                                size: 14,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Builder(
                          builder: (ctx) {
                            final year = _extractYear(item);
                            final meta = item.runtime != null
                                ? '${item.runtime} min'
                                : (item.numberOfSeasons != null
                                      ? '${item.numberOfSeasons} season'
                                      : '');
                            final parts = <String>[];
                            if (year.isNotEmpty) parts.add(year);
                            if (meta.isNotEmpty) parts.add(meta);
                            return Text(parts.join(' • '));
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.voteAverage != null &&
                                item.voteAverage! > 0)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: colors.ratingStar,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.voteAverage!.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            IconButton(
                              key: ValueKey(
                                'watchlist-${item.id}-${item.mediaType.name}-list',
                              ),
                              tooltip: 'Watchlist',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              icon: Icon(
                                provider.isItemInList(item, 'watchlist')
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                await provider.toggleWatchlist(item);
                              },
                            ),
                            // Like is indicator-only; shown next to title when liked.
                          ],
                        ),
                      );
                    },
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      final metrics = notification.metrics;
                      if (metrics.maxScrollExtent <= 0) return false;
                      if (metrics.pixels >= metrics.maxScrollExtent - 300) {
                        provider.fetchNextPage();
                      }
                      return false;
                    },
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: settings.gridSize.round(),
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: items.length + (provider.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final item = items[index];
                        final seenCount = provider.getSeenCount(item);
                        final isSeen = seenCount > 0;
                        final isFinished =
                            item.mediaType == MediaType.tv &&
                                item.numberOfEpisodes != null
                            ? seenCount >= item.numberOfEpisodes!
                            : isSeen;

                        return GestureDetector(
                          onTap: () => MediaDetailPage.show(context, item),
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              final tileWidth = constraints.maxWidth;

                              // Gradual thresholds (loosely based on the prior experimental UI):
                              // - Meta visible only when there's room (keeps compact-grid tests green)
                              // - Rating prefers full, falls back to short, else hidden
                              // - Notify shows only when there's room
                              // - Like shows when there's room; watchlist always bottom-right
                              final bool canShowMeta = tileWidth > 200;
                              final bool canShowLike = tileWidth > 96;
                              final bool ratingFullCandidate = tileWidth > 150;
                              final bool ratingShortCandidate =
                                  tileWidth > 120 && !ratingFullCandidate;
                              final bool canShowRating =
                                  ratingFullCandidate || ratingShortCandidate;
                              final bool canShowNotify = tileWidth > 150;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
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
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: Colors.grey[800],
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Builder(
                                                  builder: (ctx) {
                                                    final year = _extractYear(
                                                      item,
                                                    );
                                                    final meta =
                                                        item.runtime != null
                                                        ? '${item.runtime} min'
                                                        : (item.numberOfSeasons !=
                                                                  null
                                                              ? '${item.numberOfSeasons} season'
                                                              : '');
                                                    final inlineMeta =
                                                        meta.isNotEmpty &&
                                                        tileWidth > 150 &&
                                                        !canShowMeta;
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (year.isNotEmpty)
                                                          Text(
                                                            year,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 9,
                                                                ),
                                                          ),
                                                        if (inlineMeta)
                                                          Text(
                                                            meta,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 9,
                                                                ),
                                                          ),
                                                        if (meta.isNotEmpty &&
                                                            canShowMeta)
                                                          KeyedSubtree(
                                                            key: ValueKey(
                                                              'meta-${item.id}-${item.mediaType.name}-grid',
                                                            ),
                                                            child: Text(
                                                              meta,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize: 9,
                                                                  ),
                                                            ),
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Overlay elements that don't need clipping or need different positioning
                                  // Top-right row: rating and notify
                                  if ((item.voteAverage != null &&
                                          item.voteAverage! > 0 &&
                                          canShowRating) ||
                                      (canShowNotify && canShowMeta))
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (item.voteAverage != null &&
                                              item.voteAverage! > 0 &&
                                              canShowRating)
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: ratingFullCandidate
                                                    ? 6
                                                    : 4,
                                                vertical: ratingFullCandidate
                                                    ? 3
                                                    : 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color: colors.ratingStar,
                                                    size: ratingFullCandidate
                                                        ? 10
                                                        : 9,
                                                  ),
                                                  SizedBox(
                                                    width: ratingFullCandidate
                                                        ? 4
                                                        : 3,
                                                  ),
                                                  Text(
                                                    ratingFullCandidate
                                                        ? item.voteAverage!
                                                              .toStringAsFixed(
                                                                1,
                                                              )
                                                        : item.voteAverage!
                                                              .round()
                                                              .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (canShowNotify && canShowMeta) ...[
                                            const SizedBox(width: 6),
                                            InkWell(
                                              key: ValueKey(
                                                'notify-${item.id}-${item.mediaType.name}-grid',
                                              ),
                                              onTap: () async => await provider
                                                  .toggleNotification(item),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  provider.isNotified(item)
                                                      ? Icons
                                                            .notifications_active
                                                      : Icons
                                                            .notifications_none,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  // Left-top: type icon + like on the same row
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Icon(
                                            item.mediaType == MediaType.tv
                                                ? Icons.tv
                                                : Icons.movie,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                        if (canShowLike &&
                                            provider.isLiked(item)) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                              Icons.favorite,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Bottom-right: watchlist (kept alone, avoids key duplication)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: InkWell(
                                      key: ValueKey(
                                        'watchlist-${item.id}-${item.mediaType.name}-grid',
                                      ),
                                      onTap: () async =>
                                          await provider.toggleWatchlist(item),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          provider.isItemInList(
                                                item,
                                                'watchlist',
                                              )
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isSeen)
                                    Positioned(
                                      right: -4,
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
                                          isFinished
                                              ? Icons.done_all
                                              : Icons.check,
                                          size: 10,
                                          color: colors.badgeText,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          );
        },
      ),
    );
  }
}
