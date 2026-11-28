import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/because_you_data.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/person_summary.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/services/background_task_service.dart';
import 'package:mediavore/core/utils/json_maps.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/utils/release_status.dart';
import 'package:mediavore/core/utils/unseen_episodes.dart';
import 'package:mediavore/features/discovery/presentation/services/because_you_service.dart';
import 'package:mediavore/features/home/presentation/providers/notification_provider.dart';
import 'package:mediavore/features/library/presentation/providers/library_provider.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_error.dart';
import 'package:mediavore/features/settings/presentation/providers/cache_admin_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:mediavore/features/home/presentation/providers/notification_provider.dart';
export 'package:mediavore/features/library/presentation/providers/library_provider.dart';
export 'package:mediavore/features/search/domain/entities/search_filters.dart';
export 'package:mediavore/features/search/presentation/providers/search_error.dart';
export 'package:mediavore/features/settings/presentation/providers/cache_admin_provider.dart';

class SearchProvider
    with ChangeNotifier
    implements CacheAdminActions, ListPreviewSource {
  final MediaRepository repository;

  /// When set, results and saved titles are reloaded on language change.
  final LocaleService? localeService;

  /// Used for daily caching of Discover recommendations.
  final SharedPreferences? prefs;

  final LibraryProvider _libraryProvider;
  final NotificationProvider _notificationProvider;
  final CacheAdminProvider _cacheAdminProvider;
  final bool _ownsLibraryProvider;
  final bool _ownsNotificationProvider;
  final bool _ownsCacheAdminProvider;

  SearchProvider(
    this.repository, {
    this.localeService,
    this.prefs,
    LibraryProvider? libraryProvider,
    NotificationProvider? notificationProvider,
    CacheAdminProvider? cacheAdminProvider,
  }) : _ownsLibraryProvider = libraryProvider == null,
       _libraryProvider = libraryProvider ?? LibraryProvider(repository),
       _ownsNotificationProvider = notificationProvider == null,
       _notificationProvider =
           notificationProvider ?? NotificationProvider(repository),
       _ownsCacheAdminProvider = cacheAdminProvider == null,
       _cacheAdminProvider =
           cacheAdminProvider ??
           CacheAdminProvider(repository, localeService: localeService) {
    _libraryProvider.addListener(_onLibraryChanged);
    _notificationProvider.addListener(notifyListeners);
    _cacheAdminProvider.addListener(notifyListeners);
    localeService?.addListener(_onLanguageChanged);
    _init();
  }

  LibraryProvider get libraryProvider => _libraryProvider;
  NotificationProvider get notificationProvider => _notificationProvider;
  CacheAdminProvider get cacheAdminProvider => _cacheAdminProvider;

  List<MediaItem> _searchResults = [];
  List<PersonSummary> _peopleResults = [];
  BecauseYouData? _becauseYouData;
  int _becauseYouRotation = 0;
  bool _isLoading = false;
  String? _error;
  SearchErrorType? _errorType;
  bool _isOffline = false;
  int _resetCount = 0;
  int _currentPage = 1;
  String _currentQuery = '';
  bool _hasMore = true;
  AppTab _selectedTab = AppTab.initial;
  LibrarySection _librarySection = LibrarySection.lists;

  // Filter states
  SearchFilters _filters = const SearchFilters();
  String? _originalLanguage;
  bool _isDiscoverMode = false;

  List<SeenItem> _seenItems = [];

  /// Viewings shown optimistically whose write is still running: a reload
  /// of the stored history keeps them (see [loadAllSeenStatus]).
  final List<SeenItem> _pendingSeen = [];

  /// Identity of one viewing: title, episode and instant.
  static String _seenEntryKey(SeenItem item) =>
      '${item.tmdbId}:${item.type.name}:${item.seasonNumber}:'
      '${item.episodeNumber}:${item.seenDate.millisecondsSinceEpoch}';
  Map<String, int> _seenCounts = {}; // "id:type" -> count
  List<QuickAddItem> _quickAddItems = [];
  List<InProgressItem> _inProgressItems = [];
  List<MediaItem> _tonightListItems = [];
  List<QuickAddOptOut> _quickAddOptOuts = [];
  List<QuickAddOmission> _quickAddOmissions = [];
  bool _isQuickAddOmissionsLoading = false;

  List<MediaItem> get items => _searchResults; // For SearchPage
  List<PersonSummary> get peopleResults => _peopleResults;
  BecauseYouData? get becauseYouData => _becauseYouData;
  bool get isLoading => _isLoading;
  @override
  bool get isCacheLoading => _cacheAdminProvider.isCacheLoading;
  @override
  bool get isDbSizeLoading => _cacheAdminProvider.isDbSizeLoading;
  bool get isNotifiedRefreshing => _notificationProvider.isNotifiedRefreshing;
  String? get error => _error;

  /// Kind of the last search/discover failure, or `null` if it succeeded.
  SearchErrorType? get errorType => _errorType;
  bool get isOffline => _isOffline;
  @override
  List<String> get listNames => _libraryProvider.listNames;
  Map<String, List<String>> get listEntries => _libraryProvider.listEntries;
  @override
  int get cacheSize => _cacheAdminProvider.cacheSize;
  @override
  int get seenDbSize => _cacheAdminProvider.seenDbSize;
  int get resetCount => _resetCount;
  bool get hasMore => _hasMore;
  List<String> get watchlistIds => _libraryProvider.watchlistIds;
  List<SeenItem> get seenItems => _seenItems;
  List<String> get likedIds => _libraryProvider.likedIds;
  List<NotifiedItem> get notifiedItems => _notificationProvider.notifiedItems;
  List<QuickAddItem> get quickAddItems => _quickAddItems;

  /// Series in progress, most recent activity first (Home screen).
  List<InProgressItem> get inProgressItems => _inProgressItems;

  /// First list: the one a title is added to in one tap from its detail
  /// page.
  String get firstListName => _libraryProvider.firstListName;

  /// List the "Tonight" picks of the Home screen come from: the first one.
  String get tonightListName => _libraryProvider.tonightListName;

  /// Titles of [tonightListName] that are neither seen nor started and are
  /// already out on [now] (default: today), in the order of the list.
  List<MediaItem> tonightCandidates([DateTime? now]) {
    final day = now ?? DateTime.now();
    return [
      for (final item in _tonightListItems)
        if (getSeenCount(item) == 0 && isReleased(item, day)) item,
    ];
  }

  /// Episodes removed from Quick Add, most recent first.
  List<QuickAddOptOut> get quickAddOptOuts => _quickAddOptOuts;
  List<QuickAddOmission> get quickAddOmissions => _quickAddOmissions;
  bool get isQuickAddOmissionsLoading => _isQuickAddOmissionsLoading;
  AppTab get selectedTab => _selectedTab;
  LibrarySection get librarySection => _librarySection;

  @override
  double get importProgress => _cacheAdminProvider.importProgress;
  @override
  String get importStatus => _cacheAdminProvider.importStatus;
  @override
  bool get isImporting => _cacheAdminProvider.isImporting;

  // Filter getters
  SearchFilters get filters => _filters;
  List<int>? get genreIds =>
      _filters.genreIds.isEmpty ? null : _filters.genreIds.toList();
  int? get releaseYear => _filters.exactYear;
  double? get minRating => _filters.minRating;
  String? get originalLanguage => _originalLanguage;
  MediaType? get filterType => _filters.type;
  bool get isDiscoverMode => _isDiscoverMode;
  String get currentQuery => _currentQuery;

  /// Whether a filter of Discover (type, genres, year, rating, language) is
  /// set.
  bool get hasActiveFilters =>
      _filters.hasActiveFilters || _originalLanguage != null;

  /// Whether the list shows the trends of the week: no query and no filter.
  bool get isTrending => _currentQuery.isEmpty && !hasActiveFilters;
  Future<void> _init() async {
    await loadAllSeenStatus();
    await loadQuickAddItems();
    await _loadTonightListItems();
    await loadBecauseYouRecommendations();
  }

  @override
  void dispose() {
    _libraryProvider.removeListener(_onLibraryChanged);
    _notificationProvider.removeListener(notifyListeners);
    _cacheAdminProvider.removeListener(notifyListeners);
    localeService?.removeListener(_onLanguageChanged);
    if (_ownsLibraryProvider) _libraryProvider.dispose();
    if (_ownsNotificationProvider) _notificationProvider.dispose();
    if (_ownsCacheAdminProvider) _cacheAdminProvider.dispose();
    super.dispose();
  }

  void _onLibraryChanged() {
    notifyListeners();
    unawaited(_loadTonightListItems());
  }

  void _onLanguageChanged() => unawaited(reloadForLanguageChange());

  int _tmdbLanguageRevision = 0;

  /// Bumped once the TMDB cache of the previous language is dropped; pages
  /// that hold TMDB data reload when it changes.
  int get tmdbLanguageRevision => _tmdbLanguageRevision;

  /// Re-fetches TMDB-sourced titles in the current app language.
  Future<void> reloadForLanguageChange() async {
    if (!await repository.applyLanguageChange()) return;
    _tmdbLanguageRevision++;
    await _reloadSavedTitles();
    if (_searchResults.isNotEmpty || _isDiscoverMode) {
      await searchMedia(_currentQuery);
    }
    // Saved titles come from the cache, refilled by the warm-up that the
    // language change started: reload them once it is done.
    await repository.fillCache();
    await _reloadSavedTitles();
  }

  Future<void> reloadSavedTitles() => _reloadSavedTitles();

  Future<void> _reloadSavedTitles() async {
    await _libraryProvider.init();
    await loadAllSeenStatus();
    await _notificationProvider.loadNotifiedItems();
    await loadQuickAddItems();
    await _loadTonightListItems(notify: false);
  }

  void setSelectedTab(AppTab tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  void setLibrarySection(LibrarySection section) {
    if (_librarySection != section) {
      _librarySection = section;
      notifyListeners();
    }
  }

  /// Opens the Library tab on [section].
  void openLibrary(LibrarySection section) {
    if (_selectedTab == AppTab.library && _librarySection == section) return;
    _selectedTab = AppTab.library;
    _librarySection = section;
    notifyListeners();
  }

  @override
  Future<void> updateCacheSize() => _cacheAdminProvider.updateCacheSize();
  @override
  Future<void> updateSeenDbSize() => _cacheAdminProvider.updateSeenDbSize();
  @override
  Future<void> clearCache({required bool complete}) =>
      _cacheAdminProvider.clearCache(complete: complete);
  @override
  Future<void> fillCache() => _cacheAdminProvider.fillCache();
  @override
  ValueListenable<CacheWarmupProgress?> get cacheWarmupProgress =>
      _cacheAdminProvider.cacheWarmupProgress;
  @override
  void cancelCacheFill() => _cacheAdminProvider.cancelCacheFill();

  /// Reloads the titles behind [tonightCandidates]. Never throws: the Home
  /// screen then simply has no pick to offer.
  Future<void> _loadTonightListItems({bool notify = true}) async {
    try {
      _tonightListItems = await repository.getListMediaItems(tonightListName);
    } catch (e) {
      debugPrint('[SearchProvider] loadTonightListItems error: $e');
      _tonightListItems = [];
    }
    if (notify) notifyListeners();
  }

  Future<void> loadListNames() => _libraryProvider.loadListNames();
  Future<void> loadWatchlist() => _libraryProvider.loadWatchlist();
  Future<void> loadLikedStatus() => _libraryProvider.loadLikedStatus();

  Future<void> loadAllSeenStatus() async {
    final stored = await repository.getSeenItems();
    // A pending viewing already stored (its write ended just before this
    // read) is listed once, from the database.
    final storedKeys = stored.map(_seenEntryKey).toSet();
    _seenItems = [
      ..._pendingSeen.reversed.where(
        (item) => !storedKeys.contains(_seenEntryKey(item)),
      ),
      ...stored,
    ];
    final Map<String, int> counts = {};

    final Map<String, List<SeenItem>> grouped = {};
    for (final item in _seenItems) {
      final key = '${item.tmdbId}:${item.type.name}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    grouped.forEach((key, items) {
      if (items.first.type == MediaType.movie) {
        counts[key] = items.length;
      } else {
        counts[key] = items
            .where((i) => i.seasonNumber != null && i.episodeNumber != null)
            .map((i) => '${i.seasonNumber}:${i.episodeNumber}')
            .toSet()
            .length;
      }
    });

    _seenCounts = counts;
    notifyListeners();
    await loadQuickAddItems();
  }

  /// Returns a map of cached [MediaItem]s for all seen items, keyed by tmdbId.
  Future<Map<int, MediaItem>> getCachedSeenMediaItems() async {
    final distinctKeys = _seenItems
        .map((s) => (s.tmdbId, s.type))
        .toSet()
        .toList();
    final items = await repository.getCachedMediaItems(distinctKeys);
    final map = <int, MediaItem>{};
    for (final item in items) {
      if (item != null) {
        map[item.id] = item;
      }
    }
    return map;
  }

  Future<void> loadNotifiedItems() => _notificationProvider.loadNotifiedItems();

  Future<void> loadQuickAddItems() async {
    try {
      final repoItems = await repository.getQuickAddItems();
      _quickAddItems = repoItems;
    } catch (e) {
      debugPrint('[SearchProvider] getQuickAddItems error: $e');
      _quickAddItems = [];
    }
    try {
      _inProgressItems = await repository.getInProgressItems();
    } catch (e) {
      debugPrint('[SearchProvider] getInProgressItems error: $e');
      _inProgressItems = [];
    }
    try {
      _quickAddOptOuts = await repository.getQuickAddOptOuts();
    } catch (e) {
      debugPrint('[SearchProvider] getQuickAddOptOuts error: $e');
      _quickAddOptOuts = [];
    }
    notifyListeners();
  }

  /// Loads the Quick Add diagnostics (why expected episodes are missing).
  ///
  /// Cache/runtime only by default; set [allowFetch] to permit fetching missing
  /// season data from the network. Never throws.
  Future<void> loadQuickAddOmissions({bool allowFetch = false}) async {
    _isQuickAddOmissionsLoading = true;
    notifyListeners();
    try {
      _quickAddOmissions = await repository.getQuickAddOmissions(
        allowFetch: allowFetch,
      );
    } catch (e) {
      debugPrint('[SearchProvider] loadQuickAddOmissions error: $e');
      _quickAddOmissions = [];
    } finally {
      _isQuickAddOmissionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearQuickAddItems() async {
    await repository.clearQuickAddItems();
    await loadQuickAddItems();
  }

  List<String> getListEntriesCached(String listName) =>
      _libraryProvider.getListEntriesCached(listName);

  int getSeenCount(MediaItem item) {
    return _seenCounts['${item.id}:${item.mediaType.name}'] ?? 0;
  }

  bool isItemSeenOrInAnyList(int id, MediaType type) {
    final entry = '$id:${type.name}';
    if ((_seenCounts[entry] ?? 0) > 0) return true;
    for (final list in _libraryProvider.listEntries.values) {
      if (list.contains(entry)) return true;
    }
    return false;
  }

  /// Loads personalized recommendations for the "Because you..." row in Discover.
  Future<void> loadBecauseYouRecommendations({
    bool forceRefresh = false,
  }) async {
    if (_isOffline) {
      _becauseYouData = null;
      notifyListeners();
      return;
    }

    try {
      if (!forceRefresh && prefs != null) {
        final cached = await BecauseYouService.loadCached(
          prefs: prefs!,
          now: DateTime.now(),
          isSeenOrInList: isItemSeenOrInAnyList,
        );
        if (cached != null) {
          _becauseYouData = cached;
          notifyListeners();
          return;
        }
      }

      final likedItems = await repository.getLikedItems();
      final candidates = BecauseYouService.selectCandidates(
        likedItems: likedItems,
        seenItems: _seenItems,
        inProgressItems: _inProgressItems,
      );

      if (candidates.isEmpty) {
        _becauseYouData = null;
        notifyListeners();
        return;
      }

      final startIndex = _becauseYouRotation++;
      BecauseYouData? result;

      for (var i = 0; i < candidates.length; i++) {
        final candidate = candidates[(startIndex + i) % candidates.length];
        try {
          final recs = await repository.getRecommendedMedia(
            candidate.id,
            candidate.type,
          );
          final filtered = BecauseYouService.filterRecommendations(
            recs,
            isSeenOrInList: isItemSeenOrInAnyList,
          );
          if (filtered.length >= 3) {
            result = BecauseYouData(
              sourceId: candidate.id,
              sourceType: candidate.type,
              sourceTitle: candidate.title,
              reason: candidate.reason,
              items: filtered,
            );
            break;
          }
        } catch (e) {
          debugPrint('[SearchProvider] getRecommendedMedia error: $e');
        }
      }

      _becauseYouData = result;
      if (result != null && prefs != null) {
        await BecauseYouService.saveCached(
          prefs: prefs!,
          now: DateTime.now(),
          data: result,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[SearchProvider] loadBecauseYouRecommendations error: $e');
      _becauseYouData = null;
    }
  }

  bool isItemInList(MediaItem item, String listName) =>
      _libraryProvider.isItemInList(item, listName);

  bool isLiked(MediaItem item) => _libraryProvider.isLiked(item);

  bool isNotified(MediaItem item) => _notificationProvider.isNotified(item);

  Future<void> toggleLike(MediaItem item) => _libraryProvider.toggleLike(item);

  Future<void> toggleInList(MediaItem item, String listName) async {
    await _libraryProvider.toggleInList(item, listName);
    if (listName == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
  }

  /// Adds multiple [items] to [listName] in one operation, notifying listeners once.
  Future<void> addAllToList(List<MediaItem> items, String listName) async {
    await _libraryProvider.addAllToList(items, listName);
    if (listName == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
  }

  Future<void> removeFromList(MediaItem item, String listName) async {
    await _libraryProvider.removeFromList(item, listName);
    if (listName == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
  }

  /// Moves (or copies when [keepSource] is true) [items] from [fromList] to
  /// [toList], preserving their order and skipping duplicates in [toList].
  Future<void> moveItems(
    List<MediaItem> items,
    String fromList,
    String toList, {
    bool keepSource = false,
  }) async {
    await _libraryProvider.moveItems(
      items,
      fromList,
      toList,
      keepSource: keepSource,
    );
    if (fromList == tonightListName || toList == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
  }

  Future<void> toggleWatchlist(MediaItem item) =>
      _libraryProvider.toggleWatchlist(item);

  Future<void> toggleNotification(MediaItem item) =>
      _notificationProvider.toggleNotification(item);

  Future<void> createList(String name) => _libraryProvider.createList(name);

  Future<void> deleteList(String name) async {
    await _libraryProvider.deleteList(name);
    await _loadTonightListItems(notify: false);
  }

  Future<void> updateListOrder(
    String listName,
    List<String> orderedEntries,
  ) async {
    await _libraryProvider.updateListOrder(listName, orderedEntries);
    if (listName == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
  }

  String getShareLinkForList(String listName) =>
      _libraryProvider.getShareLinkForList(listName);

  String getCustomSchemeShareLinkForList(String listName) =>
      _libraryProvider.getCustomSchemeShareLinkForList(listName);

  Future<void> importSharedEntries(
    String name,
    List<SharedMediaEntry> entries,
  ) async {
    await _libraryProvider.importSharedEntries(name, entries);
    if (name == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
  }

  Future<void> importList(String name, List<String> entries) async {
    await _libraryProvider.importList(name, entries);
    if (name == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
  }

  /// Maximum number of TMDB pages to fetch in a single search/filter batch.
  static const int maxSearchPagesBatch = 5;

  /// Target number of filtered items per batch to fill the screen.
  static const int targetItemsPerBatch = 20;

  void setFilters({
    SearchFilters? filters,
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? originalLanguage,
    MediaType? type,
    SearchReleasePeriod? period,
    SearchSort? sort,
    MovieDuration? duration,
    bool? hideSeen,
  }) {
    if (filters != null) {
      _filters = filters;
    } else {
      _filters = _filters.copyWith(
        type: type != null ? () => type : null,
        genreIds: genreIds?.toSet(),
        exactYear: releaseYear != null ? () => releaseYear : null,
        minRating: minRating != null ? () => minRating : null,
        period: period,
        sort: sort,
        duration: duration,
        hideSeen: hideSeen,
      );
    }
    if (originalLanguage != null) {
      _originalLanguage = originalLanguage;
    }
    notifyListeners();
  }

  void clearFilters() {
    _filters = const SearchFilters();
    _originalLanguage = null;
    notifyListeners();
  }

  /// Checks [credential] with TMDB without saving it.
  ///
  /// Returns `null` when TMDB accepts it, otherwise why it failed
  /// ([SearchErrorType.invalidApiKey] for a rejected key).
  Future<SearchErrorType?> validateTmdbCredential(String credential) async {
    try {
      await repository.validateTmdbCredential(credential);
      return null;
    } catch (e) {
      // Log the type only: the error may carry the request URL (v3 key).
      debugPrint(
        '[SearchProvider] TMDB credential check failed: ${e.runtimeType}',
      );
      return classifySearchError(e);
    }
  }

  Future<void> searchMedia(String query) async {
    final normalizedQuery = query.trim();
    _currentQuery = normalizedQuery;
    if (normalizedQuery.isEmpty && !_isDiscoverMode) {
      _isDiscoverMode = true;
    } else if (normalizedQuery.isNotEmpty) {
      _isDiscoverMode = false;
    }

    _isLoading = true;
    _clearSearchError();
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      if (isTrending) {
        _peopleResults = [];
        // Copy: [fetchNextPage] appends to [_searchResults], so it must not
        // alias a list the repository may return fixed-length.
        _searchResults = List<MediaItem>.of(
          await repository.getTrendingMedia(page: _currentPage),
        );
      } else if (_isDiscoverMode && _currentQuery.isEmpty) {
        _peopleResults = [];
        final List<MediaItem> rawResults;
        if (_filters.type == null) {
          final movies = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  originalLanguage: _originalLanguage,
                )
              : await repository.discoverMedia(
                  page: _currentPage,
                  filters: _filters,
                  genreIds: _filters.genreIds.isEmpty
                      ? null
                      : _filters.genreIds.toList(),
                  releaseYear: _filters.exactYear,
                  minRating: _filters.minRating,
                  originalLanguage: _originalLanguage,
                );
          final tv = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  originalLanguage: _originalLanguage,
                  type: MediaType.tv,
                )
              : await repository.discoverMedia(
                  page: _currentPage,
                  filters: _filters,
                  genreIds: _filters.genreIds.isEmpty
                      ? null
                      : _filters.genreIds.toList(),
                  releaseYear: _filters.exactYear,
                  minRating: _filters.minRating,
                  originalLanguage: _originalLanguage,
                  type: MediaType.tv,
                );
          rawResults = [...movies, ...tv];
        } else {
          rawResults = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  originalLanguage: _originalLanguage,
                  type: _filters.type!,
                )
              : await repository.discoverMedia(
                  page: _currentPage,
                  filters: _filters,
                  genreIds: _filters.genreIds.isEmpty
                      ? null
                      : _filters.genreIds.toList(),
                  releaseYear: _filters.exactYear,
                  minRating: _filters.minRating,
                  originalLanguage: _originalLanguage,
                  type: _filters.type!,
                );
        }

        // Copy before sorting in place: [fetchNextPage] appends to
        // [_searchResults], and the repository's list may be fixed-length.
        final results = _filters.hideSeen
            ? rawResults.where((item) => getSeenCount(item) == 0).toList()
            : List<MediaItem>.of(rawResults);

        sortMediaItems(results, _filters.sort, query: _currentQuery);
        _searchResults = results;
        if (rawResults.isEmpty) _hasMore = false;
      } else {
        final peopleFuture =
            (!_filters.hasActiveFilters &&
                _currentQuery.isNotEmpty &&
                _filters.type == null)
            ? repository.searchPeople(_currentQuery).catchError((Object e) {
                debugPrint('[SearchProvider] searchPeople error: $e');
                return <PersonSummary>[];
              })
            : null;

        final collected = <MediaItem>[];
        var pagesFetched = 0;

        while (pagesFetched < maxSearchPagesBatch && _hasMore) {
          final pageToFetch = _currentPage;
          final List<MediaItem> pageResults;

          if (_filters.type == null) {
            final movies = await repository.searchMedia(
              _currentQuery,
              page: pageToFetch,
              genreIds: _filters.genreIds.isEmpty
                  ? null
                  : _filters.genreIds.toList(),
              releaseYear: _filters.exactYear,
              minRating: _filters.minRating,
              originalLanguage: _originalLanguage,
              type: MediaType.movie,
            );
            final tv = await repository.searchMedia(
              _currentQuery,
              page: pageToFetch,
              genreIds: _filters.genreIds.isEmpty
                  ? null
                  : _filters.genreIds.toList(),
              releaseYear: _filters.exactYear,
              minRating: _filters.minRating,
              originalLanguage: _originalLanguage,
              type: MediaType.tv,
            );
            pageResults = [...movies, ...tv];
            if (movies.isEmpty && tv.isEmpty) {
              _hasMore = false;
            }
          } else {
            pageResults = await repository.searchMedia(
              _currentQuery,
              page: pageToFetch,
              genreIds: _filters.genreIds.isEmpty
                  ? null
                  : _filters.genreIds.toList(),
              releaseYear: _filters.exactYear,
              minRating: _filters.minRating,
              originalLanguage: _originalLanguage,
              type: _filters.type,
            );
            if (pageResults.isEmpty) {
              _hasMore = false;
            }
          }

          pagesFetched++;

          final filtered = pageResults
              .where(
                (item) => matchesSearchFilters(
                  item,
                  _filters,
                  isSeen: (item) => getSeenCount(item) > 0,
                ),
              )
              .toList();

          collected.addAll(filtered);

          if (!_hasMore) break;
          if (!_filters.hasClientFilters) break;
          if (collected.length >= targetItemsPerBatch) break;
          _currentPage++;
        }

        if (peopleFuture != null) {
          _peopleResults = await peopleFuture;
        } else {
          _peopleResults = [];
        }

        sortMediaItems(collected, _filters.sort, query: _currentQuery);
        _searchResults = collected;
      }
      _isOffline = false;
    } catch (e) {
      _searchResults = [];
      _peopleResults = [];
      _setSearchError(e, 'searchMedia');
    } finally {
      _isLoading = false;
      await updateCacheSize();
      notifyListeners();
    }
  }

  Future<void> fetchNextPage() async {
    // While a page load is failing, don't re-trigger it on every scroll event:
    // the user retries explicitly via [retryNextPage] or a refresh.
    if (_isLoading || !_hasMore || _errorType != null) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (isTrending) {
        _currentPage++;
        final results = await repository.getTrendingMedia(page: _currentPage);
        if (results.isEmpty) {
          _hasMore = false;
        } else {
          _searchResults.addAll(results);
        }
      } else if (_isDiscoverMode && _currentQuery.isEmpty) {
        _currentPage++;
        final List<MediaItem> rawResults;
        if (_filters.type == null) {
          final movies = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  originalLanguage: _originalLanguage,
                )
              : await repository.discoverMedia(
                  page: _currentPage,
                  filters: _filters,
                  genreIds: _filters.genreIds.isEmpty
                      ? null
                      : _filters.genreIds.toList(),
                  releaseYear: _filters.exactYear,
                  minRating: _filters.minRating,
                  originalLanguage: _originalLanguage,
                );
          final tv = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  originalLanguage: _originalLanguage,
                  type: MediaType.tv,
                )
              : await repository.discoverMedia(
                  page: _currentPage,
                  filters: _filters,
                  genreIds: _filters.genreIds.isEmpty
                      ? null
                      : _filters.genreIds.toList(),
                  releaseYear: _filters.exactYear,
                  minRating: _filters.minRating,
                  originalLanguage: _originalLanguage,
                  type: MediaType.tv,
                );
          rawResults = [...movies, ...tv];
        } else {
          rawResults = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  originalLanguage: _originalLanguage,
                  type: _filters.type!,
                )
              : await repository.discoverMedia(
                  page: _currentPage,
                  filters: _filters,
                  genreIds: _filters.genreIds.isEmpty
                      ? null
                      : _filters.genreIds.toList(),
                  releaseYear: _filters.exactYear,
                  minRating: _filters.minRating,
                  originalLanguage: _originalLanguage,
                  type: _filters.type!,
                );
        }

        // Copy before sorting in place, so the repository's list is never
        // mutated.
        final filtered = _filters.hideSeen
            ? rawResults.where((item) => getSeenCount(item) == 0).toList()
            : List<MediaItem>.of(rawResults);

        sortMediaItems(filtered, _filters.sort, query: _currentQuery);

        if (rawResults.isEmpty) {
          _hasMore = false;
        } else {
          _searchResults.addAll(filtered);
        }
      } else {
        _currentPage++;
        final collected = <MediaItem>[];
        var pagesFetched = 0;

        while (pagesFetched < maxSearchPagesBatch && _hasMore) {
          final pageToFetch = _currentPage;
          final List<MediaItem> pageResults;

          if (_filters.type == null) {
            final movies = await repository.searchMedia(
              _currentQuery,
              page: pageToFetch,
              genreIds: _filters.genreIds.isEmpty
                  ? null
                  : _filters.genreIds.toList(),
              releaseYear: _filters.exactYear,
              minRating: _filters.minRating,
              originalLanguage: _originalLanguage,
              type: MediaType.movie,
            );
            final tv = await repository.searchMedia(
              _currentQuery,
              page: pageToFetch,
              genreIds: _filters.genreIds.isEmpty
                  ? null
                  : _filters.genreIds.toList(),
              releaseYear: _filters.exactYear,
              minRating: _filters.minRating,
              originalLanguage: _originalLanguage,
              type: MediaType.tv,
            );
            pageResults = [...movies, ...tv];
            if (movies.isEmpty && tv.isEmpty) {
              _hasMore = false;
            }
          } else {
            pageResults = await repository.searchMedia(
              _currentQuery,
              page: pageToFetch,
              genreIds: _filters.genreIds.isEmpty
                  ? null
                  : _filters.genreIds.toList(),
              releaseYear: _filters.exactYear,
              minRating: _filters.minRating,
              originalLanguage: _originalLanguage,
              type: _filters.type,
            );
            if (pageResults.isEmpty) {
              _hasMore = false;
            }
          }

          pagesFetched++;

          final filtered = pageResults
              .where(
                (item) => matchesSearchFilters(
                  item,
                  _filters,
                  isSeen: (item) => getSeenCount(item) > 0,
                ),
              )
              .toList();

          collected.addAll(filtered);

          if (!_hasMore) break;
          if (!_filters.hasClientFilters) break;
          if (collected.length >= targetItemsPerBatch) break;
          _currentPage++;
        }

        sortMediaItems(collected, _filters.sort, query: _currentQuery);
        _searchResults.addAll(collected);
      }
      _isOffline = false;
    } catch (e) {
      _setSearchError(e, 'fetchNextPage');
      _currentPage--;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retries the page load that failed in [fetchNextPage].
  Future<void> retryNextPage() {
    _clearSearchError();
    return fetchNextPage();
  }

  void _setSearchError(Object e, String from) {
    debugPrint('[SearchProvider] $from error: $e');
    _errorType = classifySearchError(e);
    _error = searchErrorMessage(_errorType!);
    _isOffline = _errorType == SearchErrorType.offline;
  }

  void _clearSearchError() {
    _error = null;
    _errorType = null;
  }

  void clearSearch() {
    _searchResults = [];
    _peopleResults = [];
    _currentQuery = '';
    _currentPage = 1;
    _hasMore = true;
    _clearSearchError();
    _isDiscoverMode = false;
    notifyListeners();
  }

  void requestReset() {
    clearSearch();
    _resetCount++;
    notifyListeners();
  }

  Future<MediaDetails> getMediaDetails(int id, MediaType type) =>
      repository.getMediaDetails(id, type: type);
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) =>
      repository.getSeasonDetails(tvId, seasonNumber);
  Future<List<SeenItem>> loadSeenStatusForItem(
    int tmdbId,
    MediaType type,
  ) async {
    final status = await repository.getSeenStatus(tmdbId, type);
    final inMemory = _seenItems
        .where((s) => s.tmdbId == tmdbId && s.type == type)
        .toList();
    if (inMemory.length > status.length) {
      return inMemory;
    }
    return status;
  }

  void _recordSeenItemInMemory(SeenItem item) {
    _seenItems = [item, ..._seenItems];
    final key = '${item.tmdbId}:${item.type.name}';
    if (item.type == MediaType.movie) {
      _seenCounts = Map.of(_seenCounts)..[key] = (_seenCounts[key] ?? 0) + 1;
    } else {
      final existingEpisodes = _seenItems
          .where(
            (i) =>
                i.tmdbId == item.tmdbId &&
                i.type == MediaType.tv &&
                i.seasonNumber != null &&
                i.episodeNumber != null,
          )
          .map((i) => '${i.seasonNumber}:${i.episodeNumber}')
          .toSet();
      _seenCounts = Map.of(_seenCounts)..[key] = existingEpisodes.length;
    }
  }

  void _revertSeenItemInMemory(SeenItem item) {
    _seenItems = _seenItems.where((i) => !identical(i, item)).toList();
    final key = '${item.tmdbId}:${item.type.name}';
    if (item.type == MediaType.movie) {
      final count = _seenItems
          .where((i) => i.tmdbId == item.tmdbId && i.type == MediaType.movie)
          .length;
      _seenCounts = Map.of(_seenCounts)..[key] = count;
    } else {
      final existingEpisodes = _seenItems
          .where(
            (i) =>
                i.tmdbId == item.tmdbId &&
                i.type == MediaType.tv &&
                i.seasonNumber != null &&
                i.episodeNumber != null,
          )
          .map((i) => '${i.seasonNumber}:${i.episodeNumber}')
          .toSet();
      _seenCounts = Map.of(_seenCounts)..[key] = existingEpisodes.length;
    }
  }

  void _recordManySeenItemsInMemory(List<SeenItem> items) {
    if (items.isEmpty) return;
    _seenItems = [...items.reversed, ..._seenItems];
    final newCounts = Map<String, int>.of(_seenCounts);
    final touchedKeys = items.map((i) => '${i.tmdbId}:${i.type.name}').toSet();
    for (final key in touchedKeys) {
      final parts = key.split(':');
      final tmdbId = int.parse(parts[0]);
      final typeName = parts[1];
      if (typeName == MediaType.movie.name) {
        newCounts[key] = _seenItems
            .where((i) => i.tmdbId == tmdbId && i.type == MediaType.movie)
            .length;
      } else {
        newCounts[key] = _seenItems
            .where(
              (i) =>
                  i.tmdbId == tmdbId &&
                  i.type == MediaType.tv &&
                  i.seasonNumber != null &&
                  i.episodeNumber != null,
            )
            .map((i) => '${i.seasonNumber}:${i.episodeNumber}')
            .toSet()
            .length;
      }
    }
    _seenCounts = newCounts;
  }

  void _revertManySeenItemsInMemory(List<SeenItem> items) {
    if (items.isEmpty) return;
    final itemSet = items.toSet();
    _seenItems = _seenItems.where((i) => !itemSet.contains(i)).toList();
    final newCounts = Map<String, int>.of(_seenCounts);
    final touchedKeys = items.map((i) => '${i.tmdbId}:${i.type.name}').toSet();
    for (final key in touchedKeys) {
      final parts = key.split(':');
      final tmdbId = int.parse(parts[0]);
      final typeName = parts[1];
      if (typeName == MediaType.movie.name) {
        newCounts[key] = _seenItems
            .where((i) => i.tmdbId == tmdbId && i.type == MediaType.movie)
            .length;
      } else {
        newCounts[key] = _seenItems
            .where(
              (i) =>
                  i.tmdbId == tmdbId &&
                  i.type == MediaType.tv &&
                  i.seasonNumber != null &&
                  i.episodeNumber != null,
            )
            .map((i) => '${i.seasonNumber}:${i.episodeNumber}')
            .toSet()
            .length;
      }
    }
    _seenCounts = newCounts;
  }

  Future<void> markAsSeen(SeenItem item) async {
    // Immediate optimistic update (< 100 ms) so the UI icon and counters flip
    // instantly without waiting for network or disk operations.
    _recordSeenItemInMemory(item);
    _pendingSeen.add(item);
    notifyListeners();

    try {
      await repository.markAsSeen(item);
    } catch (e) {
      _revertSeenItemInMemory(item);
      notifyListeners();
      rethrow;
    } finally {
      _pendingSeen.removeWhere((pending) => identical(pending, item));
    }

    // Swap the optimistic entry for the stored one: it carries the database
    // id (needed to edit or delete the viewing) and the runtime and genres
    // resolved from TMDB (statistics).
    await loadAllSeenStatus();
    await _postMarkAsSeen(item);
  }

  Future<void> _postMarkAsSeen(SeenItem item) async {
    // After marking as seen, remove from watchlist when appropriate so
    // that all entry points (SeenManager, Notification center, WatchNext)
    // exhibit the same behaviour.
    try {
      final inWatchlist = watchlistIds.contains(item.tmdbId.toString());

      if (inWatchlist) {
        if (item.type == MediaType.movie) {
          final mediaShell = MediaItem(
            id: item.tmdbId,
            title: item.title,
            overview: '',
            releaseDate: '',
          );
          await toggleInList(mediaShell, 'watchlist');
        } else if (item.type == MediaType.tv) {
          // Fetch details to determine status/last episode info
          try {
            final details = await repository.getMediaDetails(
              item.tmdbId,
              type: MediaType.tv,
            );
            final mediaItem = details.item;
            final discontinued =
                mediaItem.status != null &&
                {'ended', 'canceled'}.contains(mediaItem.status!.toLowerCase());

            final isLastEpisode =
                item.seasonNumber != null &&
                item.episodeNumber != null &&
                mediaItem.lastSeasonNumber != null &&
                mediaItem.lastEpisodeNumber != null &&
                mediaItem.lastSeasonNumber == item.seasonNumber &&
                mediaItem.lastEpisodeNumber == item.episodeNumber;

            // Trigger background sync if they just watched the last episode of a returning series
            // and the cache is older than 2 days.
            if (isLastEpisode &&
                mediaItem.status != null &&
                mediaItem.status!.toLowerCase() == 'returning series') {
              final cacheDate = await repository.getCacheUpdateDate(
                item.tmdbId,
                MediaType.tv,
              );
              if (cacheDate == null ||
                  DateTime.now().difference(cacheDate).inDays >= 2) {
                try {
                  BackgroundTaskService.dispatchOneOffRefresh(item.tmdbId);
                } catch (e) {
                  debugPrint('Failed to dispatch background task: $e');
                }
              }
            }

            bool noNext = false;
            if (discontinued && !isLastEpisode) {
              try {
                final next = await getNextEpisode(item.tmdbId);
                if (next == null) noNext = true;
              } catch (e) {
                debugPrint(
                  '[SearchProvider] markAsSeen getNextEpisode failed: $e',
                );
              }
            }

            if ((isLastEpisode || noNext) && discontinued) {
              await toggleInList(mediaItem, 'watchlist');
            }

            // If a rewatch was in progress and all episodes have been seen in this cycle,
            // clear the active rewatch cycle.
            final rewatchStart = getSeriesRewatchStart(item.tmdbId);
            if (rewatchStart != null) {
              final allSeen = await repository.getSeenStatus(
                item.tmdbId,
                MediaType.tv,
              );
              final details = await repository.getMediaDetails(
                item.tmdbId,
                type: MediaType.tv,
              );
              final total = details.item.numberOfEpisodes ?? 0;
              final inCycle = allSeen
                  .where(
                    (s) =>
                        !s.seenDate.isBefore(rewatchStart) &&
                        s.seasonNumber != null &&
                        s.episodeNumber != null &&
                        s.seasonNumber! > 0,
                  )
                  .map((s) => '${s.seasonNumber}:${s.episodeNumber}')
                  .toSet()
                  .length;
              if (total > 0 && inCycle >= total) {
                await repository.clearSeriesRewatchStart(item.tmdbId);
                await prefs?.remove('series_rewatch_start_${item.tmdbId}');
              }
            }
          } catch (e) {
            debugPrint(
              '[SearchProvider] markAsSeen watchlist cleanup failed: $e',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[SearchProvider] markAsSeen post-processing failed: $e');
    }

    await loadNotifiedItems();
    await updateSeenDbSize();
    await loadQuickAddItems();
  }

  Future<void> markManyAsSeen(List<SeenItem> items) async {
    if (items.isEmpty) return;
    _recordManySeenItemsInMemory(items);
    _pendingSeen.addAll(items);
    notifyListeners();

    try {
      await repository.markManyAsSeen(items);
    } catch (e) {
      _revertManySeenItemsInMemory(items);
      notifyListeners();
      rethrow;
    } finally {
      _pendingSeen.removeWhere(
        (pending) => items.any((item) => identical(item, pending)),
      );
    }

    // Stored entries replace the optimistic ones (see [markAsSeen]); the
    // reload also refreshes Quick Add.
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
  }

  /// Finds anterior unseen episodes for a series before [targetSeason] / [targetEpisode].
  Future<List<CandidateEpisode>> getPreviousUnseenEpisodes({
    required int tvId,
    required int targetSeason,
    required int targetEpisode,
  }) async {
    try {
      final details = await repository.getMediaDetails(
        tvId,
        type: MediaType.tv,
      );
      final seasons = details.item.seasons ?? [];

      final seasonsToPrefetch = seasons
          .map((s) => s.seasonNumber)
          .where((n) => n > 0 && n <= targetSeason)
          .toList();
      if (seasonsToPrefetch.isNotEmpty) {
        try {
          await repository.prefetchSeasons(tvId, seasonsToPrefetch);
        } catch (_) {}
      }

      final allCandidates = <CandidateEpisode>[];
      for (final s in seasons) {
        if (s.seasonNumber <= 0 || s.seasonNumber > targetSeason) continue;
        try {
          final sDetails = await repository.getSeasonDetails(
            tvId,
            s.seasonNumber,
          );
          final episodes = sDetails['episodes'] as List? ?? [];
          for (final ep in episodes) {
            if (ep is Map<String, dynamic>) {
              allCandidates.add(
                CandidateEpisode(
                  seasonNumber: s.seasonNumber,
                  episodeNumber: ep['episode_number'] as int? ?? 0,
                  name: ep['name'] as String?,
                  runtime: ep['runtime'] as int?,
                  airDate: ep['air_date'] as String?,
                ),
              );
            }
          }
        } catch (_) {}
      }

      final seenKeys = _seenItems
          .where(
            (s) =>
                s.tmdbId == tvId &&
                s.type == MediaType.tv &&
                s.seasonNumber != null &&
                s.episodeNumber != null,
          )
          .map((s) => '${s.seasonNumber}:${s.episodeNumber}')
          .toSet();

      return findPreviousUnseenEpisodes(
        targetSeason: targetSeason,
        targetEpisode: targetEpisode,
        allEpisodes: allCandidates,
        seenEpisodeKeys: seenKeys,
      );
    } catch (e) {
      debugPrint('[SearchProvider] getPreviousUnseenEpisodes failed: $e');
      return [];
    }
  }

  /// Whether two dates are the same once stored (the database keeps
  /// microseconds at best).
  static bool _sameInstant(DateTime a, DateTime b) =>
      a.difference(b).abs() < const Duration(milliseconds: 1);

  /// Marks the next episode of [item] as seen through [markAsSeen] and
  /// returns the action that undoes it: the viewing just logged is deleted
  /// (older viewings of the same episode are kept), the Quick Add queue goes
  /// back to that episode and the series returns to the watchlist if marking
  /// it had removed it.
  Future<Future<void> Function()> markNextEpisodeSeen(
    InProgressItem item,
  ) async {
    final next = item.next;
    final seenDate = DateTime.now();
    final wasInWatchlist = watchlistIds.contains('${next.tmdbId}');

    await markAsSeen(
      SeenItem(
        tmdbId: next.tmdbId,
        type: next.type,
        title: next.title ?? '',
        posterPath: next.posterPath,
        seenDate: seenDate,
        seasonNumber: next.seasonNumber,
        episodeNumber: next.episodeNumber,
        runtime: next.runtime,
      ),
    );

    return () async {
      final viewings = await repository.getSeenStatus(next.tmdbId, next.type);
      for (final viewing in viewings) {
        final id = viewing.id;
        if (id != null &&
            viewing.seasonNumber == next.seasonNumber &&
            viewing.episodeNumber == next.episodeNumber &&
            _sameInstant(viewing.seenDate, seenDate)) {
          await repository.deleteSeenEntry(id);
        }
      }

      // Drop the episode queued by this viewing, then put the one that was
      // marked back in the queue.
      for (final queued in await repository.getQuickAddItems()) {
        final id = queued.isarId;
        if (id != null &&
            queued.tmdbId == next.tmdbId &&
            _sameInstant(queued.insertedAt, seenDate)) {
          await repository.removeQuickAddItemById(id);
        }
      }
      await repository.addQuickAddItem(next);

      if (wasInWatchlist && !watchlistIds.contains('${next.tmdbId}')) {
        try {
          final details = await repository.getMediaDetails(
            next.tmdbId,
            type: next.type,
          );
          await toggleInList(details.item, 'watchlist');
        } catch (e) {
          debugPrint('[SearchProvider] undo watchlist restore failed: $e');
        }
      }

      await loadAllSeenStatus();
      await loadNotifiedItems();
      await updateSeenDbSize();
    };
  }

  /// Marks [item] as seen through [markAsSeen] and returns the action that
  /// undoes it: the viewing just logged is deleted, Quick Add is refreshed
  /// and the title returns to the watchlist if marking it had removed it.
  Future<Future<void> Function()> markItemSeen(SeenItem item) async {
    final seenDate = item.seenDate;
    final wasInWatchlist = watchlistIds.contains('${item.tmdbId}');
    final isEpisode = item.type == MediaType.tv;

    await markAsSeen(item);

    return () async {
      final viewings = await repository.getSeenStatus(item.tmdbId, item.type);
      for (final viewing in viewings) {
        final id = viewing.id;
        if (id != null &&
            viewing.seasonNumber == item.seasonNumber &&
            viewing.episodeNumber == item.episodeNumber &&
            _sameInstant(viewing.seenDate, seenDate)) {
          await repository.deleteSeenEntry(id);
        }
      }

      if (isEpisode) {
        for (final queued in await repository.getQuickAddItems()) {
          final id = queued.isarId;
          if (id != null &&
              queued.tmdbId == item.tmdbId &&
              _sameInstant(queued.insertedAt, seenDate)) {
            await repository.removeQuickAddItemById(id);
          }
        }
        await repository.populateQuickAddFromSeenHistory(tmdbId: item.tmdbId);
      }

      if (wasInWatchlist && !watchlistIds.contains('${item.tmdbId}')) {
        try {
          final details = await repository.getMediaDetails(
            item.tmdbId,
            type: item.type,
          );
          await toggleInList(details.item, 'watchlist');
        } catch (_) {
          final fallback = MediaItem(
            id: item.tmdbId,
            title: item.title,
            overview: '',
            releaseDate: '',
            mediaType: item.type,
          );
          await toggleInList(fallback, 'watchlist');
        }
      }

      await loadAllSeenStatus();
      await loadNotifiedItems();
      await updateSeenDbSize();
      await loadQuickAddItems();
    };
  }

  /// Marks the release [item] as seen (the film, or the notified episode)
  /// through [markAsSeen] and returns the action that undoes it: the viewing
  /// just logged is deleted, the Quick Add queue is computed again and the
  /// title returns to the watchlist if marking it had removed it.
  Future<Future<void> Function()> markReleaseSeen(NotifiedItem item) async {
    final seenDate = DateTime.now();
    final wasInWatchlist = _libraryProvider.watchlistIds.contains(
      '${item.tmdbId}',
    );
    final isEpisode = item.type == MediaType.tv;

    await markAsSeen(
      SeenItem(
        tmdbId: item.tmdbId,
        type: item.type,
        title: item.title,
        posterPath: item.posterPath,
        seenDate: seenDate,
        seasonNumber: isEpisode ? item.seasonNumber : null,
        episodeNumber: isEpisode ? item.episodeNumber : null,
        runtime: item.runtime,
      ),
    );

    // Refresh the title to find the next milestone to announce.
    try {
      await repository.getMediaDetails(item.tmdbId, type: item.type);
    } catch (e) {
      debugPrint('[SearchProvider] markReleaseSeen refresh failed: $e');
    }
    await loadNotifiedItems();

    return () async {
      final viewings = await repository.getSeenStatus(item.tmdbId, item.type);
      for (final viewing in viewings) {
        final id = viewing.id;
        if (id != null && _sameInstant(viewing.seenDate, seenDate)) {
          await repository.deleteSeenEntry(id);
        }
      }

      if (isEpisode) {
        // Drop the episode queued by this viewing, then let Quick Add find
        // the next one again.
        for (final queued in await repository.getQuickAddItems()) {
          final id = queued.isarId;
          if (id != null &&
              queued.tmdbId == item.tmdbId &&
              _sameInstant(queued.insertedAt, seenDate)) {
            await repository.removeQuickAddItemById(id);
          }
        }
        await repository.populateQuickAddFromSeenHistory(tmdbId: item.tmdbId);
      }

      if (wasInWatchlist &&
          !_libraryProvider.watchlistIds.contains('${item.tmdbId}')) {
        try {
          final details = await repository.getMediaDetails(
            item.tmdbId,
            type: item.type,
          );
          await toggleInList(details.item, 'watchlist');
        } catch (e) {
          debugPrint('[SearchProvider] undo watchlist restore failed: $e');
        }
      }

      await loadAllSeenStatus();
      await loadNotifiedItems();
      await updateSeenDbSize();
    };
  }

  /// Stops following the release [item]: it leaves "Upcoming". Returns the
  /// action that follows it again, as it was (manual or automatic).
  Future<Future<void> Function()> disableReleaseAlert(NotifiedItem item) =>
      _notificationProvider.disableReleaseAlert(item);

  Future<void> deleteSeenEntry(int id) async {
    await repository.deleteSeenEntry(id);
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
    await loadQuickAddItems();
  }

  Future<void> updateSeenEntry(SeenItem item) async {
    await repository.updateSeenEntry(item);
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
    await loadQuickAddItems();
  }

  Future<void> removeFromSeen(
    int tmdbId,
    MediaType type, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await repository.removeFromSeen(
      tmdbId,
      type,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
    await loadQuickAddItems();
  }

  @override
  List<MediaItemPreview> getPreviewsForList(String name) =>
      _libraryProvider.getPreviewsForList(name);

  int getListItemCount(String name) => _libraryProvider.getListItemCount(name);

  /// Type of a list entry written as `id:type`; a movie when unspecified.
  static MediaType listEntryType(String entry) =>
      LibraryProvider.listEntryType(entry);

  /// Entries of [listName] of the given [type]; all of them when `null`.
  @override
  List<String> getListEntriesOfType(String listName, MediaType? type) =>
      _libraryProvider.getListEntriesOfType(listName, type);

  /// Number of entries of [type] across every list; all types when `null`.
  int countListEntries(MediaType? type) =>
      _libraryProvider.countListEntries(type);

  /// First [limit] previews of [listName] of the given [type], in the order
  /// of the list. Reads only as far into the list as needed.
  @override
  Future<List<MediaItemPreview>> loadListPreviewsOfType(
    String listName,
    MediaType type, {
    int limit = 3,
  }) => _libraryProvider.loadListPreviewsOfType(listName, type, limit: limit);

  void setOffline(bool offline) {
    _isOffline = offline;
    notifyListeners();
  }

  void notifyNetworkError() {
    if (!_isOffline) {
      _isOffline = true;
      notifyListeners();
    }
  }

  Future<void> loadLists() => loadListNames();

  @override
  Future<List<int>> exportAllData() => _cacheAdminProvider.exportAllData();

  @override
  Future<void> importAllData(
    List<int> zipBytes, {
    ImportMode mode = ImportMode.append,
  }) async {
    await _cacheAdminProvider.importAllData(
      zipBytes,
      mode: mode,
      onImported: _reloadAfterImport,
    );
  }

  /// Rebuilds every screen from the imported data; runs while the import is
  /// still reported in progress, so the Storage page stays busy until done.
  Future<void> _reloadAfterImport() async {
    // If quick add was not part of import, populate from seen history
    try {
      final qaItems = await repository.getQuickAddItems();
      if (qaItems.isEmpty) {
        await repository.populateQuickAddFromSeenHistory();
      }
    } catch (e) {
      debugPrint(
        '[SearchProvider] auto-populate quickadd after import failed: $e',
      );
    }
    await _reloadSavedTitles();
    // A restore on a new install starts from an empty TMDB cache, and the
    // boot warm-up (once a day) already ran on the empty library: until it
    // is refilled, Tonight has no release dates and In progress no totals.
    try {
      await repository.fillCache();
    } catch (e) {
      debugPrint('[SearchProvider] cache warm-up after import failed: $e');
    }
    await _reloadSavedTitles();
    // "Because you..." was built from the previous likes and history.
    await loadBecauseYouRecommendations(forceRefresh: true);
  }

  @override
  Future<void> refetchMissingData() async {
    await _cacheAdminProvider.refetchMissingData();
    await loadAllSeenStatus();
  }

  Future<void> optOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await repository.optOutSeries(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    await loadQuickAddItems();
  }

  Future<void> clearOptOutSeries(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await repository.clearOptOutSeries(
      tmdbId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    await loadQuickAddItems();
  }

  /// Puts a series removed from Quick Add back: clears [optOut], then
  /// computes its next episode again from the seen history.
  Future<void> restoreQuickAddOptOut(QuickAddOptOut optOut) async {
    await repository.clearOptOutSeries(
      optOut.tmdbId,
      seasonNumber: optOut.seasonNumber,
      episodeNumber: optOut.episodeNumber,
    );
    await repository.populateQuickAddFromSeenHistory(tmdbId: optOut.tmdbId);
    await loadQuickAddItems();
  }

  Future<void> populateQuickAddFromSeenHistory({
    int? tmdbId,
    int? tailSeason,
    int? tailEpisode,
  }) async {
    await repository.populateQuickAddFromSeenHistory(
      tmdbId: tmdbId,
      tailSeason: tailSeason,
      tailEpisode: tailEpisode,
    );
    await loadQuickAddItems();
  }

  Future<void> addQuickAddItem(QuickAddItem item) async {
    await repository.addQuickAddItem(item);
    await loadQuickAddItems();
  }

  Future<({int seasonNumber, int episodeNumber})?> getNextEpisode(
    int tmdbId,
  ) async {
    try {
      final seen = await repository.getSeenStatus(tmdbId, MediaType.tv);

      int nextS = 1;
      int nextE = 1;

      if (seen.isNotEmpty) {
        final rewatchStart = getSeriesRewatchStart(tmdbId);
        final filteredSeen = rewatchStart != null
            ? seen.where((s) => !s.seenDate.isBefore(rewatchStart)).toList()
            : seen;

        final episodeSeen = filteredSeen
            .where((s) => s.seasonNumber != null && s.episodeNumber != null)
            .toList();
        if (episodeSeen.isNotEmpty) {
          episodeSeen.sort((a, b) {
            final seasonCompare = b.seasonNumber!.compareTo(a.seasonNumber!);
            if (seasonCompare != 0) return seasonCompare;
            return b.episodeNumber!.compareTo(a.episodeNumber!);
          });

          final latest = episodeSeen.first;
          final details = await repository.getMediaDetails(
            tmdbId,
            type: MediaType.tv,
          );

          final seasons = details.item.seasons;
          if (seasons == null || seasons.isEmpty) return null;

          final currentSeason = seasons.firstWhere(
            (s) => s.seasonNumber == latest.seasonNumber,
            orElse: () =>
                const TVSeason(id: -1, seasonNumber: -1, episodeCount: 0),
          );

          if (currentSeason.seasonNumber != -1 &&
              latest.episodeNumber! < currentSeason.episodeCount) {
            nextS = latest.seasonNumber!;
            nextE = latest.episodeNumber! + 1;
          } else {
            final nextSeason = seasons.firstWhere(
              (s) => s.seasonNumber == latest.seasonNumber! + 1,
              orElse: () =>
                  const TVSeason(id: -1, seasonNumber: -1, episodeCount: 0),
            );

            if (nextSeason.seasonNumber != -1) {
              nextS = nextSeason.seasonNumber;
              nextE = 1;
            } else {
              return null;
            }
          }
        }
      }

      final seasonDetails = await repository.getSeasonDetails(tmdbId, nextS);
      final episodes = seasonDetails['episodes'] as List<dynamic>?;
      if (episodes == null) return null;

      final epData = jsonObjectList(
        episodes,
      ).where((e) => e['episode_number'] == nextE).firstOrNull;

      if (epData != null) {
        final airDateStr = epData['air_date'] as String?;
        if (airDateStr != null) {
          final airDate = DateTime.tryParse(airDateStr);
          if (airDate != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            if (airDate.isAfter(today)) {
              return null;
            }
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null;
      }

      return (seasonNumber: nextS, episodeNumber: nextE);
    } catch (_) {
      return null;
    }
  }

  /// Start timestamp of an active rewatch cycle for [tmdbId], or `null` if none.
  DateTime? getSeriesRewatchStart(int tmdbId) {
    return repository.getSeriesRewatchStart(tmdbId) ??
        (prefs?.getString('series_rewatch_start_$tmdbId') != null
            ? DateTime.tryParse(
                prefs!.getString('series_rewatch_start_$tmdbId')!,
              )
            : null);
  }

  /// Calculates the number of complete viewing cycles for [item] given [seen].
  static int calculateCompletedCycles(MediaItem item, Iterable<SeenItem> seen) {
    final episodeSeen = seen
        .where(
          (s) =>
              s.seasonNumber != null &&
              s.episodeNumber != null &&
              s.seasonNumber! > 0,
        )
        .toList();
    if (episodeSeen.isEmpty) return 0;

    final counts = <String, int>{};
    for (final s in episodeSeen) {
      final key = '${s.seasonNumber!}:${s.episodeNumber!}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final total = item.numberOfEpisodes ?? 0;
    if (total > 0 && counts.length < total) {
      return 0;
    }
    return counts.values.reduce(math.min);
  }

  /// Checks whether [item] (a TV series) has all episodes watched in the current cycle.
  Future<bool> isSeriesCompleted(MediaItem item) async {
    if (item.mediaType != MediaType.tv) return false;
    final seen = await repository.getSeenStatus(item.id, MediaType.tv);
    final total = item.numberOfEpisodes ?? 0;
    if (total == 0) return false;

    final rewatchStart = getSeriesRewatchStart(item.id);
    if (rewatchStart != null) {
      final inCycle = seen
          .where(
            (s) =>
                !s.seenDate.isBefore(rewatchStart) &&
                s.seasonNumber != null &&
                s.episodeNumber != null &&
                s.seasonNumber! > 0,
          )
          .map((s) => '${s.seasonNumber}:${s.episodeNumber}')
          .toSet()
          .length;
      return inCycle >= total;
    }

    final uniqueSeen = seen
        .where(
          (s) =>
              s.seasonNumber != null &&
              s.episodeNumber != null &&
              s.seasonNumber! > 0,
        )
        .map((s) => '${s.seasonNumber}:${s.episodeNumber}')
        .toSet()
        .length;
    return uniqueSeen >= total;
  }

  /// Starts a new viewing cycle for [item]. Returns the cycle number (e.g. 2 for 2nd watch).
  Future<int> startSeriesRewatch(MediaItem item) async {
    final now = DateTime.now();
    await repository.setSeriesRewatchStart(item.id, now);
    await prefs?.setString(
      'series_rewatch_start_${item.id}',
      now.toIso8601String(),
    );

    final seen = await repository.getSeenStatus(item.id, MediaType.tv);
    final completed = calculateCompletedCycles(item, seen);
    final currentCycle = (completed > 0 ? completed : 1) + 1;

    await repository.clearOptOutSeries(
      item.id,
      seasonNumber: 1,
      episodeNumber: 1,
    );

    DateTime? airDate;
    int? runtime;
    try {
      final seasonDetails = await repository.getSeasonDetails(item.id, 1);
      final ep1 = jsonObjectList(
        seasonDetails['episodes'],
      ).where((e) => e['episode_number'] == 1).firstOrNull;
      if (ep1 != null) {
        final airDateStr = ep1['air_date'] as String?;
        if (airDateStr != null) airDate = DateTime.tryParse(airDateStr);
        if (ep1['runtime'] is num) runtime = (ep1['runtime'] as num).toInt();
      }
    } catch (_) {}

    final quickAdd = QuickAddItem(
      tmdbId: item.id,
      type: MediaType.tv,
      seasonNumber: 1,
      episodeNumber: 1,
      insertedAt: now,
      airDate: airDate,
      runtime: runtime,
      title: item.title,
      posterPath: item.posterPath,
    );
    await repository.addQuickAddItem(quickAdd);
    await loadQuickAddItems();
    notifyListeners();

    return currentCycle;
  }

  /// Cancels an active rewatch for [tmdbId], restoring the completed state.
  Future<void> cancelSeriesRewatch(int tmdbId) async {
    await repository.clearSeriesRewatchStart(tmdbId);
    await prefs?.remove('series_rewatch_start_$tmdbId');

    for (final queued in await repository.getQuickAddItems()) {
      final id = queued.isarId;
      if (id != null &&
          queued.tmdbId == tmdbId &&
          queued.seasonNumber == 1 &&
          queued.episodeNumber == 1) {
        await repository.removeQuickAddItemById(id);
      }
    }
    await loadQuickAddItems();
    notifyListeners();
  }

  Future<void> refreshNotifiedItems({bool force = false}) =>
      _notificationProvider.refreshNotifiedItems(force: force);

  Future<void> refreshQuickAddItems() async {
    await repository.refreshQuickAddItems();
    await loadQuickAddItems();
  }

  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) =>
      repository.getSimilarMedia(id, type);
  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type) =>
      repository.getRecommendedMedia(id, type);
  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type) =>
      repository.getWatchProviders(id, type);
  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type) =>
      repository.getVideos(id, type);
}
