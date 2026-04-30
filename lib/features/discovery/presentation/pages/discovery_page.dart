import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watchlist_icon_button.dart';

class DiscoveryPage extends StatefulWidget {
  final ValueListenable<int>? searchTrigger;

  const DiscoveryPage({super.key, this.searchTrigger});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  bool _showSearch = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.searchTrigger?.addListener(_handleSearchTrigger);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDiscovery();
    });
  }

  @override
  void didUpdateWidget(covariant DiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchTrigger != widget.searchTrigger) {
      oldWidget.searchTrigger?.removeListener(_handleSearchTrigger);
      widget.searchTrigger?.addListener(_handleSearchTrigger);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    widget.searchTrigger?.removeListener(_handleSearchTrigger);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().fetchNextPage();
    }
  }

  void _refreshDiscovery([String? query]) {
    final provider = context.read<SearchProvider>();
    provider.searchMedia(query ?? _controller.text);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _refreshDiscovery(value);
    });
  }

  void _handleSearchTrigger() {
    if (!mounted) return;
    if (!_showSearch) {
      setState(() {
        _showSearch = true;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
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

  void _showDisplayModePicker() {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Display Options',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ToggleButtons(
                  isSelected: [
                    settings.displayMode == DisplayMode.list,
                    settings.displayMode == DisplayMode.grid,
                  ],
                  onPressed: (index) {
                    settings.setDisplayMode(DisplayMode.values[index]);
                    setSheetState(() {});
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.list),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.grid_view),
                    ),
                  ],
                ),
                if (settings.displayMode == DisplayMode.grid) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Grid Size',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                ],
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

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _controller,
                autofocus: true,
                focusNode: _searchFocusNode,
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
              setState(() {
                if (_showSearch) {
                  _controller.clear();
                  _refreshDiscovery();
                }
                _showSearch = !_showSearch;
              });
            },
          ),
          IconButton(
            icon: Icon(
              settings.displayMode == DisplayMode.grid
                  ? Icons.grid_on
                  : Icons.list,
            ),
            onPressed: _showDisplayModePicker,
            tooltip: 'Display Mode',
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
                    padding: const EdgeInsets.all(8),
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

                      String lengthText = '';
                      if (item.mediaType == MediaType.tv) {
                        lengthText = '${item.numberOfSeasons ?? "?"} seasons';
                      } else if (item.runtime != null) {
                        lengthText = '${item.runtime} min';
                      }

                      return InkWell(
                        onTap: () => MediaDetailPage.show(context, item),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: SizedBox(
                            width: 50,
                            height: 75,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.posterPath != null
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              'https://image.tmdb.org/t/p/w92${item.posterPath}',
                                          fit: BoxFit.cover,
                                          height: double.infinity,
                                          width: double.infinity,
                                          placeholder: (context, url) =>
                                              Container(
                                                color: Colors.grey[800],
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        )
                                      : Container(
                                          color: Colors.grey[800],
                                          height: double.infinity,
                                          width: double.infinity,
                                          child: const Icon(
                                            Icons.movie,
                                            color: Colors.white54,
                                          ),
                                        ),
                                ),
                                if (isSeen)
                                  Positioned(
                                    bottom: -4,
                                    right: -4,
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
                            ),
                          ),
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (provider.isLiked(item))
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Icon(
                                    Icons.favorite,
                                    size: 16,
                                    color: colors.likeHeart,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.mediaType == MediaType.tv
                                    ? Icons.tv
                                    : Icons.movie,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${item.releaseDate?.isNotEmpty == true && item.releaseDate!.length >= 4 ? item.releaseDate!.substring(0, 4) : "?"} • $lengthText',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (item.voteAverage != null &&
                                  item.voteAverage! > 0) ...[
                                const Text(' • '),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(item.voteAverage!.toStringAsFixed(1)),
                              ],
                            ],
                          ),
                          trailing: WatchlistIconButton(item: item),
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

                      String lengthText = '';
                      if (item.mediaType == MediaType.tv) {
                        lengthText = '${item.numberOfSeasons ?? "?"} S';
                      } else if (item.runtime != null) {
                        lengthText = '${item.runtime}m';
                      }

                      return GestureDetector(
                        onTap: () => MediaDetailPage.show(context, item),
                        child: Stack(
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
                                          Container(color: Colors.grey[800]),
                                      errorWidget: (context, url, error) =>
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
                                      padding: const EdgeInsets.only(
                                        left: 6,
                                        top: 24,
                                        bottom: 6,
                                        right: 18,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  item.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (provider.isLiked(item))
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 4.0,
                                                      ),
                                                  child: Icon(
                                                    Icons.favorite,
                                                    size: 10,
                                                    color: colors.likeHeart,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.releaseDate?.isNotEmpty == true && item.releaseDate!.length >= 4 ? item.releaseDate!.substring(0, 4) : ""} • $lengthText',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Overlay elements that don't need clipping or need different positioning
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.voteAverage != null &&
                                      item.voteAverage! > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 10,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            item.voteAverage!.toStringAsFixed(
                                              1,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    height: 22,
                                    width: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: WatchlistIconButton(
                                      item: item,
                                      iconSize: 14,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
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
                                    isFinished ? Icons.done_all : Icons.check,
                                    size: 10,
                                    color: colors.badgeText,
                                  ),
                                ),
                              ),
                          ],
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
