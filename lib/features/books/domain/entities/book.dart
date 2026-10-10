import 'package:equatable/equatable.dart';

enum ReadStatus {
  unread,
  reading,
  read;

  String get label {
    switch (this) {
      case ReadStatus.unread:
        return 'À lire';
      case ReadStatus.reading:
        return 'En cours';
      case ReadStatus.read:
        return 'Lu';
    }
  }

  static ReadStatus fromIndex(int index) {
    if (index >= 0 && index < ReadStatus.values.length) {
      return ReadStatus.values[index];
    }
    return ReadStatus.unread;
  }
}

class Book extends Equatable {
  final String isbn;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final String? publisher;
  final int? publishYear;
  final int? pageCount;
  final String? description;
  final DateTime dateAdded;
  final ReadStatus readStatus;
  final DateTime? readDate;

  const Book({
    required this.isbn,
    required this.title,
    required this.authors,
    this.coverUrl,
    this.publisher,
    this.publishYear,
    this.pageCount,
    this.description,
    required this.dateAdded,
    this.readStatus = ReadStatus.unread,
    this.readDate,
  });

  Book copyWith({
    String? isbn,
    String? title,
    List<String>? authors,
    String? coverUrl,
    String? publisher,
    int? publishYear,
    int? pageCount,
    String? description,
    DateTime? dateAdded,
    ReadStatus? readStatus,
    DateTime? readDate,
  }) {
    return Book(
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      coverUrl: coverUrl ?? this.coverUrl,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      pageCount: pageCount ?? this.pageCount,
      description: description ?? this.description,
      dateAdded: dateAdded ?? this.dateAdded,
      readStatus: readStatus ?? this.readStatus,
      readDate: readDate ?? this.readDate,
    );
  }

  String get authorsDisplay => authors.join(', ');

  @override
  List<Object?> get props => [
        isbn,
        title,
        authors,
        coverUrl,
        publisher,
        publishYear,
        pageCount,
        description,
        dateAdded,
        readStatus,
        readDate,
      ];
}
