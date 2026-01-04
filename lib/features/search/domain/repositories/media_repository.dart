import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';

/// Abstract class for a repository that handles media (movies and series) data.
abstract class MediaRepository {
  /// Searches for media based on a query.
  Future<List<MediaItem>> searchMedia(String query, {int page = 1});

  /// Gets the details for a specific media item.
  Future<MediaDetails> getMediaDetails(int id, {MediaType type = MediaType.movie});

  /// Gets the details for a specific actor.
  Future<ActorDetails> getActorDetails(int actorId);

  /// Adds a media item to a list.
  Future<void> addToList(MediaItem item, String listName);

  /// Removes a media item from a list.
  Future<void> removeFromList(int id, MediaType type, String listName);

  /// Gets the entries of all items in a specific list (format "id:type").
  Future<List<String>> getListEntries(String listName);

  /// Checks if an item is in a specific list.
  Future<bool> isInList(int id, MediaType type, String listName);

  /// Gets all user-created list names.
  Future<List<String>> getAllListNames();

  /// Creates a new list.
  Future<void> createList(String name);

  /// Deletes a list and its items.
  Future<void> deleteList(String name);

  /// Adds a media item to the user's watchlist.
  Future<void> addToWatchlist(MediaItem item) => addToList(item, 'watchlist');

  /// Removes a media item from the user's watchlist.
  Future<void> removeFromWatchlist(int id, MediaType type) => removeFromList(id, type, 'watchlist');

  /// Gets the entries of all items in the user's watchlist (format "id:type").
  Future<List<String>> getWatchlistEntries() => getListEntries('watchlist');

  /// Checks if an item is in the user's watchlist.
  Future<bool> isInWatchlist(int id, MediaType type) => isInList(id, type, 'watchlist');
  
  /// Gets a few items from a list for preview purposes.
  Future<List<MediaItemPreview>> getListPreviews(String listName, {int limit = 4});
}

class MediaItemPreview {
  final int id;
  final String title;
  final String? posterPath;
  final String type;

  MediaItemPreview({required this.id, required this.title, this.posterPath, required this.type});
}
