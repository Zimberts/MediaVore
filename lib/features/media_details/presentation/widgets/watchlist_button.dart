import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

class WatchlistButton extends StatefulWidget {
  final MediaRepository mediaRepository;
  final int itemId;
  final MediaType mediaType;

  const WatchlistButton({
    super.key,
    required this.mediaRepository,
    required this.itemId,
    this.mediaType = MediaType.movie,
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
    final isAdded = await widget.mediaRepository.isInWatchlist(widget.itemId, widget.mediaType);
    if (mounted) {
      setState(() {
        _isAdded = isAdded;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    if (_isAdded) {
      await widget.mediaRepository.removeFromWatchlist(widget.itemId, widget.mediaType);
    } else {
      await widget.mediaRepository.addToWatchlist(widget.itemId, widget.mediaType);
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
