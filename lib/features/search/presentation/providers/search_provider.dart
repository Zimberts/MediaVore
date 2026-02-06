import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

class SearchProvider with ChangeNotifier {
  final MediaRepository repository;

  SearchProvider(this.repository) {
    _init();
  }

  List<MediaItem> _searchResults = [];
  bool _isLoading = false;
  bool _isCacheLoading = false;
  bool _isDbSizeLoading = false;
  bool _isNotifiedRefreshing = false;
  String? _error;
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
  int _selectedTab = 0; // Default to "Discover" (SearchPage)

  // Progress feedback for refetching/importing
  double _importProgress = 0.0;
  String _importStatus = '';
  bool _isImporting = false;

  // Filter states
  List<int>? _genreIds;
  int? _releaseYear;
  double? _minRating;
  String? _language;
  MediaType? _filterType;
  bool _isDiscoverMode = false;

  List<SeenItem> _seenItems = [];
  Map<String, int> _seenCounts = {}; // "id:type" -> count
  List<String> _watchlistIds = []; // Simplified IDs for quick checks
  List<String> _likedIds = []; // "id:type"
  List<NotifiedItem> _notifiedItems = [];

  List<MediaItem> get items => _searchResults; // For SearchPage
  bool get isLoading => _isLoading;
  bool get isCacheLoading => _isCacheLoading;
  bool get isDbSizeLoading => _isDbSizeLoading;
  bool get isNotifiedRefreshing => _isNotifiedRefreshing;
  String? get error => _error;
  bool get isOffline => _isOffline;
  List<String> get listNames => _listNames;
  int get cacheSize => _cacheSize;
  int get seenDbSize => _seenDbSize;
  int get resetCount => _resetCount;
  bool get hasMore => _hasMore;
  List<String> get watchlistIds => _watchlistIds;
  List<SeenItem> get seenItems => _seenItems;
  List<String> get likedIds => _likedIds;
  List<NotifiedItem> get notifiedItems => _notifiedItems;
  int get selectedTab => _selectedTab;

  double get importProgress => _importProgress;
  String get importStatus => _importStatus;
  bool get isImporting => _isImporting;

  // Filter getters
  List<int>? get genreIds => _genreIds;
  int? get releaseYear => _releaseYear;
  double? get minRating => _minRating;
  String? get language => _language;
  MediaType? get filterType => _filterType;
  bool get isDiscoverMode => _isDiscoverMode;
  String get currentQuery => _currentQuery;

  Future<void> _init() async {
    await loadListNames();
    await _loadAllListEntries();
    await updateCacheSize();
    await updateSeenDbSize();
    await loadAllSeenStatus();
    await loadWatchlist();
    await loadLikedStatus();
    await loadNotifiedItems();
  }

