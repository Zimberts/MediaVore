import 'dart:async';

import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/because_you_data.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/person_summary.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/services/background_task_service.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/utils/unseen_episodes.dart';
import 'package:mediavore/features/discovery/presentation/services/because_you_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';
import 'package:mediavore/features/search/presentation/providers/search_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:mediavore/features/search/domain/entities/search_filters.dart';
export 'package:mediavore/features/search/presentation/providers/search_error.dart';

class SearchProvider with ChangeNotifier {
  final MediaRepository repository;

  /// When set, results and saved titles are reloaded on language change.
  final LocaleService? localeService;

  /// Used for daily caching of Discover recommendations.
  final SharedPreferences? prefs;
  StreamSubscription<void>? _notifiedItemsSubscription;

  SearchProvider(this.repository, {this.localeService, this.prefs}) {
    localeService?.addListener(_onLanguageChanged);
    _init();
  }

  List<MediaItem> _searchResults = [];
  List<PersonSummary> _peopleResults = [];
  BecauseYouData? _becauseYouData;
  int _becauseYouRotation = 0;
  bool _isLoading = false;
  bool _isCacheLoading = false;
  bool _isDbSizeLoading = false;
  bool _isNotifiedRefreshing = false;
  String? _error;
  SearchErrorType? _errorType;
  bool _isOffline = false;
  List<String> _listNames = ['watchlist'];
  final Map<String, List<String>> _listEntries = {}; // listName -> ["id:type"]
  final Map<String, List<MediaItemPreview>> _listPreviews = {};
  int _cacheSize = 0;
  int _seenDbSize = 0;
  int _resetCount = 0;
  int _currentPage = 1;
  String _currentQuery = '';
  bool _hasMore = true;
  AppTab _selectedTab = AppTab.initial;
  LibrarySection _librarySection = LibrarySection.lists;

  // Progress feedback for refetching/importing
  double _importProgress = 0.0;
  String _importStatus = '';
  bool _isImporting = false;

  // Filter states
  SearchFilters _filters = const SearchFilters();
  String? _originalLanguage;
  bool _isDiscoverMode = false;

  List<SeenItem> _seenItems = [];
  Map<String, int> _seenCounts = {}; // "id:type" -> count
  List<String> _watchlistIds = []; // Simplified IDs for quick checks
  List<String> _likedIds = []; // "id:type"
  List<NotifiedItem> _notifiedItems = [];
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
  bool get isCacheLoading => _isCacheLoading;
  bool get isDbSizeLoading => _isDbSizeLoading;
  bool get isNotifiedRefreshing => _isNotifiedRefreshing;
  String? get error => _error;

  /// Kind of the last search/discover failure, or `null` if it succeeded.
  SearchErrorType? get errorType => _errorType;
  bool get isOffline => _isOffline;
  List<String> get listNames => _listNames;
  Map<String, List<String>> get listEntries => Map.unmodifiable(_listEntries);
  int get cacheSize => _cacheSize;
  int get seenDbSize => _seenDbSize;
  int get resetCount => _resetCount;
  bool get hasMore => _hasMore;
  List<String> get watchlistIds => _watchlistIds;
  List<SeenItem> get seenItems => _seenItems;
  List<String> get likedIds => _likedIds;
  List<NotifiedItem> get notifiedItems => _notifiedItems;
  List<QuickAddItem> get quickAddItems => _quickAddItems;

  /// Series in progress, most recent activity first (Home screen).
  List<InProgressItem> get inProgressItems => _inProgressItems;

  /// First list: the one a title is added to in one tap from its detail
  /// page.
  String get firstListName =>
      _listNames.isEmpty ? 'watchlist' : _listNames.first;

  /// List the "Tonight" picks of the Home screen come from: the first one.
  String get tonightListName => firstListName;

  /// Titles of [tonightListName] that are neither seen nor started, in the
  /// order of the list.
  List<MediaItem> get tonightCandidates => [
    for (final item in _tonightListItems)
      if (getSeenCount(item) == 0) item,
  ];

