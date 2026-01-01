import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/core/domain/entities/movie_details.dart';

/// Abstract class for a repository that handles movie data.
abstract class MovieRepository {
  /// Searches for movies based on a query.
  Future<List<Movie>> searchMovies(String query);

  /// Gets the details for a specific movie.
  Future<MovieDetails> getMovieDetails(int movieId);

  /// Adds a movie to the user's watchlist.
  Future<void> addMovieToWatchlist(int id);

  /// Removes a movie from the user's watchlist.
  Future<void> removeMovieFromWatchlist(int id);

  /// Gets the IDs of all movies in the user's watchlist.
  Future<List<int>> getWatchlistMovieIds();

  /// Checks if a movie is in the user's watchlist.
  Future<bool> isMovieInWatchlist(int id);
}
