import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// List names, entries and poster previews read by the lists overview,
/// offered by [LibraryProvider] and, as a facade over it, by `SearchProvider`.
abstract interface class ListPreviewSource {
  List<String> get listNames;
  List<MediaItemPreview> getPreviewsForList(String name);
  List<String> getListEntriesOfType(String listName, MediaType? type);
  Future<List<MediaItemPreview>> loadListPreviewsOfType(
    String listName,
    MediaType type, {
    int limit,
  });
}

/// Provider dedicated to custom lists, likes and watchlist management.
class LibraryProvider with ChangeNotifier implements ListPreviewSource {
  LibraryProvider(this.repository) {
    unawaited(init());
  }

  final MediaRepository repository;

  List<String> _listNames = ['watchlist'];
  final Map<String, List<String>> _listEntries = {}; // listName -> ["id:type"]
  final Map<String, List<MediaItemPreview>> _listPreviews = {};
  List<String> _watchlistIds = [];
  List<String> _likedIds = [];
  final bool _isLoading = false;

  @override
  List<String> get listNames => _listNames;
  Map<String, List<String>> get listEntries => Map.unmodifiable(_listEntries);
  List<String> get watchlistIds => _watchlistIds;
  List<String> get likedIds => _likedIds;
  bool get isLoading => _isLoading;

  String get firstListName =>
      _listNames.isEmpty ? 'watchlist' : _listNames.first;
  String get tonightListName => firstListName;

  Future<void> init() async {
    await loadListNames();
    await loadAllListEntries();
    await loadWatchlist();
    await loadLikedStatus();
  }

  Future<void> loadListNames() async {
    _listNames = await repository.getAllListNames();
    notifyListeners();
  }

  Future<void> loadLists() async {
    await loadListNames();
    await loadAllListEntries();
  }

  Future<void> loadAllListEntries() async {
    for (final name in _listNames) {
      _listEntries[name] = await repository.getListEntries(name);
      _listPreviews[name] = await repository.getListPreviews(name);
    }
    notifyListeners();
  }

  Future<void> loadWatchlist() async {
    final entries = await repository.getWatchlistEntries();
    _watchlistIds = entries
        .map((e) => e.split(':').first)
        .where((id) => id.isNotEmpty)
        .toList();
    _listEntries['watchlist'] = entries;
    _listPreviews['watchlist'] = await repository.getListPreviews('watchlist');
    notifyListeners();
  }

  Future<void> loadLikedStatus() async {
    _likedIds = await repository.getLikedEntries();
    notifyListeners();
  }

  bool isLiked(MediaItem item) {
    return _likedIds.contains('${item.id}:${item.mediaType.name}');
  }

  Future<void> toggleLike(MediaItem item) async {
    await repository.toggleLike(item);
    await loadLikedStatus();
  }

  bool isItemInList(MediaItem item, String listName) {
    final entry = '${item.id}:${item.mediaType.name}';
    return _listEntries[listName]?.contains(entry) ?? false;
  }

  bool isWatchlist(MediaItem item) =>
      _watchlistIds.contains(item.id.toString());

  Future<void> toggleWatchlist(MediaItem item) async {
    await toggleInList(item, 'watchlist');
  }