  /// Episodes removed from Quick Add, most recent first.
  List<QuickAddOptOut> get quickAddOptOuts => _quickAddOptOuts;
  List<QuickAddOmission> get quickAddOmissions => _quickAddOmissions;
  bool get isQuickAddOmissionsLoading => _isQuickAddOmissionsLoading;
  AppTab get selectedTab => _selectedTab;
  LibrarySection get librarySection => _librarySection;

  double get importProgress => _importProgress;
  String get importStatus => _importStatus;
  bool get isImporting => _isImporting;

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
    await loadListNames();
    await _loadAllListEntries();
    await updateCacheSize();
    await updateSeenDbSize();
    await loadAllSeenStatus();
    await loadWatchlist();
    await loadLikedStatus();
    await loadNotifiedItems();
    await loadQuickAddItems();
    await _loadTonightListItems();
    await loadBecauseYouRecommendations();

    _notifiedItemsSubscription = repository.watchNotifiedItems().listen((_) {
      loadNotifiedItems();
    });
  }

  @override
  void dispose() {
    localeService?.removeListener(_onLanguageChanged);
    _notifiedItemsSubscription?.cancel();
    super.dispose();
  }

  /// Strings for messages built outside the widget tree.
  AppLocalizations get _l10n => lookupAppLocalizations(
    (localeService?.current ?? fallbackAppLanguage).locale,
  );

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

  Future<void> _reloadSavedTitles() async {
    await _loadAllListEntries();
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await loadQuickAddItems();
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

  Future<void> updateCacheSize() async {
    _isCacheLoading = true;
    notifyListeners();
    _cacheSize = await repository.getCacheSize();
    _isCacheLoading = false;
    notifyListeners();
  }

  Future<void> updateSeenDbSize() async {
    _isDbSizeLoading = true;
    notifyListeners();
    _seenDbSize = await repository.getSeenDbSize();
    _isDbSizeLoading = false;
    notifyListeners();
  }

  Future<void> clearCache({required bool complete}) async {
    _isCacheLoading = true;
    notifyListeners();
    await repository.clearCache(complete: complete);
    await updateCacheSize();
    _isCacheLoading = false;
    notifyListeners();
  }

  Future<void> fillCache() async {
    _isCacheLoading = true;
    notifyListeners();
    await repository.fillCache();
    await updateCacheSize();
    await _loadAllListEntries();
    _isCacheLoading = false;
    notifyListeners();
  }

  Future<void> _loadAllListEntries() async {
    for (final name in _listNames) {
      _listEntries[name] = await repository.getListEntries(name);
      _listPreviews[name] = await repository.getListPreviews(name);
    }
    await _loadTonightListItems(notify: false);
    notifyListeners();
  }

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

  Future<void> loadListNames() async {
    _listNames = await repository.getAllListNames();
    notifyListeners();
  }

  Future<void> loadWatchlist() async {
    final entries = await repository.getWatchlistEntries();
    _watchlistIds = entries.map((e) => e.split(':')[0]).toList();
    _listEntries['watchlist'] = entries;
    _listPreviews['watchlist'] = await repository.getListPreviews('watchlist');
    await _loadTonightListItems(notify: false);
    notifyListeners();
  }

  Future<void> loadLikedStatus() async {
    _likedIds = await repository.getLikedEntries();
    notifyListeners();
  }

  Future<void> loadAllSeenStatus() async {
    _seenItems = await repository.getSeenItems();
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

  Future<void> loadNotifiedItems() async {
    _notifiedItems = await repository.getNotifiedItems();
    notifyListeners();
  }

  Future<void> loadQuickAddItems() async {
    final repoItems = await repository.getQuickAddItems();
    // Use repository-provided quick-add entries only (no compatibility fallback)
    _quickAddItems = repoItems;
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

  List<String> getListEntriesCached(String listName) {
    return _listEntries[listName] ?? [];
  }

  int getSeenCount(MediaItem item) {
    return _seenCounts['${item.id}:${item.mediaType.name}'] ?? 0;
  }

  bool isItemSeenOrInAnyList(int id, MediaType type) {
    final entry = '$id:${type.name}';
    if ((_seenCounts[entry] ?? 0) > 0) return true;
    for (final list in _listEntries.values) {
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

  bool isItemInList(MediaItem item, String listName) {
    final entry = '${item.id}:${item.mediaType.name}';
    return _listEntries[listName]?.contains(entry) ?? false;
  }

  bool isLiked(MediaItem item) {
    return _likedIds.contains('${item.id}:${item.mediaType.name}');
  }

  bool isNotified(MediaItem item) {
    return _notifiedItems.any(
      (n) => n.tmdbId == item.id && n.type == item.mediaType,
    );
  }

  Future<void> toggleLike(MediaItem item) async {
    await repository.toggleLike(item);
    await loadLikedStatus();
    await updateCacheSize();
  }

  Future<void> toggleInList(MediaItem item, String listName) async {
    final entry = '${item.id}:${item.mediaType.name}';
    final currentEntries = _listEntries[listName] ?? [];

    if (currentEntries.contains(entry)) {
      await repository.removeFromList(item.id, item.mediaType, listName);
      _listEntries[listName] = currentEntries.where((e) => e != entry).toList();
      if (listName == 'watchlist') {
        _watchlistIds.remove(item.id.toString());
      }
    } else {
      await repository.addToList(item, listName);
      _listEntries[listName] = [...currentEntries, entry];
      if (listName == 'watchlist') {
        _watchlistIds.add(item.id.toString());
        if (item.canBeNotified) {
          await repository.toggleNotification(item, autoNotify: true);
        }
        await loadNotifiedItems();
      }
    }
    _listPreviews[listName] = await repository.getListPreviews(listName);
    if (listName == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
    await updateCacheSize();
    notifyListeners();
  }

  /// Adds multiple [items] to [listName] in one operation, notifying listeners once.
  Future<void> addAllToList(List<MediaItem> items, String listName) async {
    if (items.isEmpty) return;
    await repository.addAllToList(items, listName);
    final currentEntries = _listEntries[listName] ?? [];
    final newEntries = items
        .map((item) => '${item.id}:${item.mediaType.name}')
        .toList();
    _listEntries[listName] = [
      ...currentEntries,
      ...newEntries.where((e) => !currentEntries.contains(e)),
    ];
    if (listName == 'watchlist') {
      for (final item in items) {
        _watchlistIds.add(item.id.toString());
      }
    }
    _listPreviews[listName] = await repository.getListPreviews(listName);
    if (listName == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
    await updateCacheSize();
    notifyListeners();
  }

  Future<void> removeFromList(MediaItem item, String listName) async {
    final entry = '${item.id}:${item.mediaType.name}';
    final currentEntries = _listEntries[listName] ?? [];

    if (currentEntries.contains(entry)) {
      await repository.removeFromList(item.id, item.mediaType, listName);
      _listEntries[listName] = currentEntries.where((e) => e != entry).toList();
      if (listName == 'watchlist') {
        _watchlistIds.remove(item.id.toString());
      }
      _listPreviews[listName] = await repository.getListPreviews(listName);
      if (listName == tonightListName) {
        await _loadTonightListItems(notify: false);
      }
      await updateCacheSize();
      notifyListeners();
    }
  }

  Future<void> toggleWatchlist(MediaItem item) async {
    await toggleInList(item, 'watchlist');
  }

  Future<void> toggleNotification(MediaItem item) async {
    await repository.toggleNotification(item);
    await loadNotifiedItems();
    notifyListeners();
  }

  Future<void> createList(String name) async {
    await repository.createList(name);
    await loadListNames();
    _listEntries[name] = await repository.getListEntries(name);
    _listPreviews[name] = await repository.getListPreviews(name);
    notifyListeners();
  }

  Future<void> deleteList(String name) async {
    await repository.deleteList(name);
    await loadListNames();
    _listEntries.remove(name);
    _listPreviews.remove(name);
    await _loadTonightListItems(notify: false);
    notifyListeners();
  }

  Future<void> updateListOrder(
    String listName,
    List<String> orderedEntries,
  ) async {
    await repository.updateListOrder(listName, orderedEntries);
    _listEntries[listName] = orderedEntries;
    _listPreviews[listName] = await repository.getListPreviews(listName);
    if (listName == tonightListName) {
      await _loadTonightListItems(notify: false);
    }
    notifyListeners();
  }

  String getShareLinkForList(String listName) {
    final entries = _listEntries[listName] ?? [];
    if (entries.isEmpty) return '';
    final sharedEntries = ListShareCodec.parseEntries(entries);
    return ListShareCodec.createShareUrl(
      listName: listName,
      entries: sharedEntries,
    );
  }

  String getCustomSchemeShareLinkForList(String listName) {
    final entries = _listEntries[listName] ?? [];
    if (entries.isEmpty) return '';
    final sharedEntries = ListShareCodec.parseEntries(entries);
    return ListShareCodec.createShareUrl(
      listName: listName,
      entries: sharedEntries,
      customScheme: true,
    );
  }

  Future<void> importSharedEntries(
    String name,
    List<SharedMediaEntry> entries,
  ) async {
    final strList = entries.map((e) => '${e.id}:${e.type.name}').toList();
    await importList(name, strList);
  }

  Future<void> importList(String name, List<String> entries) async {
    await repository.createList(name);
    await loadListNames();
    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final id = int.tryParse(parts[0]);
      final type = parts[1] == 'tv' ? MediaType.tv : MediaType.movie;
      if (id != null) {
        final shell = MediaItem(
          id: id,
          title: 'Unknown',
          overview: '',
          releaseDate: '',
          mediaType: type,
        );
        await repository.addToList(shell, name);
      }
    }
    await _loadAllListEntries();
    notifyListeners();
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
        _searchResults = await repository.getTrendingMedia(page: _currentPage);
      } else if (_isDiscoverMode && _currentQuery.isEmpty) {
        _peopleResults = [];
        final List<MediaItem> rawResults;
        if (_filters.type == null) {
          final movies = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  genreIds: null,
                  releaseYear: null,
                  minRating: null,
                  originalLanguage: _originalLanguage,
                  type: MediaType.movie,
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
                  type: MediaType.movie,
                );
          final tv = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  genreIds: null,
                  releaseYear: null,
                  minRating: null,
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
                  genreIds: null,
                  releaseYear: null,
                  minRating: null,
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

        var results = _filters.hideSeen
            ? rawResults.where((item) => getSeenCount(item) == 0).toList()
            : rawResults;

        sortMediaItems(results, _filters.sort, query: _currentQuery);
        _searchResults = results;
        if (rawResults.isEmpty) _hasMore = false;
      } else {
        final peopleFuture = (!_filters.hasActiveFilters &&
                _currentQuery.isNotEmpty &&
                _filters.type == null)
            ? repository.searchPeople(_currentQuery).catchError((e) {
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
                  genreIds: null,
                  releaseYear: null,
                  minRating: null,
                  originalLanguage: _originalLanguage,
                  type: MediaType.movie,
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
                  type: MediaType.movie,
                );
          final tv = _filters.isEmpty
              ? await repository.discoverMedia(
                  page: _currentPage,
                  genreIds: null,
                  releaseYear: null,
                  minRating: null,
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
                  genreIds: null,
                  releaseYear: null,
                  minRating: null,
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

        final filtered = _filters.hideSeen
            ? rawResults.where((item) => getSeenCount(item) == 0).toList()
            : rawResults;

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
  Future<List<SeenItem>> loadSeenStatusForItem(int tmdbId, MediaType type) =>
      repository.getSeenStatus(tmdbId, type);
  Future<void> markAsSeen(SeenItem item) async {
    await repository.markAsSeen(item);

    // After marking as seen, remove from watchlist when appropriate so
    // that all entry points (SeenManager, Notification center, WatchNext)
    // exhibit the same behaviour.
    try {
      final inWatchlist = _watchlistIds.contains(item.tmdbId.toString());

      if (inWatchlist) {
        if (item.type == MediaType.movie) {
          final mediaShell = MediaItem(
            id: item.tmdbId,
            title: item.title,
            overview: '',
            releaseDate: '',
            mediaType: MediaType.movie,
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
            try {
              final next = await getNextEpisode(item.tmdbId);
              if (next == null) noNext = true;
            } catch (e) {
              debugPrint(
                '[SearchProvider] markAsSeen getNextEpisode failed: $e',
              );
            }

            if ((isLastEpisode || noNext) && discontinued) {
              await toggleInList(mediaItem, 'watchlist');
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

    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
  }

  Future<void> markManyAsSeen(List<SeenItem> items) async {
    if (items.isEmpty) return;
    await repository.markManyAsSeen(items);
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
    await loadQuickAddItems();
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
    final wasInWatchlist = _watchlistIds.contains('${next.tmdbId}');

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

      if (wasInWatchlist && !_watchlistIds.contains('${next.tmdbId}')) {
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
    final wasInWatchlist = _watchlistIds.contains('${item.tmdbId}');
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

      if (wasInWatchlist && !_watchlistIds.contains('${item.tmdbId}')) {
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
    final wasInWatchlist = _watchlistIds.contains('${item.tmdbId}');
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

      if (wasInWatchlist && !_watchlistIds.contains('${item.tmdbId}')) {
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

  MediaItem _releaseShell(NotifiedItem item) => MediaItem(
    id: item.tmdbId,
    title: item.title,
    posterPath: item.posterPath,
    overview: '',
    releaseDate: item.releaseDate?.toIso8601String() ?? '',
    mediaType: item.type,
  );

  /// Stops following the release [item]: it leaves "Upcoming". Returns the
  /// action that follows it again, as it was (manual or automatic).
  Future<Future<void> Function()> disableReleaseAlert(NotifiedItem item) async {
    final shell = _releaseShell(item);
    await repository.toggleNotification(shell);
    await loadNotifiedItems();

    return () async {
      if (!await repository.isNotified(item.tmdbId, item.type)) {
        await repository.toggleNotification(shell, autoNotify: item.autoNotify);
      }
      await loadNotifiedItems();
    };
  }

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

  List<MediaItemPreview> getPreviewsForList(String name) {
    return _listPreviews[name] ?? [];
  }

  int getListItemCount(String name) {
    return _listEntries[name]?.length ?? 0;
  }

  /// Type of a list entry written as `id:type`; a movie when unspecified.
  static MediaType listEntryType(String entry) =>
      entry.endsWith(':tv') ? MediaType.tv : MediaType.movie;

  /// Entries of [listName] of the given [type]; all of them when `null`.
  List<String> getListEntriesOfType(String listName, MediaType? type) {
    final entries = _listEntries[listName] ?? const <String>[];
    if (type == null) return entries;
    return entries.where((entry) => listEntryType(entry) == type).toList();
  }

  /// Number of entries of [type] across every list; all types when `null`.
  int countListEntries(MediaType? type) {
    var count = 0;
    for (final name in _listNames) {
      count += getListEntriesOfType(name, type).length;
    }
    return count;
  }

  /// First [limit] previews of [listName] of the given [type], in the order
  /// of the list. Reads only as far into the list as needed.
  Future<List<MediaItemPreview>> loadListPreviewsOfType(
    String listName,
    MediaType type, {
    int limit = 3,
  }) async {
    final entries = _listEntries[listName] ?? const <String>[];
    var found = 0;
    var depth = 0;
    for (var i = 0; i < entries.length && found < limit; i++) {
      if (listEntryType(entries[i]) == type) {
        found++;
        depth = i + 1;
      }
    }
    if (depth == 0) return const [];
    final previews = await repository.getListPreviews(listName, limit: depth);
    return previews
        .where((preview) => preview.type == type.name)
        .take(limit)
        .toList();
  }

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

  Future<List<int>> exportAllData() {
    return repository.exportAllData();
  }

  Future<void> importAllData(
    List<int> zipBytes, {
    ImportMode mode = ImportMode.append,
  }) async {
    _isImporting = true;
    _importProgress = 0.0;
    _importStatus = _l10n.progressImportingAll;
    notifyListeners();

    try {
      await repository.importAllData(
        zipBytes,
        mode: mode,
        onProgress: (p, s) {
          _importProgress = p;
          _importStatus = s;
          notifyListeners();
        },
      );

      _importProgress = 1.0;
      _importStatus = _l10n.progressDone;
    } catch (e) {
      _importStatus = _l10n.progressError('$e');
    } finally {
      await loadAllSeenStatus();
      await loadLikedStatus();
      await loadNotifiedItems();
      await loadListNames();
      await _loadAllListEntries();
      await updateCacheSize();
      await updateSeenDbSize();
      // If quick add was not part of import, populate from seen history
      try {
        final qaItems = await repository.getQuickAddItems();
        if (qaItems.isEmpty) {
          await repository.populateQuickAddFromSeenHistory();
          await loadQuickAddItems();
        }
      } catch (e) {
        debugPrint(
          '[SearchProvider] importAllData quick-add population failed: $e',
        );
      }

      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> refetchMissingData() async {
    _isImporting = true;
    _importProgress = 0.0;
    _importStatus = _l10n.progressRefetchingRuntimes;
    notifyListeners();

    try {
      final seenItems = await repository.getSeenItems();
      final itemsToUpdate = seenItems
          .where((i) => i.id != null && (i.runtime == null || i.runtime == 0))
          .toList();

      int processed = 0;
      for (final item in itemsToUpdate) {
        _importProgress = processed / itemsToUpdate.length;
        _importStatus = _l10n.progressRefetchingItem(item.title);
        notifyListeners();

        try {
          final details = await repository.getMediaDetails(
            item.tmdbId,
            type: item.type,
          );

          List<String>? newGenres = item.genres;
          if (newGenres == null || newGenres.isEmpty) {
            newGenres = details.item.genres;
          }
          int? newRuntime = item.runtime;

          if (item.type == MediaType.movie) {
            newRuntime = details.item.runtime;
          } else if (item.seasonNumber != null && item.episodeNumber != null) {
            // For TV episodes, runtime comes from season/episode
            final seasonDetails = await repository.getSeasonDetails(
              item.tmdbId,
              item.seasonNumber!,
            );
            final episodes = seasonDetails['episodes'] as List?;
            final episode = episodes?.firstWhere(
              (e) => e['episode_number'] == item.episodeNumber,
              orElse: () => null,
            );
            if (episode != null && episode['runtime'] != null) {
              newRuntime = episode['runtime'] as int;
            } else {
              // fallback to tv show runtime
              newRuntime = details.item.runtime;
            }
          }

          if ((newRuntime != null && newRuntime > 0) ||
              (newGenres != null && newGenres.isNotEmpty)) {
            final updatedItem = item.copyWith(
              runtime: newRuntime,
              genres: newGenres,
            );
            await repository.updateSeenEntry(updatedItem);
          }
        } catch (e) {
          // Ignore individual failures to not interrupt the whole batch
        }

        processed++;
      }

      _importProgress = 1.0;
      _importStatus = _l10n.progressRefetchDone;
    } catch (e) {
      _importStatus = _l10n.progressError('$e');
    } finally {
      await loadAllSeenStatus();
      await updateSeenDbSize();
      _isImporting = false;
      notifyListeners();
    }
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
        final episodeSeen = seen
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
      final episodes = seasonDetails['episodes'] as List?;
      if (episodes == null) return null;

      dynamic epData;
      try {
        epData = episodes.firstWhere((e) => e['episode_number'] == nextE);
      } catch (_) {
        epData = null;
      }

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

  Future<void> refreshNotifiedItems() async {
    _isNotifiedRefreshing = true;
    notifyListeners();
    try {
      // Show the locally stored data immediately, then reconcile with the
      // network series by series (throttled to at most once a day per series).
      await loadNotifiedItems();
      await repository.refreshNotifiedItems();
      await loadNotifiedItems();
    } finally {
      _isNotifiedRefreshing = false;
      notifyListeners();
    }
  }

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
