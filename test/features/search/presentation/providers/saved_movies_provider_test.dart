import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/data/models/movie.dart';
import 'package:mediavore/features/search/presentation/providers/saved_movies_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SavedMoviesProvider', () {
    late SavedMoviesProvider savedMoviesProvider;
    late SharedPreferences sharedPreferences;

    final movie = Movie(
      id: 1,
      title: 'Test Movie',
      overview: 'Test Overview',
      posterPath: '/test.jpg',
      releaseDate: '2022-01-01',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      savedMoviesProvider = SavedMoviesProvider();
      await Future.microtask(() {}); // Allow provider to load from prefs
    });

    test('is initially empty', () {
      expect(savedMoviesProvider.savedMovies.isEmpty, true);
    });

    test('adds a movie', () async {
      savedMoviesProvider.toggleMovieSaved(movie);
      expect(savedMoviesProvider.savedMovies.contains(movie), true);
    });

    test('removes a movie', () {
      savedMoviesProvider.toggleMovieSaved(movie);
      savedMoviesProvider.toggleMovieSaved(movie);
      expect(savedMoviesProvider.savedMovies.contains(movie), false);
    });

    test('isMovieSaved returns correct value', () {
      expect(savedMoviesProvider.isMovieSaved(movie), false);
      savedMoviesProvider.toggleMovieSaved(movie);
      expect(savedMoviesProvider.isMovieSaved(movie), true);
    });

    test('loads saved movies from SharedPreferences', () async {
      final movieJson = jsonEncode(movie.toJson());
      await sharedPreferences.setStringList('saved_movies', [movieJson]);

      final newProvider = SavedMoviesProvider();
      await Future.microtask(() {}); 

      expect(newProvider.savedMovies.length, 1);
      expect(newProvider.savedMovies.first, movie);
    });
  });
}
