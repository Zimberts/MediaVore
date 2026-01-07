import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class WatchNextButton extends StatefulWidget {
  final MediaItem item;
  final VoidCallback? onSeenChanged;

  const WatchNextButton({super.key, required this.item, this.onSeenChanged});

  @override
  State<WatchNextButton> createState() => _WatchNextButtonState();
}

class _WatchNextButtonState extends State<WatchNextButton> {
  ({int seasonNumber, int episodeNumber})? _nextEpisode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNextEpisode();
  }

  Future<void> _loadNextEpisode() async {
    if (widget.item.mediaType != MediaType.tv) return;
    
    setState(() => _isLoading = true);
    final provider = context.read<SearchProvider>();
    final next = await provider.getNextEpisode(widget.item.id);
    
    if (mounted) {
      setState(() {
        _nextEpisode = next;
        _isLoading = false;
      });
    }
  }

  Future<void> _markNextAsSeen() async {
    if (_nextEpisode == null) return;

    final provider = context.read<SearchProvider>();
    await provider.markAsSeen(SeenItem(
      tmdbId: widget.item.id,
      type: MediaType.tv,
      title: widget.item.title,
      posterPath: widget.item.posterPath,
      seenDate: DateTime.now(),
      seasonNumber: _nextEpisode!.seasonNumber,
      episodeNumber: _nextEpisode!.episodeNumber,
    ));

    widget.onSeenChanged?.call();
    _loadNextEpisode();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.mediaType != MediaType.tv) return const SizedBox.shrink();
    if (_isLoading) return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    if (_nextEpisode == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: _markNextAsSeen,
        icon: const Icon(Icons.play_arrow),
        label: Text('Watch Next: S${_nextEpisode!.seasonNumber} E${_nextEpisode!.episodeNumber}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
