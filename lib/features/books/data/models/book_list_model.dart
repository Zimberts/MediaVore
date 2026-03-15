import 'package:isar/isar.dart';

part 'book_list_model.g.dart';

@collection
class BookListModel {
  Id? isarId;

  @Index(unique: true)
  final String name;

  final DateTime dateCreated;

  BookListModel({
    required this.name,
    required this.dateCreated,
  });
}
