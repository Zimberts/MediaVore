import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';

@lazySingleton
class MediaListLocalDataSource {
  final Isar _isar;

  MediaListLocalDataSource(this._isar);

  Future<void> addToList({
    required int id,
    required String type,
    required String listName,
    required String title,
    String? posterPath,
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
          posterPath: posterPath,
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
      // We allow multiple seen entries for the same item now.
      // Always create a new record.
      await _isar.seenItemModels.put(item);
    });
  }

  Future<void> removeFromSeen(int tmdbId, String type, {int? seasonNumber, int? episodeNumber}) async {
    await _isar.writeTxn(() async {
      // Removing "seen" status for a specific item (movie or episode)
      // currently deletes ALL history entries for that item.
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
  
  /// Deletes a specific seen entry by its Isar ID.
  Future<void> deleteSeenEntry(int isarId) async {
    await _isar.writeTxn(() async {
      await _isar.seenItemModels.delete(isarId);
    });
  }
}
