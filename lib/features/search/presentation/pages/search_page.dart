import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// The main page for searching for movies and series.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).loadWatchlist();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaVore Search'),
        bottom: context.watch<SearchProvider>().isOffline 
          ? PreferredSize(
              preferredSize: const Size.fromHeight(30),
              child: Container(
                color: Colors.orange,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text(
                  'Offline Mode - Some features unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.isOffline ? 'You are offline.' : 'Search for movies or series!',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  if (provider.isOffline) ...[
                    const SizedBox(height: 16),
                    const Text('Go to your watchlist to see saved items.', style: TextStyle(color: Colors.grey)),
                  ],
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
              final isSaved = provider.watchlistIds.contains(item.id);
              final isTv = item.mediaType == MediaType.tv;
              final seenCount = provider.getSeenCount(item);
              final isSeen = seenCount > 0;
              
              bool isFinished = false;
              if (isSeen) {
                if (isTv && item.numberOfEpisodes != null && item.numberOfEpisodes! > 0) {
                  isFinished = seenCount >= item.numberOfEpisodes!;
                } else if (!isTv) {
                  isFinished = true; // Movies are finished if seen at least once
                }
              }

              return InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaDetailPage(item: item),
                    ),
                  );
                  if (mounted) {
                    provider.loadWatchlist();
                  }
                },
                child: ListTile(
                  leading: Stack(
                    children: [
                      item.posterPath != null
                          ? CachedNetworkImage(
                              imageUrl:
                                  'https://image.tmdb.org/t/p/w92${item.posterPath}',
                              width: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  Icon(isTv ? Icons.tv : Icons.movie),
                            )
                          : Icon(isTv ? Icons.tv : Icons.movie, size: 50),
                      if (isSeen)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isFinished ? Colors.blue : Colors.green,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              isFinished ? Icons.done_all : Icons.check, 
                              size: 12, 
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(item.title)),
                      if (isTv)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Badge(
                            label: Text(
                              item.numberOfSeasons != null
                                  ? 'TV • ${item.numberOfSeasons} S'
                                  : 'TV',
                            ),
                          ),
                        ),
                      if (!isTv && item.runtime != null && item.runtime! > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Badge(
                            label: Text(Formatters.formatRuntime(item.runtime)),
                            backgroundColor: Colors.blueGrey,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.releaseDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isTv && isSeen)
                        Text(
                          isFinished 
                              ? 'Finished ($seenCount episodes)' 
                              : '$seenCount / ${item.numberOfEpisodes ?? "?"} episodes seen',
                          style: TextStyle(
                            color: isFinished ? Colors.blue : Colors.green, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (!isTv && isSeen)
                        const Text(
                          'Seen',
                          style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: () => provider.toggleWatchlist(item),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const SearchBottomBar(),
    );
  }
}

class SearchBottomBar extends StatefulWidget {
  const SearchBottomBar({super.key});

  @override
  State<SearchBottomBar> createState() => _SearchBottomBarState();
}

class _SearchBottomBarState extends State<SearchBottomBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  late int _lastResetCount;

  @override
  void initState() {
    super.initState();
    _lastResetCount = Provider.of<SearchProvider>(context, listen: false).resetCount;
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, SearchProvider provider) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      provider.searchMedia(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);
    
    // Check if a reset was requested from MainPage
    if (provider.resetCount > _lastResetCount) {
      _lastResetCount = provider.resetCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
        }
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search names...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
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
            ],
          ),
        ),
      ),
    );
  }
}
