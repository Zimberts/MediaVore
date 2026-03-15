import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

enum ImportMode { append, replace, merge }

/// Abstract class for a repository that handles media (movies and series) data.
abstract class MediaRepository {
  /// Searches for media based on a query with optional filters.
  Future<List<MediaItem>> searchMedia(
    String query, {
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? language,
    MediaType? type,
  });

  /// Discovers media using TMDb's discovery endpoint.
  Future<List<MediaItem>> discoverMedia({
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? language,
    MediaType type = MediaType.movie,
    String sortBy = 'popularity.desc',
  });

  /// Gets the details for a specific media item.
  Future<MediaDetails> getMediaDetails(
    int id, {
    MediaType type = MediaType.movie,
  });

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

  /// Updates the order of items in a list.
  Future<void> updateListOrder(String listName, List<String> orderedEntries);

  /// Adds a media item to the user's watchlist.
  Future<void> addToWatchlist(MediaItem item) => addToList(item, 'watchlist');

  /// Removes a media item from the user's watchlist.
  Future<void> removeFromWatchlist(int id, MediaType type) =>
      removeFromList(id, type, 'watchlist');

  /// Gets the entries of all items in the user's watchlist (format "id:type").
  Future<List<String>> getWatchlistEntries() => getListEntries('watchlist');

  /// Checks if an item is in the user's watchlist.
  Future<bool> isInWatchlist(int id, MediaType type) =>
      isInList(id, type, 'watchlist');

  /// Gets a few items from a list for preview purposes.
  Future<List<MediaItemPreview>> getListPreviews(
    String listName, {
    int limit = 4,
  });

  /// Marks a media item (movie or episode) as seen.
  Future<void> markAsSeen(SeenItem item);

  /// Removes all seen entries for a specific media item (optionally filtered by season/episode).
  Future<void> removeFromSeen(
    int tmdbId,
    MediaType type, {
    int? seasonNumber,
    int? episodeNumber,
  });

  /// Updates an existing seen entry.
  Future<void> updateSeenEntry(SeenItem item);

  /// Deletes a specific viewing entry by its local ID.
  Future<void> deleteSeenEntry(int id);

  /// Gets all seen items.
  Future<List<SeenItem>> getSeenItems();

  /// Gets all viewing entries for a specific media item.
  Future<List<SeenItem>> getSeenStatus(int tmdbId, MediaType type);

  /// Fetches details for a specific season of a TV show.
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber);

  /// Gets the approximate size of the cache in bytes.
  Future<int> getCacheSize();

  /// Gets the approximate size of the seen database in bytes.
  Future<int> getSeenDbSize();

  /// Clears the cache. If [complete] is true, everything is deleted.
  /// If false, only non-essential items are deleted.
  Future<void> clearCache({required bool complete});

  /// Manually triggers a full cache fill (pre-caching lists and recent seen).
  Future<void> fillCache();

  /// Exports all user data (seen, likes, notifications, lists) as a single zip archive byte list.
  Future<List<int>> exportAllData();

  /// Imports an export archive produced by `exportAllData`.
  Future<void> importAllData(
    List<int> zipBytes, {
    ImportMode mode = ImportMode.append,
    Function(double progress, String status)? onProgress,
  });

  /// Likes a media item.
  Future<void> toggleLike(MediaItem item);

  /// Checks if a media item is liked.
  Future<bool> isLiked(int tmdbId, MediaType type);

  /// Gets all liked media entries (format "id:type").
  Future<List<String>> getLikedEntries();

  /// Toggles notification for a media item.
  Future<void> toggleNotification(MediaItem item, {bool autoNotify = false});

  /// Checks if a media item is notified.
  Future<bool> isNotified(int tmdbId, MediaType type);

  /// Gets all notified media entries.
  Future<List<NotifiedItem>> getNotifiedItems();

  /// Force refreshes all notified items from network.
  Future<void> refreshNotifiedItems();

  /// Gets similar media items.
  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type);

  /// Gets recommended media items.
  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type);

  /// Gets watch providers for a media item.
  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type);

  /// Gets videos (trailers, etc.) for a media item.
  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type);

  /// QuickAdd: returns current quick-add entries (next episodes the user can quickly mark seen)
  Future<List<QuickAddItem>> getQuickAddItems();

  /// Removes a quick-add entry by its isar id.
  Future<void> removeQuickAddItemById(int isarId);

  /// User opts out of automatic quick-add for a specific streak.
  /// If `seasonNumber`/`episodeNumber` are omitted, behavior defaults to opt-out for the series.
  Future<void> optOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  });

  /// Clears opt-out for a specific streak so quick-add resumes.
  Future<void> clearOptOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  });

  /// Populate quick-add collection from existing seen history.
  /// If [tmdbId] is provided, only compute quick-add for that show.
  /// If [tailSeason]/[tailEpisode] are provided, only compute for that specific tail.
  /// This will compute next unseen episodes for TV shows (that have aired)
  /// and persist quick-add entries where appropriate.
  Future<void> populateQuickAddFromSeenHistory({
    int? tmdbId,
    int? tailSeason,
    int? tailEpisode,
  });

  /// Clear all entries from the Quick Add collection.
  Future<void> clearQuickAddItems();

  /// Add a specific quick-add entry directly (used for Undo of a dismiss).
  Future<void> addQuickAddItem(QuickAddItem item);
}

class NotifiedItem {
  final int tmdbId;
  final MediaType type;
  final String title;
  final String? posterPath;
  final DateTime? releaseDate;
  final int? seasonNumber;
  final int? episodeNumber;
  final bool autoNotify;

  NotifiedItem({
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    this.releaseDate,
    this.seasonNumber,
    this.episodeNumber,
    this.autoNotify = false,
  });
}

class MediaItemPreview {
  final int id;
  final String title;
  final String? posterPath;
  final String type;

  MediaItemPreview({
    required this.id,
    required this.title,
    this.posterPath,
    required this.type,
  });
}

class QuickAddItem {
  final int? isarId;
  final int tmdbId;
  final MediaType type;
  final int? seasonNumber;
  final int? episodeNumber;
  final DateTime insertedAt;
  final DateTime? airDate;
  final String? title;
  final String? posterPath;

  QuickAddItem({
    this.isarId,
    required this.tmdbId,
    required this.type,
    this.seasonNumber,
    this.episodeNumber,
    required this.insertedAt,
    this.airDate,
    this.title,
    this.posterPath,
  });
}
