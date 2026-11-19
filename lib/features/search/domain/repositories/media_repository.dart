import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/person_summary.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';

enum ImportMode { append, replace, merge }

/// Abstract class for a repository that handles media (movies and series) data.
abstract class MediaRepository {
  /// Searches for media based on a query with optional filters.
  ///
  /// Throws an [AppException] (configuration, network, server or parsing
  /// error) instead of returning an empty list when the request fails.
  Future<List<MediaItem>> searchMedia(
    String query, {
    int page = 1,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? originalLanguage,
    MediaType? type,
  });

  /// Searches for people (actors, directors, crew) via `/search/person`.
  Future<List<PersonSummary>> searchPeople(String query, {int page = 1});

  /// Discovers media using TMDb's discovery endpoint.
  ///
  /// Throws an [AppException] on failure, like [searchMedia].
  Future<List<MediaItem>> discoverMedia({
    int page = 1,
    SearchFilters? filters,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? originalLanguage,
    MediaType type = MediaType.movie,
    String sortBy = 'popularity.desc',
  });

  /// Films and series trending this week, mixed.
  ///
  /// Throws an [AppException] on failure, like [searchMedia].
  Future<List<MediaItem>> getTrendingMedia({int page = 1});

  /// Checks a TMDB credential with TMDB before it is saved.
  ///
  /// Completes when TMDB accepts [credential]; throws an [AppException]
  /// otherwise (401 [ServerException] for a rejected key).
  Future<void> validateTmdbCredential(String credential);

  /// Gets the details for a specific media item.
  Future<MediaDetails> getMediaDetails(
    int id, {
    MediaType type = MediaType.movie,
  });

  /// Gets the details for a specific actor.
  Future<ActorDetails> getActorDetails(int actorId);

  /// Adds a media item to a list.
  Future<void> addToList(MediaItem item, String listName);

  /// Atomically adds multiple media items to a list in order.
  Future<void> addAllToList(List<MediaItem> items, String listName);

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
  Future<void> markManyAsSeen(List<SeenItem> items);

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

  /// Drops TMDB data cached in a previous app language and re-fetches saved
  /// items in the current one. Safe to call when nothing changed. Returns
  /// whether the cache was dropped.
  Future<bool> applyLanguageChange();

  /// Exports all user data (seen, likes, notifications, lists) as a single MDV archive byte list.
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

  /// Watches for changes in notified items.
  Stream<void> watchNotifiedItems();

  /// Refreshes notified items from the network, series by series.
  ///
  /// Only entries missing information (no release date, or one already in the
  /// past) are reconciled, and each series is throttled to at most once per day
  /// unless [force] is set.
  Future<void> refreshNotifiedItems({bool force = false});

  /// Reconciles a single notified series/movie with the network, throttled to at
  /// most once per day unless [force] is set.
  Future<void> refreshNotificationForSeries(
    int tmdbId,
    MediaType type, {
    bool force = false,
  });

  /// Backfills missing runtime metadata for existing quick-add entries from network.
  Future<void> refreshQuickAddItems();

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

  /// Series in progress (one entry per series with a next aired episode to
  /// watch), most recent activity first. Local data only.
  Future<List<InProgressItem>> getInProgressItems();

  /// Titles of a list, in the order of the list, as known locally (cached
  /// TMDB data, else the title stored with the entry). Never reaches the
  /// network.
  Future<List<MediaItem>> getListMediaItems(String listName);

  /// QuickAdd: diagnostic list of expected next episodes that are NOT shown.
  ///
  /// Read-only; never persists. Uses runtime/cached data only unless
  /// [allowFetch] is true, in which case missing season data is fetched from
  /// the network.
  Future<List<QuickAddOmission>> getQuickAddOmissions({
    bool allowFetch = false,
  });

  /// Refreshes a Returning Series specifically for background syncing
  Future<void> refreshReturningSeries(int tmdbId);

  /// Gets the last cache update date for a specific media item.
  Future<DateTime?> getCacheUpdateDate(int tmdbId, MediaType type);

  /// Returns cached media items for the given tmdb id and type pairs.
  Future<List<MediaItem?>> getCachedMediaItems(List<(int, MediaType)> keys);

  /// Removes a quick-add entry by its isar id.
  Future<void> removeQuickAddItemById(int isarId);

  /// User opts out of automatic quick-add for a specific episode.
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

