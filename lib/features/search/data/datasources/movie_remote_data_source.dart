import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mediavore/core/domain/entities/movie.dart';

/// Handles data fetching from the TMDB API.
class MovieRemoteDataSource {
  final http.Client client;

  /// Creates a new instance of [MovieRemoteDataSource].
  ///
  /// Requires an [http.Client] to make network requests.
  MovieRemoteDataSource({required this.client});

  /// Searches for movies on the TMDB API.
  Future<List<Movie>> searchMovies(String query) async {
    final token = dotenv.env['TMDB_API_TOKEN'];
    final url = Uri.parse('https://api.themoviedb.org/3/search/movie?query=${Uri.encodeComponent(query)}');

    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((m) => Movie.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load movies');
    }
  }

  /// Fetches the details for a single movie from the TMDB API.
  Future<Movie> getMovie(int movieId) async {
    final token = dotenv.env['TMDB_API_TOKEN'];
    final url = Uri.parse('https://api.themoviedb.org/3/movie/$movieId');

    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie');
    }
  }

  /// Fetches the credits (cast and crew) for a single movie from the TMDB API.
  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    final token = dotenv.env['TMDB_API_TOKEN'];
    final url = Uri.parse('https://api.themoviedb.org/3/movie/$movieId/credits');

    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load movie credits');
    }
  }
}
