import 'package:isar/isar.dart';

part 'liked_item.g.dart';

@collection
class LikedItem {
  Id? isarId;

  @Index(composite: [CompositeIndex('type')], unique: true)
  final int tmdbId;

  final String type; // 'movie' or 'tv'

  final String title;

  LikedItem({
    required this.tmdbId,
    required this.type,
    required this.title,
  });
}
