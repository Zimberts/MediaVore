import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mediavore/features/movie_details/data/models/cast_member.dart';
import 'package:mediavore/features/movie_details/data/models/crew_member.dart';
import 'package:mediavore/features/movie_details/data/models/movie_details.dart';
import 'package:mediavore/features/movie_details/presentation/widgets/watchlist_button.dart';
import 'package:mediavore/features/search/data/models/movie.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  MovieDetails? _movieDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovieDetails();
  }

  Future<void> _fetchMovieDetails() async {
    final token = dotenv.env['TMDB_API_TOKEN'];
    final url = Uri.parse(
        'https://api.themoviedb.org/3/movie/${widget.movie.id}/credits');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List castResults = data['cast'];
        final List crewResults = data['crew'];

        final List<CastMember> cast =
            castResults.map((c) => CastMember.fromJson(c)).toList();
        final List<CrewMember> crew =
            crewResults.map((c) => CrewMember.fromJson(c)).toList();

        final CrewMember? director = crew.firstWhere(
          (member) => member.job == 'Director',
          orElse: () => CrewMember(name: 'N/A', job: 'Director'),
        );

        setState(() {
          _movieDetails = MovieDetails(
            movie: widget.movie,
            cast: cast,
            director: director,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load movie details')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movieDetails == null
              ? const Center(child: Text('Could not load movie details.'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.movie.posterPath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w500${widget.movie.posterPath}',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 250,
                              color: Colors.grey,
                              child: const Center(
                                child: Icon(Icons.movie, size: 100),
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Release Date: ${widget.movie.releaseDate}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            if (_movieDetails!.director != null)
                              Text(
                                'Director: ${_movieDetails!.director!.name}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            const SizedBox(height: 16),
                            Text(
                              widget.movie.overview,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Cast',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _movieDetails!.cast.length,
                                itemBuilder: (context, index) {
                                  final member = _movieDetails!.cast[index];
                                  return Container(
                                    width: 100,
                                    margin:
                                        const EdgeInsets.only(right: 12.0),
                                    child: Column(
                                      children: [
                                        member.profilePath != null
                                            ? CircleAvatar(
                                                radius: 40,
                                                backgroundImage: NetworkImage(
                                                    'https://image.tmdb.org/t/p/w185${member.profilePath}'),
                                              )
                                            : const CircleAvatar(
                                                radius: 40,
                                                child: Icon(Icons.person),
                                              ),
                                        const SizedBox(height: 4),
                                        Text(
                                          member.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Center(
                              child: WatchlistButton(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
