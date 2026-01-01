import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/features/movie_details/presentation/pages/movie_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';
import 'package:mediavore/features/search/presentation/pages/saved_movies_page.dart';

/// The main page for searching for movies.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late final MovieRepository _movieRepository;
  List<Movie> _movies = [];
  bool _isLoading = false;
  Set<int> _watchlistIds = {};

  @override
  void initState() {
    super.initState();
    _movieRepository = locator<MovieRepository>();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    final ids = await _movieRepository.getWatchlistMovieIds();
    if (mounted) {
      setState(() {
        _watchlistIds = ids.toSet();
      });
    }
  }

  /// Searches for movies using the movie repository.
  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final movies = await _movieRepository.searchMovies(query);
      if (mounted) {
        setState(() {
          _movies = movies;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load movies: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleWatchlist(Movie movie) async {
    final isInWatchlist = _watchlistIds.contains(movie.id);
    try {
      if (isInWatchlist) {
        await _movieRepository.removeMovieFromWatchlist(movie.id);
        setState(() {
          _watchlistIds.remove(movie.id);
        });
      } else {
        await _movieRepository.addMovieToWatchlist(movie.id);
        setState(() {
          _watchlistIds.add(movie.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update watchlist: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  builder: (context) => const SavedMoviesPage(),
                ),
              );
              _loadWatchlist();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movies.isEmpty
              ? const Center(child: Text('Search for movies!'))
              : ListView.builder(
                  itemCount: _movies.length,
                  itemBuilder: (context, index) {
                    final movie = _movies[index];
                    final isSaved = _watchlistIds.contains(movie.id);
                    return InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailPage(movie: movie),
                          ),
                        );
                        _loadWatchlist();
                      },
                      child: ListTile(
                        leading: movie.posterPath != null
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                                width: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
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
                          onPressed: () => _toggleWatchlist(movie),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
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
                    onSubmitted: (value) => _searchMovies(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchMovies(_searchController.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
