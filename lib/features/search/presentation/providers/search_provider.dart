import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';

class SearchProvider extends ChangeNotifier {
  final MovieRepository _movieRepository;

  SearchProvider(this._movieRepository);

  List<Movie> _movies = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Set<int> _watchlistIds = {};
  bool _watchlistLoaded = false;

  List<Movie> get movies => _movies;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  Set<int> get watchlistIds => _watchlistIds;

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) return;

    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      _movies = await _movieRepository.searchMovies(query);
    } catch (e) {
      // Handle error appropriately
      debugPrint('Failed to load movies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWatchlist() async {
    if (_watchlistLoaded) return;
    _watchlistLoaded = true;
    _watchlistIds = (await _movieRepository.getWatchlistMovieIds()).toSet();
    notifyListeners();
  }

  Future<void> toggleWatchlist(Movie movie) async {
    final isInWatchlist = _watchlistIds.contains(movie.id);
    try {
      if (isInWatchlist) {
        await _movieRepository.removeMovieFromWatchlist(movie.id);
        _watchlistIds.remove(movie.id);
      } else {
        await _movieRepository.addMovieToWatchlist(movie.id);
        _watchlistIds.add(movie.id);
      }
      notifyListeners();
    } catch (e) {
      // Handle error appropriately
      debugPrint('Failed to update watchlist: $e');
    }
  }
}
