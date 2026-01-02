import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/movie.dart';
import 'package:mediavore/core/domain/entities/movie_details.dart';
import 'package:mediavore/features/movie_details/presentation/widgets/watchlist_button.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';

/// A page that displays the details of a specific movie.
class MovieDetailPage extends StatefulWidget {
  /// The movie to display.
  final Movie movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late final MovieRepository _movieRepository;
  MovieDetails? _movieDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _movieRepository = locator<MovieRepository>();
    _fetchMovieDetails();
  }

  /// Fetches the movie details from the repository.
  Future<void> _fetchMovieDetails() async {
    try {
      final movieDetails = await _movieRepository.getMovieDetails(widget.movie.id);
      if (mounted) {
        setState(() {
          _movieDetails = movieDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Use addPostFrameCallback to show snackbar after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load movie details: $e')),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final movieToDisplay = _movieDetails?.movie ?? widget.movie;
    
    // Check for Android and attempt to detect button navigation mode.
    // Gesture navigation usually has a non-zero systemGestureInsets.bottom.
    // Button navigation often has a larger padding.bottom (around 48) if edge-to-edge, 
    // or 0 if not edge-to-edge.
    final mediaQuery = MediaQuery.of(context);
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final bool isAndroidButtons = isAndroid && 
        (mediaQuery.systemGestureInsets.bottom < 8 || mediaQuery.padding.bottom > 30);

    return Scaffold(
      appBar: AppBar(
        title: Text(movieToDisplay.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  movieToDisplay.posterPath != null && !Platform.environment.containsKey('FLUTTER_TEST')
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w500${movieToDisplay.posterPath}',
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
                          movieToDisplay.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Release Date: ${movieToDisplay.releaseDate}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        if (_movieDetails?.director != null)
                          Text(
                            'Director: ${_movieDetails!.director!.name}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        const SizedBox(height: 16),
                        Text(
                          movieToDisplay.overview,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_movieDetails == null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load additional details.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ] else ...[
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
                                      member.profilePath != null && !Platform.environment.containsKey('FLUTTER_TEST')
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
                        ],
                        const SizedBox(height: 24),
                        Center(
                          child: WatchlistButton(
                            movieRepository: _movieRepository,
                            movieId: movieToDisplay.id,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Extra padding at the bottom of the scrollable area for Android button navigation.
                  // This is placed outside the main padding to ensure it's at the very end.
                  if (isAndroidButtons) const SizedBox(height: 80) else const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
