import 'package:injectable/injectable.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/core/domain/entities/movie_details.dart';
import 'package:mediavore/features/movie_details/data/datasources/watchlist_local_data_source.dart';
import 'package:mediavore/features/search/data/datasources/movie_remote_data_source.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';

/// Implementation of the [MovieRepository] that uses a remote and a local data source.
@LazySingleton(as: MovieRepository)
class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;
  final WatchlistLocalDataSource localDataSource;

  /// Creates a new instance of [MovieRepositoryImpl].
  ///
  /// Requires a [remoteDataSource] to fetch movie data from the network,
  /// and a [localDataSource] to manage the watchlist.
  MovieRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Movie>> searchMovies(String query) async {
    return remoteDataSource.searchMovies(query);
  }

  @override
  Future<MovieDetails> getMovieDetails(int movieId) async {
    // Fetch both the movie details and the credits in parallel.
    final movieFuture = remoteDataSource.getMovie(movieId);
    final creditsFuture = remoteDataSource.getMovieCredits(movieId);

    final movie = await movieFuture;
    final credits = await creditsFuture;

    final List castResults = credits['cast'];
    final List crewResults = credits['crew'];

    final List<CastMember> cast =
        castResults.map((c) => CastMember.fromJson(c)).toList();
    
    final CrewMember director = crewResults
        .map((c) => CrewMember.fromJson(c))
        .firstWhere((member) => member.job == 'Director', orElse: () => CrewMember(name: 'N/A', job: 'Director'));

    return MovieDetails(
      movie: movie,
      cast: cast,
      director: director,
    );
  }

  @override
  Future<void> addMovieToWatchlist(int id) {
    return localDataSource.addMovie(id);
  }

  @override
  Future<List<int>> getWatchlistMovieIds() {
    return localDataSource.getWatchlistMovieIds();
  }

  @override
  Future<bool> isMovieInWatchlist(int id) async {
    final watchlistIds = await localDataSource.getWatchlistMovieIds();
    return watchlistIds.contains(id);
  }

  @override
  Future<void> removeMovieFromWatchlist(int id) {
    return localDataSource.removeMovie(id);
  }
}
