import 'package:isar/isar.dart';

part 'media_list_item.g.dart';

@collection
class MediaListItem {
  Id? isarId;

  @Index(composite: [CompositeIndex('type'), CompositeIndex('listName')], unique: true)
  final int id;

  final String type;

  final String listName;
  
  final String title;

  int position;

  MediaListItem({
    required this.id,
    required this.type,
    required this.title,
    this.listName = 'watchlist',
    this.position = 0,
  });
}
