import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';

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
}
