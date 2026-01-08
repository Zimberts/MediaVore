import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// A button that allows users to add/remove an item from their watchlist.
/// 
/// @deprecated Use [MediaListManager] instead for full list support.
class WatchlistButton extends StatefulWidget {
  final MediaRepository mediaRepository;
  final int itemId;
  final MediaType mediaType;
  final String title;
  final String? posterPath;

  const WatchlistButton({
    super.key,
    required this.mediaRepository,
    required this.itemId,
    required this.title,
    this.posterPath,
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
      final item = MediaItem(
        id: widget.itemId,
        title: widget.title,
        overview: '',
        posterPath: widget.posterPath,
        releaseDate: '',
        mediaType: widget.mediaType,
      );
      await widget.mediaRepository.addToWatchlist(item);
    }
    _checkIfAdded();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    final colors = context.appColors;
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: _toggleWatchlist,
      icon: Icon(_isAdded ? Icons.check : Icons.add),
      label: Text(_isAdded ? 'On Watchlist' : 'Add to Watchlist'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isAdded ? colors.onWatchlist : theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
