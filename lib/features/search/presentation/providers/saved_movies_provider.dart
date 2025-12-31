import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mediavore/features/search/data/models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedMoviesProvider extends ChangeNotifier {
  static const _savedMoviesKey = 'saved_movies';

  List<Movie> _savedMovies = [];
  List<Movie> get savedMovies => _savedMovies;

  SavedMoviesProvider() {
    _loadSavedMovies();
  }

  Future<void> _loadSavedMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMoviesJson = prefs.getStringList(_savedMoviesKey) ?? [];
    _savedMovies = savedMoviesJson
        .map((json) => Movie.fromJson(jsonDecode(json)))
        .toList();
    notifyListeners();
  }

  Future<void> _saveMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMoviesJson =
        _savedMovies.map((movie) => jsonEncode(movie.toJson())).toList();
    await prefs.setStringList(_savedMoviesKey, savedMoviesJson);
  }

  bool isMovieSaved(Movie movie) {
    return _savedMovies.any((savedMovie) => savedMovie.id == movie.id);
  }

  void toggleMovieSaved(Movie movie) {
    if (isMovieSaved(movie)) {
      _savedMovies.removeWhere((savedMovie) => savedMovie.id == movie.id);
    } else {
      _savedMovies.add(movie);
    }
    _saveMovies();
    notifyListeners();
  }
}