  /// QuickAdd: episodes the user removed from Quick Add, most recent first,
  /// with the title of their series as known locally. Never reaches the
  /// network.
  Future<List<QuickAddOptOut>> getQuickAddOptOuts();

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

  /// Records a user's swipe decision on a candidate movie.
  Future<void> recordSwipeDecision(SwipeDecisionModel decision);

  /// Records multiple swipe decisions atomically (e.g. for a whole saga).
  Future<void> recordSwipeDecisions(List<SwipeDecisionModel> decisions);

  /// Retrieves all recorded swipe decisions sorted latest first.
  Future<List<SwipeDecisionModel>> getSwipeDecisions();

  /// Retrieves the set of TMDB IDs that have already been decided in swipe mode.
  Future<Set<int>> getDecidedTmdbIds();

  /// Undoes the most recent swipe decision (or collection decisions).
  Future<SwipeDecisionModel?> undoLastSwipeDecision();

  /// Clears all swipe decisions from local storage.
  Future<void> clearAllSwipeDecisions();
}

class NotifiedItem {
  final int tmdbId;
  final MediaType type;
  final String title;
  final String? posterPath;
  final DateTime? releaseDate;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? runtime;
  final bool autoNotify;

  NotifiedItem({
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    this.releaseDate,
    this.seasonNumber,
    this.episodeNumber,
    this.runtime,
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
  final int? runtime;

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
    this.runtime,
  });
}

/// An episode the user removed from Quick Add: its series stays out of
/// "In progress" until the opt-out is cleared.
class QuickAddOptOut {
  final int tmdbId;
  final int? seasonNumber;
  final int? episodeNumber;
  final DateTime optedOutAt;

  /// Title of the series, or `null` when it is not known locally.
  final String? title;
  final String? posterPath;

  QuickAddOptOut({
    required this.tmdbId,
    this.seasonNumber,
    this.episodeNumber,
    required this.optedOutAt,
    this.title,
    this.posterPath,
  });
}

/// A series the viewer is in the middle of, as shown on the Home screen.
class InProgressItem {
  /// A series without any viewing for longer than this is "paused".
  static const Duration pauseAfter = Duration(days: 30);

  /// Quick Add entry of the next episode to watch (season and episode are
  /// always set).
  final QuickAddItem next;

  /// Distinct episodes seen, specials excluded.
  final int seenEpisodes;

  /// Episodes of the series, or `null` when the count is not cached.
  final int? totalEpisodes;

  /// Share of the series seen, from 0 to 1; `null` when [totalEpisodes] is
  /// unknown (no progress bar rather than a misleading 0 %).
  final double? progress;

  /// Date of the last viewing of the series.
  final DateTime lastActivity;

  /// No viewing for more than 30 days.
  final bool paused;

  InProgressItem({
    required this.next,
    required this.seenEpisodes,
    required this.totalEpisodes,
    required this.progress,
    required this.lastActivity,
    required this.paused,
  });

  int get tmdbId => next.tmdbId;
  String? get title => next.title;
  String? get posterPath => next.posterPath;
  int get seasonNumber => next.seasonNumber!;
  int get episodeNumber => next.episodeNumber!;
  int? get runtime => next.runtime;
}

/// Why an expected next episode is not present in the Quick Add list.
enum QuickAddOmissionReason {
  /// The user dismissed this episode, opting out of Quick Add for it.
  optedOut,

  /// The next episode exists but has not aired yet.
  notReleased,

  /// The next episode has no known air date.
  noAirDate,

  /// Season/episode data is not cached and fetching was not allowed.
  noCacheData,

  /// A valid aired next episode exists but is missing from Quick Add.
  notPopulated,
}

/// A diagnostic entry describing an expected Quick Add episode that is absent.
class QuickAddOmission {
  final int tmdbId;
  final String title;
  final String? posterPath;

  /// Season/episode of the next episode the omission refers to, when known.
  final int? seasonNumber;
  final int? episodeNumber;

  /// Air date of the next episode (used for [QuickAddOmissionReason.notReleased]).
  final DateTime? airDate;

  /// The seen streak (tail) this omission was computed from, when known.
  final int? tailSeason;
  final int? tailEpisode;

  final QuickAddOmissionReason reason;

  QuickAddOmission({
    required this.tmdbId,
    required this.title,
    this.posterPath,
    this.seasonNumber,
    this.episodeNumber,
    this.airDate,
    this.tailSeason,
    this.tailEpisode,
    required this.reason,
  });
}
