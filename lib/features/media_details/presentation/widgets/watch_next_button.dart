import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/widgets/app_message.dart';
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
  bool _isCompleted = false;
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
    final isComplete =
        next == null && await provider.isSeriesCompleted(widget.item);

    if (mounted) {
      setState(() {
        _nextEpisode = next;
        _isCompleted = isComplete;
        _isLoading = false;
      });
    }
  }

  Future<void> _markNextAsSeen() async {
    if (_nextEpisode == null) return;

    final provider = context.read<SearchProvider>();
    await provider.markAsSeen(
      SeenItem(
        tmdbId: widget.item.id,
        type: MediaType.tv,
        title: widget.item.title,
        posterPath: widget.item.posterPath,
        seenDate: DateTime.now(),
        seasonNumber: _nextEpisode!.seasonNumber,
        episodeNumber: _nextEpisode!.episodeNumber,
      ),
    );

    widget.onSeenChanged?.call();
    _loadNextEpisode();
  }

  Future<void> _startRewatch() async {
    final provider = context.read<SearchProvider>();
    final l10n = context.l10n;
    final cycle = await provider.startSeriesRewatch(widget.item);

    showAppMessage(
      l10n.rewatchStartedMessage(cycle.toString()),
      actionLabel: l10n.commonUndo,
      onAction: () async {
        await provider.cancelSeriesRewatch(widget.item.id);
        widget.onSeenChanged?.call();
        _loadNextEpisode();
      },
    );

    widget.onSeenChanged?.call();
    _loadNextEpisode();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.mediaType != MediaType.tv) return const SizedBox.shrink();
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_nextEpisode != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton.icon(
          onPressed: _markNextAsSeen,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            context.l10n.watchNext(
              _nextEpisode!.seasonNumber,
              _nextEpisode!.episodeNumber,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.success,
            foregroundColor: contrastingForeground(context.appColors.success),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      );
    }

    if (_isCompleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton.icon(
          onPressed: _startRewatch,
          icon: const Icon(Icons.replay),
          label: Text(context.l10n.rewatchSeriesAction),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.series,
            foregroundColor: contrastingForeground(context.appColors.series),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
