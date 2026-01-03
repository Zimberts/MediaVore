import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// The main page for searching for movies and series.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).loadWatchlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaVore Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedMediaPage(),
                ),
              );
              if (mounted) {
                Provider.of<SearchProvider>(context, listen: false).loadWatchlist();
              }
            },
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return const Center(child: Text('Search for movies or series!'));
          }
          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              final isSaved = provider.watchlistIds.contains(item.id);
              final isTv = item.mediaType == MediaType.tv;

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
                  leading: item.posterPath != null
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
                      : Icon(isTv ? Icons.tv : Icons.movie),
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
                  subtitle: Text(
                    item.releaseDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: const InputDecoration(
                    hintText: 'Search names...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                     Provider.of<SearchProvider>(context, listen: false).searchMedia(value);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                   Provider.of<SearchProvider>(context, listen: false).searchMedia(_searchController.text);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
