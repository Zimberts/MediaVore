import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's watchlist using local storage.
@lazySingleton
class WatchlistLocalDataSource {
  final SharedPreferences _prefs;
  static const _watchlistKey = 'watchlist';

  WatchlistLocalDataSource(this._prefs);

  /// Adds an item to the watchlist with its type.
  Future<void> addToWatchlist(int id, String type) async {
    final watchlist = _prefs.getStringList(_watchlistKey) ?? [];
    final entry = '$id:$type';
    if (!watchlist.contains(entry)) {
      watchlist.add(entry);
      await _prefs.setStringList(_watchlistKey, watchlist);
    }
  }

  /// Removes an item from the watchlist.
  Future<void> removeFromWatchlist(int id, String type) async {
    final watchlist = _prefs.getStringList(_watchlistKey) ?? [];
    watchlist.remove('$id:$type');
    await _prefs.setStringList(_watchlistKey, watchlist);
  }

  /// Gets all watchlist entries as strings ("id:type").
  Future<List<String>> getWatchlistEntries() async {
    return _prefs.getStringList(_watchlistKey) ?? [];
  }
}
