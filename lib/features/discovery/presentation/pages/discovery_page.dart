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

  void _showGridSizeSlider() {
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
                  'Adjust Grid Size',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
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
            child: GridView.builder(
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
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Overlay elements that don't need clipping or need different positioning
                      if (item.voteAverage != null && item.voteAverage! > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
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
                                  item.voteAverage!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
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
