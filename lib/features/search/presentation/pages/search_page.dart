import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  late int _lastResetCount;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
    _lastResetCount = Provider.of<SearchProvider>(context, listen: false).resetCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SearchProvider>().loadWatchlist();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().fetchNextPage();
    }
  }

  void _onSearchChanged(String query, SearchProvider provider) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      provider.searchMedia(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    // Handle reset request from MainPage (tapping the search tab again)
    if (provider.resetCount > _lastResetCount) {
      _lastResetCount = provider.resetCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          // We set selection twice to ensure it sticks after the focus event
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _buildContent(provider),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search movies & series...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (value) => _onSearchChanged(value, provider),
              onSubmitted: (value) {
                _debounce?.cancel();
                provider.searchMedia(value);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(SearchProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              provider.isOffline ? 'You are offline.' : 'Search for movies or series!',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
      controller: _scrollController,
      itemBuilder: (context, index) {
        if (index >= provider.items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final item = provider.items[index];
        final isSaved = provider.watchlistIds.contains(item.id.toString());
        final isTv = item.mediaType == MediaType.tv;
        final seenCount = provider.getSeenCount(item);
        final isSeen = seenCount > 0;
        final isLiked = provider.isLiked(item);

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MediaDetailPage(item: item)),
          ),
          child: ListTile(
            leading: _buildPoster(item, isTv, isSeen, seenCount, item.numberOfEpisodes),
            title: _buildTitle(item, isTv, isLiked),
            subtitle: Row(
              children: [
                Expanded(
                  child: Align(
                  alignment: Alignment.centerLeft,
                      child: Text(item.releaseDate)
                  )
                ),
                if (isTv)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Badge(
                      label: Text(item.numberOfSeasons != null ? '${item.numberOfSeasons}S' : 'TV'),
                    ),
                  )
                else if (item.runtime != null && item.runtime! > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Badge(
                      label: Text(Formatters.formatRuntime(item.runtime)),
                      backgroundColor: Colors.blueGrey,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => provider.toggleWatchlist(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPoster(MediaItem item, bool isTv, bool isSeen, int seenCount, int? totalEpisodes) {
    bool isFinished = false;
    if (isSeen) {
      if (isTv && totalEpisodes != null && totalEpisodes > 0) {
        isFinished = seenCount >= totalEpisodes;
      } else if (!isTv) {
        isFinished = true;
      }
    }
    final settings = context.watch<SettingsProvider>();
    final palette = Theme.of(context).brightness == Brightness.dark
        ? settings.darkPalette
        : settings.lightPalette;

    return Stack(
      children: [
        item.posterPath != null
            ? CachedNetworkImage(
                imageUrl: 'https://image.tmdb.org/t/p/w92${item.posterPath}',
                width: 50,
                height: 75,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Icon(isTv ? Icons.tv : Icons.movie),
              )
            : Container(
                width: 50,
                height: 75,
                color: Colors.grey[200],
                child: Icon(isTv ? Icons.tv : Icons.movie),
              ),
        if (isSeen)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isFinished ? palette.badgeBgSeen : palette.badgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              padding: const EdgeInsets.all(2),
              child: Icon(
                isFinished ? Icons.done_all : Icons.check,
                size: 10,
                color: palette.badgeText,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(MediaItem item, bool isTv, bool isLiked) {
    final settings = context.watch<SettingsProvider>();
    final palette = Theme.of(context).brightness == Brightness.dark
        ? settings.darkPalette
        : settings.lightPalette;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (isLiked)
                  Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(Icons.favorite, size: 16, color: palette.likeHeart),
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
