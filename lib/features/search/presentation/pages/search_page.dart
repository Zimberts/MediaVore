import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/features/movie_details/presentation/pages/movie_detail_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_movies_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// The main page for searching for movies.
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
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

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
                  builder: (context) => const SavedMoviesPage(),
                ),
              );
              searchProvider.loadWatchlist();
            },
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.movies.isEmpty) {
            return const Center(child: Text('Search for movies!'));
          }
          return ListView.builder(
            itemCount: provider.movies.length,
            itemBuilder: (context, index) {
              final movie = provider.movies[index];
              final isSaved = provider.watchlistIds.contains(movie.id);
              return InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailPage(movie: movie),
                    ),
                  );
                  provider.loadWatchlist();
                },
                child: ListTile(
                  leading: movie.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl:
                              'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                          width: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.movie),
                        )
                      : const Icon(Icons.movie),
                  title: Text(movie.title),
                  subtitle: Text(
                    movie.releaseDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: () => provider.toggleWatchlist(movie),
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
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
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
                    hintText: 'Search movie names...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) => searchProvider.searchMovies(value),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => searchProvider.searchMovies(_searchController.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

