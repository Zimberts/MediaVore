import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/features/media_details/data/models/watchlist_item.dart';

@module
abstract class DatabaseModule {
  @preResolve
  @singleton
  Future<Isar> get isar async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [WatchlistItemSchema],
      directory: dir.path,
    );
  }
}