  void setSelectedTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
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
    notifyListeners();
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
  }

  Future<void> loadNotifiedItems() async {
    _notifiedItems = await repository.getNotifiedItems();
    notifyListeners();
  }

  int getSeenCount(MediaItem item) {
    return _seenCounts['${item.id}:${item.mediaType.name}'] ?? 0;
  }

  bool isItemInList(MediaItem item, String listName) {
    final entry = '${item.id}:${item.mediaType.name}';
    return _listEntries[listName]?.contains(entry) ?? false;
  }

  bool isLiked(MediaItem item) {
    return _likedIds.contains('${item.id}:${item.mediaType.name}');
  }

  bool isNotified(MediaItem item) {
    return _notifiedItems.any((n) => n.tmdbId == item.id && n.type == item.mediaType);
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
        await repository.toggleNotification(item, autoNotify: true);
        await loadNotifiedItems();
      }
    }
    _listPreviews[listName] = await repository.getListPreviews(listName);
    await updateCacheSize();
    notifyListeners();
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
    _listEntries[name] = [];
    _listPreviews[name] = [];
    notifyListeners();
  }

  Future<void> deleteList(String name) async {
    await repository.deleteList(name);
    await loadListNames();
    _listEntries.remove(name);
    _listPreviews.remove(name);
    notifyListeners();
  }

  Future<void> updateListOrder(String listName, List<String> orderedEntries) async {
    await repository.updateListOrder(listName, orderedEntries);
    _listEntries[listName] = orderedEntries;
    _listPreviews[listName] = await repository.getListPreviews(listName);
    notifyListeners();
  }

  String getShareLinkForList(String listName) {
    final entries = _listEntries[listName] ?? [];
    if (entries.isEmpty) return '';
    final encodedItems = Uri.encodeComponent(entries.join(','));
    return 'https://mediavore.app/share?name=${Uri.encodeComponent(listName)}&items=$encodedItems';
  }

  String getCustomSchemeShareLinkForList(String listName) {
    final entries = _listEntries[listName] ?? [];
    if (entries.isEmpty) return '';
    final encodedItems = Uri.encodeComponent(entries.join(','));
    return 'mediavore://share?name=${Uri.encodeComponent(listName)}&items=$encodedItems';
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
        final shell = MediaItem(id: id, title: 'Unknown', overview: '', releaseDate: '', mediaType: type);
        await repository.addToList(shell, name);
      }
    }
    await _loadAllListEntries();
    notifyListeners();
  }

  void setFilters({
    List<int>? genreIds,
    int? releaseYear,
    double? minRating,
    String? language,
    MediaType? type,
  }) {
    _genreIds = genreIds;
    _releaseYear = releaseYear;
    _minRating = minRating;
    _language = language;
    _filterType = type;
    notifyListeners();
  }

  void clearFilters() {
    _genreIds = null;
    _releaseYear = null;
    _minRating = null;
    _language = null;
    _filterType = null;
    notifyListeners();
  }

  Future<void> searchMedia(String query) async {
    _currentQuery = query;
    if (query.isEmpty && !_isDiscoverMode) {
      _isDiscoverMode = true;
    } else if (query.isNotEmpty) {
      _isDiscoverMode = false;
    }

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      if (_isDiscoverMode && _currentQuery.isEmpty) {
        if (_filterType == null) {
          // Both types mode
          final movies = await repository.discoverMedia(
            page: _currentPage,
            genreIds: _genreIds,
            releaseYear: _releaseYear,
            minRating: _minRating,
            language: _language,
            type: MediaType.movie,
          );
          final tv = await repository.discoverMedia(
            page: _currentPage,
            genreIds: _genreIds,
            releaseYear: _releaseYear,
            minRating: _minRating,
            language: _language,
            type: MediaType.tv,
          );
          _searchResults = [...movies, ...tv]..sort((a, b) => b.voteAverage?.compareTo(a.voteAverage ?? 0) ?? 0);
        } else {
          _searchResults = await repository.discoverMedia(
            page: _currentPage,
            genreIds: _genreIds,
            releaseYear: _releaseYear,
            minRating: _minRating,
            language: _language,
            type: _filterType!,
          );
        }
      } else {
        _searchResults = await repository.searchMedia(
          _currentQuery,
          page: _currentPage,
          genreIds: _genreIds,
          releaseYear: _releaseYear,
          minRating: _minRating,
          language: _language,
          type: _filterType,
        );
      }
      _isOffline = false;
    } catch (e) {
      _error = e.toString();
      _isOffline = true;
    } finally {
      _isLoading = false;
      await updateCacheSize();
      notifyListeners();
    }
  }

  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();
  }

    try {
      _currentPage++;
      List<MediaItem> results;
      if (_isDiscoverMode && _currentQuery.isEmpty) {
        if (_filterType == null) {
          final movies = await repository.discoverMedia(
            page: _currentPage,
            genreIds: _genreIds,
            releaseYear: _releaseYear,
            minRating: _minRating,
            language: _language,
            type: MediaType.movie,
          );
          final tv = await repository.discoverMedia(
            page: _currentPage,
            genreIds: _genreIds,
            releaseYear: _releaseYear,
            minRating: _minRating,
            language: _language,
            type: MediaType.tv,
          );
          results = [...movies, ...tv]..sort((a, b) => b.voteAverage?.compareTo(a.voteAverage ?? 0) ?? 0);
        } else {
          results = await repository.discoverMedia(
            page: _currentPage,
            genreIds: _genreIds,
            releaseYear: _releaseYear,
            minRating: _minRating,
            language: _language,
            type: _filterType!,
          );
        }
      } else {
        results = await repository.searchMedia(
          _currentQuery,
          page: _currentPage,
          genreIds: _genreIds,
          releaseYear: _releaseYear,
          minRating: _minRating,
          language: _language,
          type: _filterType,
        );
      }

      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _searchResults.addAll(results);
      }
      _isOffline = false;
    } catch (e) {
      _error = e.toString();
      _isOffline = true;
      _currentPage--;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _isDiscoverMode = false;
    notifyListeners();
  }

  void requestReset() {
    clearSearch();
    _resetCount++;
    notifyListeners();
  }

  Future<MediaDetails> getMediaDetails(int id, MediaType type) => repository.getMediaDetails(id, type: type);
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) => repository.getSeasonDetails(tvId, seasonNumber);
  Future<List<SeenItem>> loadSeenStatusForItem(int tmdbId, MediaType type) => repository.getSeenStatus(tmdbId, type);
  Future<void> markAsSeen(SeenItem item) async {
    await repository.markAsSeen(item);
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
  }
  Future<void> deleteSeenEntry(int id) async {
    await repository.deleteSeenEntry(id);
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
  }
  Future<void> removeFromSeen(int tmdbId, MediaType type, {int? seasonNumber, int? episodeNumber}) async {
    await repository.removeFromSeen(tmdbId, type, seasonNumber: seasonNumber, episodeNumber: episodeNumber);
    await loadAllSeenStatus();
    await loadNotifiedItems();
    await updateSeenDbSize();
  }

  List<MediaItemPreview> getPreviewsForList(String name) {
    return _listPreviews[name] ?? [];
  }

  int getListItemCount(String name) {
    return _listEntries[name]?.length ?? 0;
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

  Future<List<Map<String, dynamic>>> exportSeenData({
    DateTime? start,
    DateTime? end,
    int? tmdbId,
    MediaType? type,
  }) {
    return repository.exportSeenData(
      start: start,
      end: end,
      tmdbId: tmdbId,
      type: type,
    );
  }

  Future<void> importSeenData(List<Map<String, dynamic>> data, {ImportMode mode = ImportMode.append}) async {
    _isImporting = true;
    _importProgress = 0.0;
    _importStatus = 'Starting import...';
    notifyListeners();

    try {
      await repository.importSeenData(
        data, 
        mode: mode,
        onProgress: (progress, status) {
          _importProgress = progress;
          _importStatus = status;
          notifyListeners();
        },
      );
      
      _importProgress = 1.0;
      _importStatus = 'Done!';
    } catch (e) {
      _importStatus = 'Error: $e';
    } finally {
      await loadAllSeenStatus();
      await loadNotifiedItems();
      await updateCacheSize();
      await updateSeenDbSize();
      
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<({int seasonNumber, int episodeNumber})?> getNextEpisode(int tmdbId) async {
    try {
      final seen = await repository.getSeenStatus(tmdbId, MediaType.tv);

      int nextS = 1;
      int nextE = 1;

      if (seen.isNotEmpty) {
        final episodeSeen = seen.where((s) => s.seasonNumber != null && s.episodeNumber != null).toList();
        if (episodeSeen.isNotEmpty) {
          episodeSeen.sort((a, b) {
            final seasonCompare = b.seasonNumber!.compareTo(a.seasonNumber!);
            if (seasonCompare != 0) return seasonCompare;
            return b.episodeNumber!.compareTo(a.episodeNumber!);
          });

          final latest = episodeSeen.first;
          final details = await repository.getMediaDetails(tmdbId, type: MediaType.tv);

          final seasons = details.item.seasons;
          if (seasons == null || seasons.isEmpty) return null;

          final currentSeason = seasons.firstWhere(
            (s) => s.seasonNumber == latest.seasonNumber,
            orElse: () => const TVSeason(id: -1, seasonNumber: -1, episodeCount: 0),
          );

          if (currentSeason.seasonNumber != -1 && latest.episodeNumber! < currentSeason.episodeCount) {
            nextS = latest.seasonNumber!;
            nextE = latest.episodeNumber! + 1;
          } else {
            final nextSeason = seasons.firstWhere(
              (s) => s.seasonNumber == latest.seasonNumber! + 1,
              orElse: () => const TVSeason(id: -1, seasonNumber: -1, episodeCount: 0),
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
      await repository.refreshNotifiedItems();
      await loadNotifiedItems();
    } finally {
      _isNotifiedRefreshing = false;
      notifyListeners();
    }
  }

  Future<List<MediaItem>> getSimilarMedia(int id, MediaType type) => repository.getSimilarMedia(id, type);
  Future<List<MediaItem>> getRecommendedMedia(int id, MediaType type) => repository.getRecommendedMedia(id, type);
  Future<Map<String, dynamic>> getWatchProviders(int id, MediaType type) => repository.getWatchProviders(id, type);
  Future<List<Map<String, dynamic>>> getVideos(int id, MediaType type) => repository.getVideos(id, type);
}
