import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

class SearchProvider extends ChangeNotifier {
  final MediaRepository _mediaRepository;

  SearchProvider(this._mediaRepository);

  List<MediaItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Set<String> _watchlistEntries = {};
  bool _watchlistLoaded = false;

  List<MediaItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  Set<int> get watchlistIds => _watchlistEntries.map((e) => int.parse(e.split(':').first)).toSet();

  Future<void> searchMedia(String query) async {
    if (query.isEmpty) return;

    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _mediaRepository.searchMedia(query);
    } catch (e) {
      debugPrint('Failed to load results: $e');
    } finally {
      _isLoading = false;
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
