import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

@lazySingleton
class MediaListLocalDataSource {
  final Isar _isar;

  MediaListLocalDataSource(this._isar);

  Future<void> addToList({
    required int id,
    required String type,
    required String listName,
    required String title,
  }) async {
    await _isar.writeTxn(
      () =>
          _addToListInTxn(id: id, type: type, listName: listName, title: title),
    );
  }

  /// Must run inside a write transaction.
  Future<void> _addToListInTxn({
    required int id,
    required String type,
    required String listName,
    required String title,
  }) async {
    final existing = await _isar.mediaListItems
        .filter()
        .idEqualTo(id)
        .typeEqualTo(type)
        .listNameEqualTo(listName)
        .findFirst();

    if (existing == null) {
      final maxItem = await _isar.mediaListItems
          .filter()
          .listNameEqualTo(listName)
          .sortByPositionDesc()
          .findFirst();
      final nextPosition = maxItem != null ? maxItem.position + 1 : 0;

      final item = MediaListItem(
        id: id,
        type: type,
        listName: listName,
        title: title,
        position: nextPosition,
      );
      await _isar.mediaListItems.put(item);
    }
  }

  Future<void> removeFromList(int id, String type, String listName) async {
    await _isar.writeTxn(() async {
      await _isar.mediaListItems
          .filter()
          .idEqualTo(id)
          .typeEqualTo(type)
          .listNameEqualTo(listName)
          .deleteAll();
    });
  }

  Future<List<MediaListItem>> getListItems(String listName) async {
    return await _isar.mediaListItems
        .filter()
        .listNameEqualTo(listName)
        .sortByPosition()
        .findAll();
  }

  Future<List<String>> getListEntries(String listName) async {
    final items = await getListItems(listName);
    return items.map((item) => '${item.id}:${item.type}').toList();
  }

  Future<void> updateListOrder(
    String listName,
    List<String> orderedEntries,
  ) async {
    await _isar.writeTxn(() async {
      for (int i = 0; i < orderedEntries.length; i++) {
        final parts = orderedEntries[i].split(':');
        final id = int.parse(parts[0]);
        final type = parts[1];

        final item = await _isar.mediaListItems
            .filter()
            .idEqualTo(id)
            .typeEqualTo(type)
            .listNameEqualTo(listName)
            .findFirst();

        if (item != null) {
          item.position = i;
          await _isar.mediaListItems.put(item);
        }
      }
    });
  }

  Future<List<String>> getAllListNames() async {
    final lists = await _isar.userLists.where().findAll();
    final names = lists.map((l) => l.name).toList();
    if (!names.contains('watchlist')) {
      names.insert(0, 'watchlist');
    }
    return names;
  }

  Future<void> createList(String name) async {
    await _isar.writeTxn(() => _createListInTxn(name));
  }

  /// Must run inside a write transaction.
  Future<void> _createListInTxn(String name) async {
    final existing = await _isar.userLists
        .filter()
        .nameEqualTo(name)
        .findFirst();
    if (existing == null) {
      await _isar.userLists.put(UserList(name: name));
    }
  }

  Future<void> deleteList(String name) async {
    if (name.toLowerCase() == 'watchlist') return; // Cannot delete watchlist
    await _isar.writeTxn(() async {
      await _isar.userLists.filter().nameEqualTo(name).deleteAll();
      await _isar.mediaListItems.filter().listNameEqualTo(name).deleteAll();
    });
  }

  // Seen Items methods
  Future<void> markAsSeen(SeenItemModel item) async {
    await _isar.writeTxn(() async {
      await _isar.seenItemModels.put(item);
    });
  }

  Future<void> removeFromSeen(
    int tmdbId,
    String type, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _isar.writeTxn(() async {
      await _isar.seenItemModels
          .filter()
          .tmdbIdEqualTo(tmdbId)
          .typeEqualTo(type)
          .seasonNumberEqualTo(seasonNumber)
          .episodeNumberEqualTo(episodeNumber)
          .deleteAll();
    });
  }

  Future<List<SeenItemModel>> getAllSeenItems() async {
    return await _isar.seenItemModels
        .where()
        .sortBySeenDateDesc()
        .thenBySeasonNumberDesc()
        .thenByEpisodeNumberDesc()
        .findAll();
  }

