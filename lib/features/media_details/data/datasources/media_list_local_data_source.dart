import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
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
    await _isar.writeTxn(() async {
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
    });
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
    await _isar.writeTxn(() async {
      final existing = await _isar.userLists
          .filter()
          .nameEqualTo(name)
          .findFirst();
      if (existing == null) {
        await _isar.userLists.put(UserList(name: name));
      }
    });
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
    if (mode == ImportMode.replace) {
      await _isar.writeTxn(() async {
        await _isar.seenItemModels.clear();
      });
    }

    await _isar.writeTxn(() async {
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
    });
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
            autoNotify: existing.autoNotify,
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
          autoNotify: existing.autoNotify,
        );
        updated.isarId = existing.isarId;
        await _isar.notifiedItemModels.put(updated);
      }
    });
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
    final total = items.length;

    if (mode == ImportMode.replace) {
      await _isar.writeTxn(() async {
        await _isar.likedItems.clear();
      });
    }

    if (mode == ImportMode.replace || mode == ImportMode.append) {
      for (int i = 0; i < items.length; i++) {
        if (onProgress != null) onProgress(i / total, 'Importing likes...');
      }

      await _isar.writeTxn(() async {
        await _isar.likedItems.putAll(items);
      });
    } else if (mode == ImportMode.merge) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (onProgress != null) {
          onProgress(i / total, 'Processing like ${i + 1}');
        }
        final existing = await _isar.likedItems
            .filter()
            .tmdbIdEqualTo(item.tmdbId)
            .typeEqualTo(item.type)
            .findFirst();
        if (existing == null) {
          await _isar.writeTxn(() async {
            await _isar.likedItems.put(item);
          });
        }
      }
    }
  }

  Future<void> importNotifiedItems(
    List<NotifiedItemModel> items, {
    required ImportMode mode,
    Function(double progress, String status)? onProgress,
  }) async {
    final total = items.length;

    if (mode == ImportMode.replace) {
      await _isar.writeTxn(() async {
        await _isar.notifiedItemModels.clear();
      });
    }

    if (mode == ImportMode.replace || mode == ImportMode.append) {
      for (int i = 0; i < items.length; i++) {
        if (onProgress != null) {
          onProgress(i / total, 'Importing notifications...');
        }
      }

      await _isar.writeTxn(() async {
        await _isar.notifiedItemModels.putAll(items);
      });
    } else if (mode == ImportMode.merge) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (onProgress != null) {
          onProgress(i / total, 'Processing notification ${i + 1}');
        }
        final existing = await _isar.notifiedItemModels
            .filter()
            .tmdbIdEqualTo(item.tmdbId)
            .typeEqualTo(item.type)
            .findFirst();
        if (existing == null) {
          await _isar.writeTxn(() async {
            await _isar.notifiedItemModels.put(item);
          });
        }
      }
    }
  }

  Future<void> importListsData(
    Map<String, List<MediaListItem>> lists, {
    required ImportMode mode,
    Function(double progress, String status)? onProgress,
  }) async {
    final total = lists.length;

    if (mode == ImportMode.replace) {
      // delete all user-created lists except watchlist
      await _isar.writeTxn(() async {
        await _isar.mediaListItems.where().deleteAll();
        await _isar.userLists.where().deleteAll();
      });
    }

    int i = 0;
    for (final entry in lists.entries) {
      if (onProgress != null) onProgress(i / total, 'Importing list ${i + 1}');
      final name = entry.key;
      final items = entry.value;

      // ensure list exists
      await createList(name);

      for (final item in items) {
        // addToList avoids duplicates
        await addToList(
          id: item.id,
          type: item.type,
          listName: name,
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
    final total = items.length;

    if (mode == ImportMode.replace) {
      await _isar.writeTxn(() async {
        await _isar.quickAddItemModels.clear();
      });
    }

    if (mode == ImportMode.replace || mode == ImportMode.append) {
      for (int i = 0; i < items.length; i++) {
        if (onProgress != null) onProgress(i / total, 'Importing quick add...');
      }

      await _isar.writeTxn(() async {
        await _isar.quickAddItemModels.putAll(items);
      });
    } else if (mode == ImportMode.merge) {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (onProgress != null) {
          onProgress(i / total, 'Processing quick add ${i + 1}');
        }
        final existing = await _isar.quickAddItemModels
            .filter()
            .tmdbIdEqualTo(item.tmdbId)
            .seasonNumberEqualTo(item.seasonNumber)
            .episodeNumberEqualTo(item.episodeNumber)
            .findFirst();
        if (existing == null) {
          await _isar.writeTxn(() async {
            await _isar.quickAddItemModels.put(item);
          });
        }
      }
    }
  }
}
