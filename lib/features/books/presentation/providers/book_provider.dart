import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mediavore/features/books/domain/repositories/book_repository.dart';

@injectable
class BookProvider extends ChangeNotifier {
  final BookRepository _repository;

  BookProvider(this._repository) {
    loadBooks();
    loadLists();
  }

  // ── State ──

  List<Book> _books = [];
  List<Book> get books => _books;

  List<BookList> _lists = [];
  List<BookList> get lists => _lists;

  List<Book> _searchResults = [];
  List<Book> get searchResults => _searchResults;

  List<Book> _currentListBooks = [];
  List<Book> get currentListBooks => _currentListBooks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _error;
  String? get error => _error;

  ReadStatus? _filterStatus;
  ReadStatus? get filterStatus => _filterStatus;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ── Books ──

  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_filterStatus != null) {
        _books = await _repository.getBooksByReadStatus(_filterStatus!);
      } else {
        _books = await _repository.getAllBooks();
      }
    } catch (e) {
      _error = 'Erreur lors du chargement des livres: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(ReadStatus? status) {
    _filterStatus = status;
    loadBooks();
  }

  Future<void> addBook(Book book) async {
    try {
      await _repository.addBook(book);
      await loadBooks();
      await loadLists();
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du livre: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> deleteBook(String isbn) async {
    try {
      await _repository.deleteBook(isbn);
      await loadBooks();
      await loadLists();
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> updateReadStatus(String isbn, ReadStatus status) async {
    try {
      await _repository.updateReadStatus(isbn, status);
      await loadBooks();
    } catch (e) {
      _error = 'Erreur lors de la mise à jour: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<Book?> getBookByIsbn(String isbn) async {
    return await _repository.getBookByIsbn(isbn);
  }

  // ── Remote Search ──

  Future<void> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchRemoteBooks(query);
    } catch (e) {
      _error = 'Erreur de recherche: $e';
      debugPrint(_error);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<Book?> fetchBookByIsbn(String isbn) async {
    try {
      return await _repository.fetchBookByIsbn(isbn);
    } catch (e) {
      _error = 'Livre introuvable pour l\'ISBN: $isbn';
      debugPrint(_error);
      notifyListeners();
      return null;
    }
  }

  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  // ── Book Lists ──

  Future<void> loadLists() async {
    try {
      _lists = await _repository.getAllLists();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading lists: $e');
    }
  }

  Future<void> createList(String name) async {
    try {
      await _repository.createList(name);
      await loadLists();
    } catch (e) {
      _error = 'Erreur lors de la création de la liste: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> deleteList(String name) async {
    try {
      await _repository.deleteList(name);
      await loadLists();
    } catch (e) {
      _error = 'Erreur lors de la suppression de la liste: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> loadListBooks(String listName) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentListBooks = await _repository.getListBooks(listName);
    } catch (e) {
      debugPrint('Error loading list books: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBookToList(String isbn, String listName) async {
    try {
      await _repository.addBookToList(isbn, listName);
      await loadLists();
      await loadListBooks(listName);
    } catch (e) {
      _error = 'Erreur lors de l\'ajout à la liste: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> removeBookFromList(String isbn, String listName) async {
    try {
      await _repository.removeBookFromList(isbn, listName);
      await loadLists();
      await loadListBooks(listName);
    } catch (e) {
      _error = 'Erreur lors du retrait de la liste: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<List<String>> getListsForBook(String isbn) async {
    try {
      return await _repository.getListsForBook(isbn);
    } catch (e) {
      return [];
    }
  }

  Future<bool> isBookInList(String isbn, String listName) async {
    return await _repository.isBookInList(isbn, listName);
  }

  int get totalBookCount => _books.length;

  int get readCount => _books.where((b) => b.readStatus == ReadStatus.read).length;

  int get readingCount => _books.where((b) => b.readStatus == ReadStatus.reading).length;

  int get unreadCount => _books.where((b) => b.readStatus == ReadStatus.unread).length;
}