  Future<List<SeenItemModel>> getSeenStatus(int tmdbId, String type) async {
    return await _isar.seenItemModels
        .filter()
        .tmdbIdEqualTo(tmdbId)
        .typeEqualTo(type)
        .findAll();
  }

  Future<void> deleteSeenEntry(int isarId) async {
    await _isar.writeTxn(() async {
      await _isar.seenItemModels.delete(isarId);
    });
  }

  Future<SeenItemModel?> getSeenEntryByIsarId(int isarId) async {
    return await _isar.seenItemModels.get(isarId);
  }

  Future<void> updatePosterPath(
    int tmdbId,
    String type,
    String posterPath,
  ) async {
    await _isar.writeTxn(() async {
      final items = await _isar.seenItemModels
          .filter()
          .tmdbIdEqualTo(tmdbId)
          .typeEqualTo(type, caseSensitive: false)
          .findAll();

      for (final item in items) {
        if (item.posterPath == null || item.posterPath!.isEmpty) {
          final updated = SeenItemModel(
            tmdbId: item.tmdbId,
            type: item.type,
            title: item.title,
            posterPath: posterPath,
            seenDate: item.seenDate,
            seasonNumber: item.seasonNumber,
            episodeNumber: item.episodeNumber,
          );
          updated.isarId = item.isarId;
          await _isar.seenItemModels.put(updated);
        }
      }
    });
  }

  Future<List<SeenItemModel>> getExportData({
    DateTime? start,
    DateTime? end,
    int? tmdbId,
    String? type,
  }) async {
    if (start == null && end == null && tmdbId == null && type == null) {
      return await _isar.seenItemModels.where().findAll();
    }

    var query = _isar.seenItemModels.filter().isarIdIsNotNull();

    if (start != null) {
      query = query.and().seenDateGreaterThan(start, include: true);
    }
    if (end != null) {
      query = query.and().seenDateLessThan(end, include: true);
    }
    if (tmdbId != null) {
      query = query.and().tmdbIdEqualTo(tmdbId);
    }
    if (type != null) {
      query = query.and().typeEqualTo(type);
    }

    return await query.findAll();
  }

  Future<void> importSeenItems(
    List<SeenItemModel> items, {
    required ImportMode mode,
  }) async {
    await _isar.writeTxn(() => _importSeenInTxn(items, mode));
  }

  /// Must run inside a write transaction.
  Future<void> _importSeenInTxn(
    List<SeenItemModel> items,
    ImportMode mode,
  ) async {
    if (mode == ImportMode.replace) {
      await _isar.seenItemModels.clear();
    }
    if (mode == ImportMode.replace || mode == ImportMode.append) {
      await _isar.seenItemModels.putAll(items);
    } else if (mode == ImportMode.merge) {
      for (final item in items) {
        final existing = await _isar.seenItemModels
            .filter()
            .tmdbIdEqualTo(item.tmdbId)
            .typeEqualTo(item.type)
            .seasonNumberEqualTo(item.seasonNumber)
            .episodeNumberEqualTo(item.episodeNumber)
            .seenDateBetween(
              item.seenDate.subtract(const Duration(seconds: 1)),
              item.seenDate.add(const Duration(seconds: 1)),
            )
            .findFirst();

        if (existing == null) {
          await _isar.seenItemModels.put(item);
        }
      }
    }
  }

  Future<int> getSeenDbSize() async {
    return await _isar.seenItemModels.getSize();
  }

  // Like methods
  Future<void> toggleLike({
    required int tmdbId,
    required String type,
    required String title,
  }) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.likedItems
          .filter()
          .tmdbIdEqualTo(tmdbId)
          .typeEqualTo(type)
          .findFirst();

