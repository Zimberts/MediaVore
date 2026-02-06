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
  int _cacheSize = 0;
  int _seenDbSize = 0;
  int _resetCount = 0;
  int _currentPage = 1;
  String _currentQuery = '';
  bool _hasMore = true;
  
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

  Future<void> loadLikedStatus() async {
    _likedIds = await repository.getLikedEntries();
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
        // Auto-notify when added to watchlist
        await repository.toggleNotification(item, autoNotify: true);
        await loadNotifiedItems();
      }
    }
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
    await loadNotifiedItems(); // Added to refresh notified items immediately
    await updateSeenDbSize();
  }
  Future<void> deleteSeenEntry(int id) async {
    await repository.deleteSeenEntry(id);
    await loadAllSeenStatus();
    await loadNotifiedItems(); // Added to refresh notified items immediately
    await updateSeenDbSize();
  }
  Future<void> removeFromSeen(int tmdbId, MediaType type, {int? seasonNumber, int? episodeNumber}) async {
    await repository.removeFromSeen(tmdbId, type, seasonNumber: seasonNumber, episodeNumber: episodeNumber);
    await loadAllSeenStatus();
    await loadNotifiedItems(); // Added to refresh notified items immediately
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
    await loadNotifiedItems(); // Refresh alerted items after import
    await updateCacheSize();
    await updateSeenDbSize();
  }

  /// Finds the next episode to watch for a given TV series.
  Future<({int seasonNumber, int episodeNumber})?> getNextEpisode(int tmdbId) async {
    final seen = await repository.getSeenStatus(tmdbId, MediaType.tv);
    
    int nextS = 1;
    int nextE = 1;

    if (seen.isNotEmpty) {
      // Filter to only include entries with season and episode numbers
      final episodeSeen = seen.where((s) => s.seasonNumber != null && s.episodeNumber != null).toList();
      if (episodeSeen.isNotEmpty) {
        // Sort by season and episode to find the latest seen
        episodeSeen.sort((a, b) {
          final seasonCompare = b.seasonNumber!.compareTo(a.seasonNumber!);
          if (seasonCompare != 0) return seasonCompare;
          return b.episodeNumber!.compareTo(a.episodeNumber!);
        });

        final latest = episodeSeen.first;
        final details = await repository.getMediaDetails(tmdbId, type: MediaType.tv);
        
        // Find current season details to see if there's a next episode
        final currentSeason = details.item.seasons?.firstWhere(
          (s) => s.seasonNumber == latest.seasonNumber,
          orElse: () => details.item.seasons!.firstWhere((s) => s.seasonNumber == latest.seasonNumber), // fallback
        );
        
        if (currentSeason != null && latest.episodeNumber! < currentSeason.episodeCount) {
          nextS = latest.seasonNumber!;
          nextE = latest.episodeNumber! + 1;
        } else {
          // Look for next season
          final nextSeason = details.item.seasons?.firstWhere(
            (s) => s.seasonNumber == latest.seasonNumber! + 1,
            orElse: () => details.item.seasons!.firstWhere((s) => s.seasonNumber == -1, orElse: () => const TVSeason(id: -1, seasonNumber: -1, episodeCount: 0)), // Dummy fallback
          );
          
          if (nextSeason != null && nextSeason.seasonNumber > latest.seasonNumber!) {
             nextS = nextSeason.seasonNumber;
             nextE = 1;
          } else {
            return null; // All seen or cannot determine
          }
        }
      }
    }

    // Check if (nextS, nextE) is already released
    try {
      final seasonDetails = await repository.getSeasonDetails(tmdbId, nextS);
      final episodes = seasonDetails['episodes'] as List;
      final epData = episodes.firstWhere((e) => e['episode_number'] == nextE, orElse: () => null);
      
      if (epData != null) {
        final airDateStr = epData['air_date'] as String?;
        if (airDateStr != null) {
          final airDate = DateTime.tryParse(airDateStr);
          if (airDate != null) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            if (airDate.isAfter(today)) {
              return null; // Not released yet
            }
          } else {
            // No valid air date, assume not released
            return null;
          }
        } else {
          // air_date is null
          return null;
        }
      } else {
        return null;
      }
    } catch (_) {
      // On error (offline or not found), don't show in quick add
      return null;
    }

    return (seasonNumber: nextS, episodeNumber: nextE);
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
