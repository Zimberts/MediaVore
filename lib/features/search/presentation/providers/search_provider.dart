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
  Set<String> _watchlistEntries = {};
  int _currentPage = 1;
  bool _hasMore = true;
  bool _watchlistLoaded = false;

  List<MediaItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String get searchQuery => _searchQuery;
  Set<int> get watchlistIds => _watchlistEntries.map((e) => int.parse(e.split(':').first)).toSet();
  bool get hasMore => _hasMore;

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

  Future<void> loadWatchlist() async {
    _watchlistEntries = (await _mediaRepository.getWatchlistEntries()).toSet();
    _watchlistLoaded = true;
    notifyListeners();
  }

  Future<void> toggleWatchlist(MediaItem item) async {
    final entry = '${item.id}:${item.mediaType.name}';
    final isInWatchlist = _watchlistEntries.contains(entry);
    try {
      if (isInWatchlist) {
        await _mediaRepository.removeFromWatchlist(item.id, item.mediaType);
        _watchlistEntries.remove(entry);
      } else {
        await _mediaRepository.addToWatchlist(item.id, item.mediaType);
        _watchlistEntries.add(entry);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update watchlist: $e');
    }
  }
}
