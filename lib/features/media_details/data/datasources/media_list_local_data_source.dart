import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
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
        final item = MediaListItem(
          id: id,
          type: type,
          listName: listName,
          title: title,
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
        .findAll();
  }

  Future<List<String>> getListEntries(String listName) async {
    final items = await getListItems(listName);
    return items.map((item) => '${item.id}:${item.type}').toList();
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
      final existing = await _isar.userLists.filter().nameEqualTo(name).findFirst();
      if (existing == null) {
        await _isar.userLists.put(UserList(name: name));
      }
    });
  }

  Future<void> deleteList(String name) async {
    if (name == 'watchlist') return; // Cannot delete watchlist
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

  Future<void> removeFromSeen(int tmdbId, String type, {int? seasonNumber, int? episodeNumber}) async {
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

  Future<void> importSeenItems(List<SeenItemModel> items, {required ImportMode mode}) async {
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
                item.seenDate.add(const Duration(seconds: 1))
              )
              .findFirst();
          
          if (existing == null) {
            await _isar.seenItemModels.put(item);
          }
        }
      }
    });
  }

  /// Returns the approximate size of the "Seen" database collection in bytes.
  Future<int> getSeenDbSize() async {
    return await _isar.seenItemModels.getSize();
  }
}
