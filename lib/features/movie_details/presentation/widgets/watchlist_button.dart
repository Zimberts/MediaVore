import 'package:flutter/material.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';

class WatchlistButton extends StatefulWidget {
  final MovieRepository movieRepository;
  final int movieId;

  const WatchlistButton({
    super.key,
    required this.movieRepository,
    required this.movieId,
  });

  @override
  State<WatchlistButton> createState() => _WatchlistButtonState();
}

class _WatchlistButtonState extends State<WatchlistButton> {
  bool _isAdded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfAdded();
  }

  Future<void> _checkIfAdded() async {
    setState(() {
      _isLoading = true;
    });
    final isAdded = await widget.movieRepository.isMovieInWatchlist(widget.movieId);
    if (mounted) {
      setState(() {
        _isAdded = isAdded;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    if (_isAdded) {
      await widget.movieRepository.removeMovieFromWatchlist(widget.movieId);
    } else {
      await widget.movieRepository.addMovieToWatchlist(widget.movieId);
    }
    _checkIfAdded();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    return ElevatedButton.icon(
      onPressed: _toggleWatchlist,
      icon: Icon(_isAdded ? Icons.check : Icons.add),
      label: Text(_isAdded ? 'On Watchlist' : 'Add to Watchlist'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isAdded ? Colors.green : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
