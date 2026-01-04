import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class SeenManager extends StatefulWidget {
  final int tmdbId;
  final MediaType type;
  final String title;
  final String? posterPath;
  final int? seasonNumber;
  final int? episodeNumber;
  final VoidCallback? onSeenChanged;

  const SeenManager({
    super.key,
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    this.seasonNumber,
    this.episodeNumber,
    this.onSeenChanged,
  });

  @override
  State<SeenManager> createState() => _SeenManagerState();
}

class _SeenManagerState extends State<SeenManager> {
  bool _isSeen = false;
  DateTime _seenDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSeenStatus();
  }

  Future<void> _checkSeenStatus() async {
    // We use the repository directly for the specific episode/movie details
    // but the provider will handle the global counts for the list/search screens.
    final provider = context.read<SearchProvider>();
    final status = await provider.loadSeenStatusForItem(widget.tmdbId, widget.type);
    
    if (mounted) {
      setState(() {
        final match = status.where((s) => 
          s.seasonNumber == widget.seasonNumber && 
          s.episodeNumber == widget.episodeNumber
        );
        
        _isSeen = match.isNotEmpty;
        if (_isSeen) {
          _seenDate = match.first.seenDate;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSeen() async {
    final provider = context.read<SearchProvider>();
    
    if (_isSeen) {
      await provider.removeFromSeen(
        widget.tmdbId,
        widget.type,
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
      );
    } else {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: _seenDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        helpText: 'When did you see this?',
      );

      if (pickedDate != null) {
        await provider.markAsSeen(SeenItem(
          tmdbId: widget.tmdbId,
          type: widget.type,
          title: widget.title,
          posterPath: widget.posterPath,
          seenDate: pickedDate,
          seasonNumber: widget.seasonNumber,
          episodeNumber: widget.episodeNumber,
        ));
      } else {
        return;
      }
    }

    _checkSeenStatus();
    widget.onSeenChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));

    return IconButton(
      icon: Icon(
        _isSeen ? Icons.visibility : Icons.visibility_off,
        color: _isSeen ? Theme.of(context).primaryColor : Colors.grey,
      ),
      onPressed: _toggleSeen,
      tooltip: _isSeen ? 'Mark as not seen' : 'Mark as seen',
    );
  }
}
