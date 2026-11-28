import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/cache/cached_media.dart';
import 'package:mediavore/features/achievements/data/models/achievement_model.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';
import 'package:mediavore/features/media_details/data/models/user_list.dart';
import 'package:path_provider/path_provider.dart';

@module
abstract class DatabaseModule {
  @preResolve
  @singleton
  Future<Isar> get isar async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open([
      UserListSchema,
      MediaListItemSchema,
      SeenItemModelSchema,
      LikedItemSchema,
      NotifiedItemModelSchema,
      QuickAddItemModelSchema,
      QuickAddOptOutModelSchema,
      SwipeDecisionModelSchema,
      CachedMediaSchema,
      CachedActorProfileSchema,
      CachedSeasonSchema,
      AchievementModelSchema,
    ], directory: dir.path);
  }
}

/// Returns `true` when the local Isar database already holds user data
/// (lists, list items, seen history, likes, notifications, or swipe decisions).
bool hasExistingUserDataInIsar(Isar isar) {
  if (isar.seenItemModels.countSync() > 0) return true;
  if (isar.mediaListItems.countSync() > 0) return true;
  if (isar.likedItems.countSync() > 0) return true;
  if (isar.notifiedItemModels.countSync() > 0) return true;
  if (isar.swipeDecisionModels.countSync() > 0) return true;
  final lists = isar.userLists.where().findAllSync();
  for (final list in lists) {
    if (list.name != 'watchlist') return true;
  }
  return false;
}
