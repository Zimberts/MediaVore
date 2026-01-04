import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

class SearchProvider extends ChangeNotifier {
  final MediaRepository _mediaRepository;

  SearchProvider(this._mediaRepository);

  List<MediaItem> _items = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String _searchQuery = '';
  
  // Map of list name to set of "id:type" entries
  Map<String, Set<String>> _listsData = {};
  List<String> _listNames = ['watchlist'];
  
  // Previews for each list
  Map<String, List<MediaItemPreview>> _listPreviews = {};

  int _currentPage = 1;
  bool _hasMore = true;
  int _resetCount = 0;

  List<MediaItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String get searchQuery => _searchQuery;
  
  Set<int> get watchlistIds => (_listsData['watchlist'] ?? {})
      .map((e) => int.parse(e.split(':').first))
      .toSet();

  List<String> get listNames => _listNames;
  bool get hasMore => _hasMore;
  int get resetCount => _resetCount;

  List<MediaItemPreview> getPreviewsForList(String listName) => _listPreviews[listName] ?? [];

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
      _items = await _mediaRepository.searchMedia(query, page: _currentPage);
      if (_items.isEmpty) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Failed to load movies: $e');
      _items = [];
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      final nextMovies = await _mediaRepository.searchMedia(_searchQuery, page: _currentPage);
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
      
      // Update previews after change
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
}