  Future<void> toggleInList(MediaItem item, String listName) async {
    final entry = '${item.id}:${item.mediaType.name}';
    final currentEntries =
        _listEntries[listName] ?? await repository.getListEntries(listName);
    final wasInList = currentEntries.contains(entry);

    // Optimistically update memory state and notify listeners immediately.
    if (wasInList) {
      _listEntries[listName] = currentEntries.where((e) => e != entry).toList();
      if (listName == 'watchlist') {
        _watchlistIds.remove(item.id.toString());
      }
    } else {
      _listEntries[listName] = [...currentEntries, entry];
      if (listName == 'watchlist') {
        _watchlistIds.add(item.id.toString());
      }
    }
    notifyListeners();

    try {
      if (wasInList) {
        await repository.removeFromList(item.id, item.mediaType, listName);
      } else {
        await repository.addToList(item, listName);
        if (listName == 'watchlist' && item.canBeNotified) {
          unawaited(repository.toggleNotification(item, autoNotify: true));
        }
      }
      _listPreviews[listName] = await repository.getListPreviews(listName);
      notifyListeners();
    } catch (e) {
      // Rollback on failure
      if (wasInList) {
        _listEntries[listName] = [...currentEntries];
        if (listName == 'watchlist') {
          _watchlistIds.add(item.id.toString());
        }
      } else {
        _listEntries[listName] = currentEntries
            .where((e) => e != entry)
            .toList();
        if (listName == 'watchlist') {
          _watchlistIds.remove(item.id.toString());
        }
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addToList(MediaItem item, String listName) async {
    final entry = '${item.id}:${item.mediaType.name}';
    final currentEntries =
        _listEntries[listName] ?? await repository.getListEntries(listName);
    if (!currentEntries.contains(entry)) {
      _listEntries[listName] = [...currentEntries, entry];
    }
    if (listName == 'watchlist') {
      _watchlistIds.add(item.id.toString());
    }
    notifyListeners();

    try {
      await repository.addToList(item, listName);
      if (listName == 'watchlist' && item.canBeNotified) {
        unawaited(repository.toggleNotification(item, autoNotify: true));
      }
      _listPreviews[listName] = await repository.getListPreviews(listName);
      notifyListeners();
    } catch (e) {
      _listEntries[listName] = currentEntries.where((e) => e != entry).toList();
      if (listName == 'watchlist') {
        _watchlistIds.remove(item.id.toString());
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addAllToList(List<MediaItem> items, String listName) async {
    if (items.isEmpty) return;
    final currentEntries =
        _listEntries[listName] ?? await repository.getListEntries(listName);
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
    notifyListeners();

    try {
      await repository.addAllToList(items, listName);
      if (listName == 'watchlist') {
        for (final item in items) {
          if (item.canBeNotified) {
            unawaited(repository.toggleNotification(item, autoNotify: true));
          }
        }
      }
      _listPreviews[listName] = await repository.getListPreviews(listName);
      notifyListeners();
    } catch (e) {
      _listEntries[listName] = [...currentEntries];
      if (listName == 'watchlist') {
        for (final item in items) {
          if (!currentEntries.contains('${item.id}:${item.mediaType.name}')) {
            _watchlistIds.remove(item.id.toString());
          }
        }
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFromList(MediaItem item, String listName) async {
    final entry = '${item.id}:${item.mediaType.name}';
    final currentEntries =
        _listEntries[listName] ?? await repository.getListEntries(listName);

    _listEntries[listName] = currentEntries.where((e) => e != entry).toList();
    if (listName == 'watchlist') {
      _watchlistIds.remove(item.id.toString());
    }
    notifyListeners();

    try {
      await repository.removeFromList(item.id, item.mediaType, listName);
      _listPreviews[listName] = await repository.getListPreviews(listName);
      notifyListeners();
    } catch (e) {
      _listEntries[listName] = [...currentEntries];
      if (listName == 'watchlist') {
        _watchlistIds.add(item.id.toString());
      }
      notifyListeners();
      rethrow;
    }
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
    notifyListeners();
  }

  Future<void> updateListOrder(
    String listName,
    List<String> orderedEntries,
  ) async {
    await repository.updateListOrder(listName, orderedEntries);
    _listEntries[listName] = orderedEntries;
    _listPreviews[listName] = await repository.getListPreviews(listName);
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
    await loadAllListEntries();
    notifyListeners();
  }

  List<String> getListEntriesCached(String listName) {
    return _listEntries[listName] ?? [];
  }

  @override
  List<MediaItemPreview> getPreviewsForList(String name) {
    return _listPreviews[name] ?? [];
  }

  int getListItemCount(String name) {
    return _listEntries[name]?.length ?? 0;
  }

  static MediaType listEntryType(String entry) =>
      entry.endsWith(':tv') ? MediaType.tv : MediaType.movie;

  @override
  List<String> getListEntriesOfType(String listName, MediaType? type) {
    final entries = _listEntries[listName] ?? const <String>[];
    if (type == null) return entries;
    return entries.where((entry) => listEntryType(entry) == type).toList();
  }

  int countListEntries(MediaType? type) {
    var count = 0;
    for (final name in _listNames) {
      count += getListEntriesOfType(name, type).length;
    }
    return count;
  }

  @override
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
}
