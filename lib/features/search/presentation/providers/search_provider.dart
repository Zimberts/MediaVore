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
  String? _error;
  bool _isOffline = false;
  List<String> _listNames = ['watchlist'];
  final Map<String, List<String>> _listEntries = {}; // listName -> ["id:type"]
  int _cacheSize = 0;
  int _seenDbSize = 0;
  int _resetCount = 0;
  int _currentPage = 1;
  String _currentQuery = '';
  bool _hasMore = true;
  
  List<SeenItem> _seenItems = [];
  Map<String, int> _seenCounts = {}; // "id:type" -> count
  List<String> _watchlistIds = []; // Simplified IDs for quick checks

  List<MediaItem> get items => _searchResults; // For SearchPage
  bool get isLoading => _isLoading;
  bool get isCacheLoading => _isCacheLoading;
  bool get isDbSizeLoading => _isDbSizeLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;
  List<String> get listNames => _listNames;
  int get cacheSize => _cacheSize;
  int get seenDbSize => _seenDbSize;
  int get resetCount => _resetCount;
  bool get hasMore => _hasMore;
  List<String> get watchlistIds => _watchlistIds;
  List<SeenItem> get seenItems => _seenItems;

  Future<void> _init() async {
    await loadListNames();
    await _loadAllListEntries();
    await updateCacheSize();
    await updateSeenDbSize();
    await loadAllSeenStatus();
    await loadWatchlist();
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
    _isCacheLoading = false;
    notifyListeners();
  }

  Future<void> _loadAllListEntries() async {
    for (final name in _listNames) {
      _listEntries[name] = await repository.getListEntries(name);
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
    notifyListeners();
  }

  Future<void> loadAllSeenStatus() async {
    _seenItems = await repository.getSeenItems();
    final Map<String, int> counts = {};
    
    // Group seen items by their media key
    final Map<String, List<SeenItem>> grouped = {};
    for (final item in _seenItems) {
      final key = '${item.tmdbId}:${item.type.name}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    // For each media key, calculate the count
    grouped.forEach((key, items) {
      if (items.first.type == MediaType.movie) {
        // For movies, count total viewings
        counts[key] = items.length;
      } else {
        // For series, count unique episode viewings
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

  int getSeenCount(MediaItem item) {
    return _seenCounts['${item.id}:${item.mediaType.name}'] ?? 0;
  }

  bool isItemInList(MediaItem item, String listName) {
    final entry = '${item.id}:${item.mediaType.name}';
    return _listEntries[listName]?.contains(entry) ?? false;
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
      }
    }
    await updateCacheSize();
    notifyListeners();
  }

  Future<void> toggleWatchlist(MediaItem item) async {
    await toggleInList(item, 'watchlist');
  }

  Future<void> createList(String name) async {
    await repository.createList(name);
    await loadListNames();
    _listEntries[name] = [];
    notifyListeners();
  }

  Future<void> deleteList(String name) async {
    await repository.deleteList(name);
    await loadListNames();
    _listEntries.remove(name);
    notifyListeners();
  }

  Future<void> searchMedia(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    _isLoading = true;
    _error = null;
    _currentQuery = query;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      _searchResults = await repository.searchMedia(query, page: _currentPage);
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
    if (_isLoading || !_hasMore || _currentQuery.isEmpty) return;

    _isLoading = true;
    notifyListeners();
  }

    try {
      _currentPage++;
      final results = await repository.searchMedia(_currentQuery, page: _currentPage);
      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _searchResults.addAll(results);
      }
      _isOffline = false;
    } catch (e) {
      _error = e.toString();
      _isOffline = true;
      _currentPage--; // Revert page increment on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  void requestReset() {
    clearSearch();
    _resetCount++;
    notifyListeners();
  }

  // Wrappers for repository methods used in UI
  Future<MediaDetails> getMediaDetails(int id, MediaType type) => repository.getMediaDetails(id, type: type);
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) => repository.getSeasonDetails(tvId, seasonNumber);
  Future<List<SeenItem>> loadSeenStatusForItem(int tmdbId, MediaType type) => repository.getSeenStatus(tmdbId, type);
  Future<void> markAsSeen(SeenItem item) async {
    await repository.markAsSeen(item);
    await loadAllSeenStatus();
    await updateSeenDbSize();
  }
  Future<void> deleteSeenEntry(int id) async {
    await repository.deleteSeenEntry(id);
    await loadAllSeenStatus();
    await updateSeenDbSize();
  }
  Future<void> removeFromSeen(int tmdbId, MediaType type, {int? seasonNumber, int? episodeNumber}) async {
    await repository.removeFromSeen(tmdbId, type, seasonNumber: seasonNumber, episodeNumber: episodeNumber);
    await loadAllSeenStatus();
    await updateSeenDbSize();
  }

  List<MediaItemPreview> getPreviewsForList(String name) {
    return [];
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
    await repository.importSeenData(data, mode: mode);
    await loadAllSeenStatus();
    await updateCacheSize();
    await updateSeenDbSize();
  }
}
