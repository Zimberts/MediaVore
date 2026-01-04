import 'package:isar/isar.dart';

part 'watchlist_item.g.dart';

@collection
class WatchlistItem {
  Id? isarId;

  @Index(unique: true, composite: [CompositeIndex('type')])
  final int id;

  final String type;

  WatchlistItem({
    required this.id,
    required this.type,
  });
}
