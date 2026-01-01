import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/features/movie_details/presentation/pages/movie_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';

class SavedMoviesPage extends StatefulWidget {
  const SavedMoviesPage({super.key});

  @override
  State<SavedMoviesPage> createState() => _SavedMoviesPageState();
}

class _SavedMoviesPageState extends State<SavedMoviesPage> {
  late final MovieRepository _movieRepository;
  Future<List<Movie>>? _savedMoviesFuture;

  @override
  void initState() {
    super.initState();
    _movieRepository = locator<MovieRepository>();
    _loadSavedMovies();
  }

  Future<void> _loadSavedMovies() async {
    setState(() {
      _savedMoviesFuture = _fetchSavedMovies();
    });
  }

  Future<List<Movie>> _fetchSavedMovies() async {
    final ids = await _movieRepository.getWatchlistMovieIds();
    final movies = <Movie>[];
    for (final id in ids) {
      try {
        final details = await _movieRepository.getMovieDetails(id);
        movies.add(details.movie);
      } catch (e) {
        // Skip if failed to load
      }
    }
    return movies;
  }

  Future<void> _toggleWatchlist(Movie movie) async {
    try {
      await _movieRepository.removeMovieFromWatchlist(movie.id);
      _loadSavedMovies(); // Reload the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove from watchlist: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Movies'),
      ),
      body: FutureBuilder<List<Movie>>(
        future: _savedMoviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No movies saved yet.'));
          } else {
            final savedMovies = snapshot.data!;
            return ListView.builder(
              itemCount: savedMovies.length,
              itemBuilder: (context, index) {
                final movie = savedMovies[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailPage(movie: movie),
                      ),
                    );
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
                      icon: const Icon(Icons.delete),
                      onPressed: () => _toggleWatchlist(movie),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
