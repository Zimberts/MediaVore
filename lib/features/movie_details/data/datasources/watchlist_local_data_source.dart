import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's watchlist using local storage.
@lazySingleton
class WatchlistLocalDataSource {
  final SharedPreferences _prefs;
  static const _watchlistKey = 'watchlist';

  WatchlistLocalDataSource(this._prefs);

  /// Adds a movie to the watchlist.
  Future<void> addMovie(int id) async {
    final watchlist = _prefs.getStringList(_watchlistKey) ?? [];
    if (!watchlist.contains(id.toString())) {
      watchlist.add(id.toString());
      await _prefs.setStringList(_watchlistKey, watchlist);
    }
  }

  /// Removes a movie from the watchlist.
  Future<void> removeMovie(int id) async {
    final watchlist = _prefs.getStringList(_watchlistKey) ?? [];
    watchlist.remove(id.toString());
    await _prefs.setStringList(_watchlistKey, watchlist);
  }

  /// Gets the IDs of all movies in the watchlist.
  Future<List<int>> getWatchlistMovieIds() async {
    final watchlist = _prefs.getStringList(_watchlistKey) ?? [];
    return watchlist.map(int.parse).toList();
  }
}
