import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/features/media_details/data/models/watchlist_item.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';

@module
abstract class DatabaseModule {
  @preResolve
  @singleton
  Future<Isar> get isar async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [
        WatchlistItemSchema,
        UserListSchema,
        MediaListItemSchema,
        SeenItemModelSchema,
      ],
      directory: dir.path,
    );
  }
}
