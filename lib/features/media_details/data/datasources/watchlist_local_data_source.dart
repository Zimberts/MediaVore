import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/media_details/data/models/watchlist_item.dart';

/// Manages the user's watchlist using Isar database.
/// @deprecated Use [MediaListLocalDataSource] instead.
@lazySingleton
class WatchlistLocalDataSource {
  final Isar _isar;

  WatchlistLocalDataSource(this._isar);

  /// Adds an item to the watchlist.
  Future<void> addToWatchlist(int id, String type) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.watchlistItems
          .filter()
          .idEqualTo(id)
          .typeEqualTo(type)
          .findFirst();

      if (existing == null) {
        final item = WatchlistItem(id: id, type: type);
        await _isar.watchlistItems.put(item);
      }
    });
  }

  /// Removes an item from the watchlist.
  Future<void> removeFromWatchlist(int id, String type) async {
    await _isar.writeTxn(() async {
      await _isar.watchlistItems
          .filter()
          .idEqualTo(id)
          .typeEqualTo(type)
          .deleteAll();
    });
  }

  /// Gets all watchlist entries as strings ("id:type").
  Future<List<String>> getWatchlistEntries() async {
    final items = await _isar.watchlistItems.where().findAll();
    return items.map((item) => '${item.id}:${item.type}').toList();
  }
}