      if (existing != null) {
        await _isar.likedItems.delete(existing.isarId!);
      } else {
        await _isar.likedItems.put(
          LikedItem(tmdbId: tmdbId, type: type, title: title),
        );
      }
    });
  }

  Future<bool> isLiked(int tmdbId, String type) async {
    final count = await _isar.likedItems
        .filter()
        .tmdbIdEqualTo(tmdbId)
        .typeEqualTo(type)
        .count();
    return count > 0;
  }

  Future<List<LikedItem>> getLikedItems() async {
    return await _isar.likedItems.where().findAll();
  }

  // Notification methods
  Future<void> toggleNotification({
    required int tmdbId,
    required String type,
    required String title,
    String? posterPath,
    DateTime? releaseDate,
    int? seasonNumber,
    int? episodeNumber,
    int? runtime,
    bool autoNotify = false,
  }) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.notifiedItemModels
          .filter()
          .tmdbIdEqualTo(tmdbId)
          .typeEqualTo(type)
          .findFirst();

      if (existing != null) {
        if (!autoNotify) {
          await _isar.notifiedItemModels.delete(existing.isarId!);
        } else if (releaseDate != null) {
          final updated = NotifiedItemModel(
            tmdbId: tmdbId,
            type: type,
            title: title,
            posterPath: posterPath ?? existing.posterPath,
            releaseDate: releaseDate,
            seasonNumber: seasonNumber ?? existing.seasonNumber,
            episodeNumber: episodeNumber ?? existing.episodeNumber,
            runtime: runtime ?? existing.runtime,
            autoNotify: existing.autoNotify,
            lastRefreshedAt: existing.lastRefreshedAt,
          );
          updated.isarId = existing.isarId;
          await _isar.notifiedItemModels.put(updated);
        }
      } else {
        await _isar.notifiedItemModels.put(
          NotifiedItemModel(
            tmdbId: tmdbId,
            type: type,
            title: title,
            posterPath: posterPath,
            releaseDate: releaseDate,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            runtime: runtime,
            autoNotify: autoNotify,
          ),
        );
      }
    });
  }

  Future<void> updateNotificationDate(
    int tmdbId,
    String type,
    DateTime date, {
    int? seasonNumber,
    int? episodeNumber,
    int? runtime,
  }) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.notifiedItemModels
          .filter()
          .tmdbIdEqualTo(tmdbId)
          .typeEqualTo(type)
          .findFirst();

      if (existing != null) {
        final updated = NotifiedItemModel(
          tmdbId: existing.tmdbId,
          type: existing.type,
          title: existing.title,
          posterPath: existing.posterPath,
          releaseDate: date,
          seasonNumber: seasonNumber ?? existing.seasonNumber,
          episodeNumber: episodeNumber ?? existing.episodeNumber,
          runtime: runtime ?? existing.runtime,
          autoNotify: existing.autoNotify,
          lastRefreshedAt: existing.lastRefreshedAt,
        );
        updated.isarId = existing.isarId;
        await _isar.notifiedItemModels.put(updated);
      }
    });
  }

  /// Sets the episode a notified entry points at, allowing a `null` release
  /// date so an announced-but-undated episode can be shown as "date TBA".
  ///
  /// Unlike [updateNotificationDate], passing `null` here clears the field
  /// instead of preserving the previous value.
  Future<void> setNotificationEpisode(
    int tmdbId,
    String type, {
    required int? seasonNumber,
    required int? episodeNumber,
    required DateTime? releaseDate,
    int? runtime,
  }) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.notifiedItemModels
          .filter()
          .tmdbIdEqualTo(tmdbId)
          .typeEqualTo(type)
          .findFirst();

      if (existing != null) {
        final updated = NotifiedItemModel(
          tmdbId: existing.tmdbId,
          type: existing.type,
          title: existing.title,
          posterPath: existing.posterPath,
          releaseDate: releaseDate,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          runtime: runtime,
          autoNotify: existing.autoNotify,
          lastRefreshedAt: existing.lastRefreshedAt,
        );
        updated.isarId = existing.isarId;
        await _isar.notifiedItemModels.put(updated);
      }
    });
  }

  /// Rewrites the notified entry for [tmdbId]/[type] so it no longer points at a
  /// specific episode: the release date, season, episode and runtime are cleared
  /// (a `null` date otherwise cannot be stored through [updateNotificationDate]).
  ///
  /// Used when a series is caught up but has a new season planned, so the UI
  /// renders "Returning — new season planned" instead of a stale episode.
  Future<void> markNotificationAsReturning(int tmdbId, String type) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.notifiedItemModels
          .filter()
          .tmdbIdEqualTo(tmdbId)
          .typeEqualTo(type)
          .findFirst();

      if (existing != null) {
        final updated = NotifiedItemModel(
          tmdbId: existing.tmdbId,
          type: existing.type,
          title: existing.title,
          posterPath: existing.posterPath,
          releaseDate: null,
          seasonNumber: null,
          episodeNumber: null,
          runtime: null,
          autoNotify: existing.autoNotify,
          lastRefreshedAt: existing.lastRefreshedAt,
        );
        updated.isarId = existing.isarId;
        await _isar.notifiedItemModels.put(updated);
      }
    });
  }

  /// Stamps when the notified entry for [tmdbId]/[type] was last refreshed from
  /// the network, driving the once-a-day refresh throttle.
  Future<void> markNotifiedRefreshed(
    int tmdbId,
    String type,
    DateTime at,
  ) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.notifiedItemModels
          .filter()
          .tmdbIdEqualTo(tmdbId)
          .typeEqualTo(type)
          .findFirst();

      if (existing != null) {
        final updated = NotifiedItemModel(
          tmdbId: existing.tmdbId,
          type: existing.type,
          title: existing.title,
          posterPath: existing.posterPath,
          releaseDate: existing.releaseDate,
          seasonNumber: existing.seasonNumber,
          episodeNumber: existing.episodeNumber,
          runtime: existing.runtime,
          autoNotify: existing.autoNotify,
          lastRefreshedAt: at,
        );
        updated.isarId = existing.isarId;
        await _isar.notifiedItemModels.put(updated);
      }
    });
  }

  Future<NotifiedItemModel?> getNotifiedItem(int tmdbId, String type) async {
    return await _isar.notifiedItemModels
        .filter()
        .tmdbIdEqualTo(tmdbId)
        .typeEqualTo(type)
        .findFirst();
  }

  Future<bool> isNotified(int tmdbId, String type) async {
    final count = await _isar.notifiedItemModels
        .filter()
        .tmdbIdEqualTo(tmdbId)
        .typeEqualTo(type)
        .count();
    return count > 0;
  }

  // QuickAdd methods
  Future<List<QuickAddItemModel>> getQuickAddItems() async {
    return await _isar.quickAddItemModels
        .where()
        .sortByInsertedAtDesc()
        .findAll();
  }

  Future<void> addQuickAddItem(QuickAddItemModel item) async {
    await _isar.writeTxn(() async {
      // avoid duplicates for same tmdb/season/episode
      final existingCount = await _isar.quickAddItemModels
          .filter()
          .tmdbIdEqualTo(item.tmdbId)
          .seasonNumberEqualTo(item.seasonNumber)
          .episodeNumberEqualTo(item.episodeNumber)
          .count();
      if (existingCount == 0) {
        await _isar.quickAddItemModels.put(item);
      }
    });
  }

  Future<void> updateQuickAddItemRuntime(int isarId, int? runtime) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.quickAddItemModels.get(isarId);
      if (existing != null) {
        final updated = QuickAddItemModel(
          tmdbId: existing.tmdbId,
          type: existing.type,
          seasonNumber: existing.seasonNumber,
          episodeNumber: existing.episodeNumber,
          insertedAt: existing.insertedAt,
          airDate: existing.airDate,
          title: existing.title,
          posterPath: existing.posterPath,
          runtime: runtime,
        );
        updated.isarId = existing.isarId;
        await _isar.quickAddItemModels.put(updated);
      }
    });
  }

  Future<void> removeQuickAddItemById(int isarId) async {
    await _isar.writeTxn(() async {
      await _isar.quickAddItemModels.delete(isarId);
    });
  }

  Future<void> removeQuickAddItemsByTmdb(int tmdbId) async {
    await _isar.writeTxn(() async {
      await _isar.quickAddItemModels.filter().tmdbIdEqualTo(tmdbId).deleteAll();
    });
  }

  Future<void> clearQuickAddItems() async {
    await _isar.writeTxn(() async {
      await _isar.quickAddItemModels.clear();
    });
  }

  Future<void> removeQuickAddItemByTmdbSeasonEpisode(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _isar.writeTxn(() async {
      var query = _isar.quickAddItemModels.filter().tmdbIdEqualTo(tmdbId);
      if (seasonNumber != null) {
        query = query.seasonNumberEqualTo(seasonNumber);
      }
      if (episodeNumber != null) {
        query = query.episodeNumberEqualTo(episodeNumber);
      }
      await query.deleteAll();
    });
  }

  // Opt-out methods
  Future<void> addOptOut(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _isar.writeTxn(() async {
      final existingQuery = _isar.quickAddOptOutModels.filter().tmdbIdEqualTo(
        tmdbId,
      );
      final existing = await (seasonNumber != null && episodeNumber != null
          ? existingQuery
                .and()
                .seasonNumberEqualTo(seasonNumber)
                .episodeNumberEqualTo(episodeNumber)
                .findFirst()
          : existingQuery.findFirst());

      if (existing == null) {
        await _isar.quickAddOptOutModels.put(
          QuickAddOptOutModel(
            tmdbId: tmdbId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            optedOutAt: DateTime.now(),
          ),
        );
      }

      // remove only quick-add entries matching this streak (if provided) or the tmdbId+nulls
      var q = _isar.quickAddItemModels.filter().tmdbIdEqualTo(tmdbId);
      if (seasonNumber != null) q = q.seasonNumberEqualTo(seasonNumber);
      if (episodeNumber != null) q = q.episodeNumberEqualTo(episodeNumber);
      await q.deleteAll();
    });
  }

  Future<void> removeOptOut(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    await _isar.writeTxn(() async {
      var q = _isar.quickAddOptOutModels.filter().tmdbIdEqualTo(tmdbId);
      if (seasonNumber != null) q = q.and().seasonNumberEqualTo(seasonNumber);
      if (episodeNumber != null) {
        q = q.and().episodeNumberEqualTo(episodeNumber);
      }
      await q.deleteAll();
    });
  }

  Future<bool> isOptedOut(
    int tmdbId, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    var q = _isar.quickAddOptOutModels.filter().tmdbIdEqualTo(tmdbId);
    if (seasonNumber != null) q = q.and().seasonNumberEqualTo(seasonNumber);
    if (episodeNumber != null) q = q.and().episodeNumberEqualTo(episodeNumber);
    final count = await q.count();
    return count > 0;
  }

  Future<List<NotifiedItemModel>> getNotifiedItems() async {
    return await _isar.notifiedItemModels.where().findAll();
  }

  Stream<void> watchNotifiedItems() {
    return _isar.notifiedItemModels.watchLazy();
  }

  Future<void> importLikedItems(
    List<LikedItem> items, {
    required ImportMode mode,
    Function(double progress, String status)? onProgress,
  }) async {
    await _isar.writeTxn(() => _importLikedInTxn(items, mode, onProgress));
  }

  /// Must run inside a write transaction.
  Future<void> _importLikedInTxn(
    List<LikedItem> items,
    ImportMode mode,
    Function(double progress, String status)? onProgress,
  ) async {
    if (mode == ImportMode.replace) {
      await _isar.likedItems.clear();
    }
    if (mode == ImportMode.replace || mode == ImportMode.append) {
      for (int i = 0; i < items.length; i++) {
        onProgress?.call(i / items.length, 'Importing likes...');
      }
      await _isar.likedItems.putAll(items);
    } else if (mode == ImportMode.merge) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        onProgress?.call(i / items.length, 'Processing like ${i + 1}');
        final existing = await _isar.likedItems
            .filter()
            .tmdbIdEqualTo(item.tmdbId)
            .typeEqualTo(item.type)
            .findFirst();
        if (existing == null) {
          await _isar.likedItems.put(item);
        }
      }
    }
  }

  Future<void> importNotifiedItems(
    List<NotifiedItemModel> items, {
    required ImportMode mode,
    Function(double progress, String status)? onProgress,
  }) async {
    await _isar.writeTxn(() => _importNotifiedInTxn(items, mode, onProgress));
  }

  /// Must run inside a write transaction.
  Future<void> _importNotifiedInTxn(
    List<NotifiedItemModel> items,
    ImportMode mode,
    Function(double progress, String status)? onProgress,
  ) async {
    if (mode == ImportMode.replace) {
      await _isar.notifiedItemModels.clear();
    }
    if (mode == ImportMode.replace || mode == ImportMode.append) {
      for (int i = 0; i < items.length; i++) {
        onProgress?.call(i / items.length, 'Importing notifications...');
      }
      await _isar.notifiedItemModels.putAll(items);
    } else if (mode == ImportMode.merge) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        onProgress?.call(i / items.length, 'Processing notification ${i + 1}');
        final existing = await _isar.notifiedItemModels
            .filter()
            .tmdbIdEqualTo(item.tmdbId)
            .typeEqualTo(item.type)
            .findFirst();
        if (existing == null) {
          await _isar.notifiedItemModels.put(item);
        }
      }
    }
  }

  Future<void> importListsData(
    Map<String, List<MediaListItem>> lists, {
    required ImportMode mode,
    Function(double progress, String status)? onProgress,
  }) async {
    await _isar.writeTxn(() => _importListsInTxn(lists, mode, onProgress));
  }

  /// Must run inside a write transaction.
  Future<void> _importListsInTxn(
    Map<String, List<MediaListItem>> lists,
    ImportMode mode,
    Function(double progress, String status)? onProgress,
  ) async {
    if (mode == ImportMode.replace) {
      await _isar.mediaListItems.where().deleteAll();
      await _isar.userLists.where().deleteAll();
    }

    int i = 0;
    for (final entry in lists.entries) {
      onProgress?.call(i / lists.length, 'Importing list ${i + 1}');
      await _createListInTxn(entry.key);
      for (final item in entry.value) {
        // _addToListInTxn avoids duplicates
        await _addToListInTxn(
          id: item.id,
          type: item.type,
          listName: entry.key,
          title: item.title,
        );
      }
      i++;
    }
  }

  Future<void> importQuickAddItems(
    List<QuickAddItemModel> items, {
    required ImportMode mode,
    Function(double progress, String status)? onProgress,
  }) async {
    await _isar.writeTxn(() => _importQuickAddInTxn(items, mode, onProgress));
  }

  /// Must run inside a write transaction.
  Future<void> _importQuickAddInTxn(
    List<QuickAddItemModel> items,
    ImportMode mode,
    Function(double progress, String status)? onProgress,
  ) async {
    if (mode == ImportMode.replace) {
      await _isar.quickAddItemModels.clear();
    }
    if (mode == ImportMode.replace || mode == ImportMode.append) {
      for (int i = 0; i < items.length; i++) {
        onProgress?.call(i / items.length, 'Importing quick add...');
      }
      await _isar.quickAddItemModels.putAll(items);
    } else if (mode == ImportMode.merge) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        onProgress?.call(i / items.length, 'Processing quick add ${i + 1}');
        final existing = await _isar.quickAddItemModels
            .filter()
            .tmdbIdEqualTo(item.tmdbId)
            .seasonNumberEqualTo(item.seasonNumber)
            .episodeNumberEqualTo(item.episodeNumber)
            .findFirst();
        if (existing == null) {
          await _isar.quickAddItemModels.put(item);
        }
      }
    }
  }

  /// Imports every collection in a single write transaction, so a failure at
  /// any stage rolls back the whole import and leaves the database unchanged.
  ///
  /// Empty collections are skipped (they are not cleared in replace mode).
  Future<void> importAll({
    required ImportMode mode,
    List<SeenItemModel> seen = const [],
    List<LikedItem> likes = const [],
    List<NotifiedItemModel> notifications = const [],
    List<QuickAddItemModel> quickAdd = const [],
    Map<String, List<MediaListItem>> lists = const {},
  }) async {
    await _isar.writeTxn(() async {
      if (seen.isNotEmpty) await _importSeenInTxn(seen, mode);
      if (likes.isNotEmpty) await _importLikedInTxn(likes, mode, null);
      if (notifications.isNotEmpty) {
        await _importNotifiedInTxn(notifications, mode, null);
      }
      if (quickAdd.isNotEmpty) await _importQuickAddInTxn(quickAdd, mode, null);
      if (lists.isNotEmpty) await _importListsInTxn(lists, mode, null);
    });
  }
}
