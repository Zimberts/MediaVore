import 'package:isar/isar.dart';

part 'book_list_item_model.g.dart';

@collection
class BookListItemModel {
  Id? isarId;

  @Index(composite: [CompositeIndex('listName')], unique: true)
  final String isbn;

  final String listName;

  int position;

  BookListItemModel({
    required this.isbn,
    required this.listName,
    this.position = 0,
  });
}
