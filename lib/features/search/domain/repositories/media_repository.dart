import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';

/// Abstract class for a repository that handles media (movies and series) data.
abstract class MediaRepository {
  /// Searches for media based on a query.
  Future<List<MediaItem>> searchMedia(String query);

  /// Gets the details for a specific media item.
  Future<MediaDetails> getMediaDetails(int id, {MediaType type = MediaType.movie});

  /// Adds a media item to the user's watchlist.
  Future<void> addToWatchlist(int id, MediaType type);

  /// Removes a media item from the user's watchlist.
  Future<void> removeFromWatchlist(int id, MediaType type);

  /// Gets the entries of all items in the user's watchlist (format "id:type").
  Future<List<String>> getWatchlistEntries();

  /// Checks if an item is in the user's watchlist.
  Future<bool> isInWatchlist(int id, MediaType type);
}
