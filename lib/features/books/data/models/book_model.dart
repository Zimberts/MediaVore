import 'package:isar/isar.dart';

part 'book_model.g.dart';

@collection
class BookModel {
  Id? isarId;

  @Index(unique: true)
  final String isbn;

  final String title;

  final List<String> authors;

  final String? coverUrl;

  final String? publisher;

  final int? publishYear;

  final int? pageCount;

  final String? description;

  final DateTime dateAdded;

  /// 0 = unread, 1 = reading, 2 = read
  int readStatus;

  final DateTime? readDate;

  BookModel({
    required this.isbn,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.publisher,
    this.publishYear,
    this.pageCount,
    this.description,
    required this.dateAdded,
    this.readStatus = 0,
    this.readDate,
  });
}
