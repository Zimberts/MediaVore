import 'package:equatable/equatable.dart';

/// Domain entity representing remote book metadata from Open Library.
class Book extends Equatable {
  /// ISBN-13 (preferred) or ISBN-10 when available.
  final String? isbn;

  /// Open Library work or edition key (e.g. `/works/OL45804W`).
  final String? openLibraryKey;

  /// Book title.
  final String title;

  /// Author display names. Empty when none were reported.
  final List<String> authors;

  /// Open Library author keys (e.g. `/authors/OL23919A`).
  final List<String> authorKeys;

  /// URL to the book cover image, if available.
  final String? coverUrl;

  /// Primary publisher name, if available.
  final String? publisher;

  /// Four-digit publication year, if available.
  final int? publishYear;

  /// Number of pages, if available.
  final int? pageCount;

  /// Synopsis / description, if available.
  final String? description;

  /// Subject / genre tags reported by Open Library.
  final List<String> subjects;

  /// Language code (e.g. `eng`, `fre`), if available.
  final String? language;

  const Book({
    this.isbn,
    this.openLibraryKey,
    required this.title,
    this.authors = const [],
    this.authorKeys = const [],
    this.coverUrl,
    this.publisher,
    this.publishYear,
    this.pageCount,
    this.description,
    this.subjects = const [],
    this.language,
  });

  /// Comma-separated list of author names.
  String get authorsDisplay => authors.join(', ');

  /// Returns a copy of this [Book] with the given fields replaced.
  Book copyWith({
    String? isbn,
    String? openLibraryKey,
    String? title,
    List<String>? authors,
    List<String>? authorKeys,
    String? coverUrl,
    String? publisher,
    int? publishYear,
    int? pageCount,
    String? description,
    List<String>? subjects,
    String? language,
  }) {
    return Book(
      isbn: isbn ?? this.isbn,
      openLibraryKey: openLibraryKey ?? this.openLibraryKey,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      authorKeys: authorKeys ?? this.authorKeys,
      coverUrl: coverUrl ?? this.coverUrl,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      pageCount: pageCount ?? this.pageCount,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
    isbn,
    openLibraryKey,
    title,
    authors,
    authorKeys,
    coverUrl,
    publisher,
    publishYear,
    pageCount,
    description,
    subjects,
    language,
  ];
}
