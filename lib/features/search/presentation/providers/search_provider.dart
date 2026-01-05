import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

class SearchProvider extends ChangeNotifier {
  final MediaRepository _mediaRepository;

  SearchProvider(this._mediaRepository);

  List<MediaItem> _items = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String _searchQuery = '';
  bool _isOffline = false;
  
  // Map of list name to set of "id:type" entries
  Map<String, Set<String>> _listsData = {};
  List<String> _listNames = ['watchlist'];
  
  // Previews for each list
  Map<String, List<MediaItemPreview>> _listPreviews = {};

  // Seen status: Map of "id:type" to count of UNIQUE seen items (episodes for TV, 1 for movie if seen)
  Map<String, int> _seenStatus = {};

  int _currentPage = 1;
  bool _hasMore = true;
  int _resetCount = 0;

  List<MediaItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String get searchQuery => _searchQuery;
  bool get isOffline => _isOffline;
  
  Set<int> get watchlistIds => (_listsData['watchlist'] ?? {})
      .map((e) => int.parse(e.split(':').first))
      .toSet();

  List<String> get listNames => _listNames;
  bool get hasMore => _hasMore;
  int get resetCount => _resetCount;

  List<MediaItemPreview> getPreviewsForList(String listName) => _listPreviews[listName] ?? [];

  /// Helper to wrap calls and catch network errors to update global offline status
  Future<T> _wrapNetworkCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      setOffline(false);
      return result;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('SocketException') || 
          errStr.contains('Network error') ||
          errStr.contains('connectionError') ||
          errStr.contains('HttpException')) {
        setOffline(true);
      }
      rethrow;
    }
  }

  void setOffline(bool offline) {
    if (_isOffline != offline) {
      _isOffline = offline;
      // Delaying notification ensures we are out of the build phase
      Future.microtask(() => notifyListeners());
    }
  }

  /// Public method to manually trigger offline status (e.g. from image load errors)
  void notifyNetworkError() => setOffline(true);

  /// Loads the entire seen history into memory for instant access across the app.
  Future<void> loadAllSeenStatus() async {
    try {
      final allSeen = await _mediaRepository.getSeenItems();
      final Map<String, int> newStatus = {};
      
      // We group by media id to count UNIQUE episodes/viewings for progress bars
      final Map<String, Set<String>> uniqueEpisodes = {};
      
      for (final item in allSeen) {
        final key = '${item.tmdbId}:${item.type.name}';
        if (item.type == MediaType.tv) {
          uniqueEpisodes[key] ??= {};
          uniqueEpisodes[key]!.add('${item.seasonNumber}:${item.episodeNumber}');
        } else {
          // For movies, we just need to know it's been seen at least once
          newStatus[key] = 1;
        }
      }
      
      uniqueEpisodes.forEach((key, episodes) {
        newStatus[key] = episodes.length;
      });
      
      _seenStatus = newStatus;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load seen status: $e');
    }
  }

  /// Helper for detail pages to get full seen status for a specific show (episodes list)
  Future<List<SeenItem>> loadSeenStatusForItem(int id, MediaType type) {
    return _mediaRepository.getSeenStatus(id, type);
  }

  Future<void> searchMedia(String query) async {
    if (query == _searchQuery && _items.isNotEmpty) return;

    _searchQuery = query;
    if (query.isEmpty) {
      _items = [];
      _isLoading = false;
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _currentPage = 1;
    _hasMore = true;
    _items = [];
    notifyListeners();

    try {
      _items = await _wrapNetworkCall(() => _mediaRepository.searchMedia(query, page: _currentPage));
      if (_items.isEmpty) {
        _hasMore = false;
      }
      await loadAllSeenStatus();
    } catch (e) {
      debugPrint('Failed to load movies: $e');
      _items = [];
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int getSeenCount(MediaItem item) {
    return _seenStatus['${item.id}:${item.mediaType.name}'] ?? 0;
  }

  void clearSearch() {
    _searchQuery = '';
    _items = [];
    _isLoading = false;
    _hasMore = false;
    notifyListeners();
  }

  void requestReset() {
    _resetCount++;
    notifyListeners();
  }

  Future<void> fetchNextPage() async {
    if (_isFetchingMore || !_hasMore || _searchQuery.isEmpty) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final nextMovies = await _wrapNetworkCall(() => _mediaRepository.searchMedia(_searchQuery, page: _currentPage));
      if (nextMovies.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(nextMovies);
      }
    } catch (e) {
      debugPrint('Failed to fetch next page: $e');
      _currentPage--;
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadLists() async {
    try {
      _listNames = await _mediaRepository.getAllListNames();
      final Map<String, Set<String>> newData = {};
      final Map<String, List<MediaItemPreview>> newPreviews = {};
      
      for (final name in _listNames) {
        final entries = await _mediaRepository.getListEntries(name);
        newData[name] = entries.toSet();
        
        final previews = await _mediaRepository.getListPreviews(name);
        newPreviews[name] = previews;
      }
      _listsData = newData;
      _listPreviews = newPreviews;
      
      await loadAllSeenStatus();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load lists: $e');
    }
  }

  Future<void> createList(String name) async {
    try {
      await _mediaRepository.createList(name);
      await loadLists();
    } catch (e) {
      debugPrint('Failed to create list: $e');
    }
  }

  Future<void> deleteList(String name) async {
    try {
      await _mediaRepository.deleteList(name);
      await loadLists();
    } catch (e) {
      debugPrint('Failed to delete list: $e');
    }
  }

  Future<void> toggleInList(MediaItem item, String listName) async {
    final entry = '${item.id}:${item.mediaType.name}';
    final entries = _listsData[listName] ?? {};
    final isInList = entries.contains(entry);
    
    try {
      if (isInList) {
        await _mediaRepository.removeFromList(item.id, item.mediaType, listName);
        _listsData[listName]?.remove(entry);
      } else {
        await _mediaRepository.addToList(item, listName);
        _listsData[listName] ??= {};
        _listsData[listName]?.add(entry);
      }
      
      final previews = await _mediaRepository.getListPreviews(listName);
      _listPreviews[listName] = previews;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update list $listName: $e');
    }
  }

  bool isItemInList(MediaItem item, String listName) {
    final entry = '${item.id}:${item.mediaType.name}';
    return _listsData[listName]?.contains(entry) ?? false;
  }

  Future<void> toggleWatchlist(MediaItem item) => toggleInList(item, 'watchlist');
  
  Future<void> loadWatchlist() => loadLists();

  Future<void> markAsSeen(SeenItem item) async {
    await _mediaRepository.markAsSeen(item);
    await loadAllSeenStatus();
  }

  Future<void> removeFromSeen(int tmdbId, MediaType type, {int? seasonNumber, int? episodeNumber}) async {
    await _mediaRepository.removeFromSeen(tmdbId, type, seasonNumber: seasonNumber, episodeNumber: episodeNumber);
    await loadAllSeenStatus();
  }

  Future<void> deleteSeenEntry(int id) async {
    await _mediaRepository.deleteSeenEntry(id);
    await loadAllSeenStatus();
  }

  /// Public method to get full details while updating the global offline state.
  Future<MediaDetails> getMediaDetails(int id, MediaType type) {
    return _wrapNetworkCall(() => _mediaRepository.getMediaDetails(id, type: type));
  }

  /// Public method to get season details while updating the global offline state.
  Future<Map<String, dynamic>> getSeasonDetails(int tvId, int seasonNumber) {
    return _wrapNetworkCall(() => _mediaRepository.getSeasonDetails(tvId, seasonNumber));
  }
}
