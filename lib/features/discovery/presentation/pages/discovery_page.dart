import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/search/presentation/widgets/media_item_poster.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watchlist_icon_button.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  static const double _gridPadding = 8;

  bool _showSearch = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  late final SettingsProvider _settings;
  late String _credential;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Reload once a TMDB credential is saved (first-launch screen or
    // Settings), so a stale "missing key" error doesn't stay on screen.
    _settings = context.read<SettingsProvider>();
    _credential = _settings.tmdbApiKey;
    _settings.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDiscovery();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().fetchNextPage();
    }
  }

  void _onSettingsChanged() {
    final credential = _settings.tmdbApiKey;
    if (credential == _credential) return;
    _credential = credential;
    if (credential.isNotEmpty && mounted) _refreshDiscovery();
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
            title: Text(context.l10n.discoveryFiltersTitle),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.seenMediaType,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<MediaType?>(
                      value: selectedType,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.l10n.discoveryBoth),
                        ),
                        DropdownMenuItem(
                          value: MediaType.movie,
                          child: Text(context.l10n.commonMovies),
                        ),
                        DropdownMenuItem(
                          value: MediaType.tv,
                          child: Text(context.l10n.commonTvShows),
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
                    Text(
                      context.l10n.discoveryReleaseYear,
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
                                label: Text(context.l10n.discoveryAnyYear),
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
                      context.l10n.discoveryMinRating(
                        selectedRating.toStringAsFixed(1),
                      ),
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
                    Text(
                      context.l10n.discoveryGenres,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: genres.entries.map((entry) {
                        final isSelected = selectedGenres.contains(entry.key);
                        return FilterChip(
                          label: Text(
                            GenreUtils.localizedName(context.l10n, entry.key),
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
                child: Text(context.l10n.discoveryReset),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.commonCancel),
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
                child: Text(context.l10n.discoveryApply),
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
                Text(
                  context.l10n.listsDisplayOptions,
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
                  Text(
                    context.l10n.listsGridSize,
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

  /// Full-page state shown when the first page failed to load.
  Widget _buildErrorState(SearchProvider provider) {
    final errorType = provider.errorType!;
    final needsApiKey =
        errorType == SearchErrorType.missingApiKey ||
        errorType == SearchErrorType.invalidApiKey;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(switch (errorType) {
              SearchErrorType.missingApiKey ||
              SearchErrorType.invalidApiKey => Icons.key_off,
              SearchErrorType.offline => Icons.wifi_off,
              SearchErrorType.server ||
              SearchErrorType.unknown => Icons.cloud_off,
            }, size: 48),
            const SizedBox(height: 16),
            Text(
              searchErrorMessage(errorType, context.l10n),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (needsApiKey)
              ElevatedButton.icon(
                key: const Key('discovery_open_settings'),
                icon: const Icon(Icons.settings),
                label: Text(context.l10n.commonOpenSettings),
                // Saving a key reloads via _onSettingsChanged.
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ),
              )
            else
              ElevatedButton.icon(
                key: const Key('discovery_retry'),
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.commonRetry),
                onPressed: () => _refreshDiscovery(),
              ),
          ],
        ),
      ),
    );
  }

  /// Trailing list/grid cell: spinner while loading the next page, or a
  /// retry button when that load failed.
  Widget _buildListFooter(SearchProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: TextButton.icon(
        key: const Key('discovery_retry_next_page'),
        icon: const Icon(Icons.refresh),
        label: Text(context.l10n.commonRetry),
        onPressed: provider.retryNextPage,
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
                decoration: InputDecoration(
                  hintText: context.l10n.discoverySearchHint,
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : Text(context.l10n.discoveryTitle),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch
                ? context.l10n.commonClose
                : context.l10n.discoverySearchToggle,
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
            tooltip: context.l10n.listsDisplayMode,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: context.l10n.discoveryFiltersTitle,
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

          if (items.isEmpty && provider.errorType != null) {
            return _buildErrorState(provider);
          }

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.l10n.discoveryNoResults),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearFilters();
                      _controller.clear();
                      _refreshDiscovery();
                    },
                    child: Text(context.l10n.discoveryClearFilters),
                  ),
                ],
              ),
            );
          }

          final hasFooter = provider.isLoading || provider.errorType != null;

          return RefreshIndicator(
            onRefresh: () async => _refreshDiscovery(),
            child: settings.displayMode == DisplayMode.list
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: items.length + (hasFooter ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return _buildListFooter(provider);
                      }

                      final item = items[index];

                      String lengthText = '';
                      if (item.mediaType == MediaType.tv) {
                        lengthText = (item.numberOfSeasons == null
                            ? '?'
                            : context.l10n.mediaSeasonCount(
                                item.numberOfSeasons!,
                              ));
                      } else if (item.runtime != null) {
                        lengthText = context.l10n.mediaRuntimeMinutes(
                          item.runtime!,
                        );
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
                            child: MediaPosterCard(
                              compact: true,
                              data: mediaItemPosterData(
                                context,
                                item,
                                seenCount: provider.getSeenCount(item),
                                imageSize: 'w92',
                              ),
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
                                color: colors.text2,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${item.releaseDate.length >= 4 ? item.releaseDate.substring(0, 4) : "?"} • $lengthText',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (item.voteAverage != null &&
                                  item.voteAverage! > 0) ...[
                                const Text(' • '),
                                Icon(
                                  Icons.star,
                                  color: colors.ratingStar,
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
                : LayoutBuilder(
                    builder: (context, constraints) => GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(_gridPadding),
                      gridDelegate: MediaPosterCard.gridDelegate(
                        context: context,
                        width: constraints.maxWidth - 2 * _gridPadding,
                        crossAxisCount: settings.gridSize.round(),
                      ),
                      itemCount: items.length + (hasFooter ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return _buildListFooter(provider);
                        }

                        final item = items[index];
                        return MediaPosterCard(
                          data: mediaItemPosterData(
                            context,
                            item,
                            seenCount: provider.getSeenCount(item),
                            liked: provider.isLiked(item),
                          ),
                          onTap: () => MediaDetailPage.show(context, item),
                          action: WatchlistIconButton(
                            item: item,
                            iconSize: 18,
                            onImage: true,
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
