import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../data/models/movie.dart';

class SearchPage extends StatefulWidget {
  final http.Client? httpClient;
  const SearchPage({super.key, this.httpClient});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _movies = [];
  bool _isLoading = false;

  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final token = dotenv.env['TMDB_API_TOKEN'];
    final url = Uri.parse('https://api.themoviedb.org/3/search/movie?query=${Uri.encodeComponent(query)}');

    try {
      final client = widget.httpClient ?? http.Client();
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
        setState(() {
          _movies = results.map((m) => Movie.fromJson(m)).toList();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load movies')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaVore Search'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movies.isEmpty
              ? const Center(child: Text('Search for movies!'))
              : ListView.builder(
                  itemCount: _movies.length,
                  itemBuilder: (context, index) {
                    final movie = _movies[index];
                    return ListTile(
                      leading: movie.posterPath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.movie),
                            )
                          : const Icon(Icons.movie),
                      title: Text(movie.title),
                      subtitle: Text(
                        movie.releaseDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search movie names...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _searchMovies(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchMovies(_searchController.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
