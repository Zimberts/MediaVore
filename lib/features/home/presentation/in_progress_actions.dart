import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// Marks the next episode of [item] as seen and reports it with "Undo".
Future<void> markInProgressEpisodeSeen(
  BuildContext context,
  InProgressItem item,
) async {
  final l10n = context.l10n;
  final provider = context.read<SearchProvider>();
  final episode = l10n.homeEpisodeCode(item.seasonNumber, item.episodeNumber);
  try {
    final undo = await provider.markNextEpisodeSeen(item);
    showAppMessage(
      l10n.homeEpisodeSeenMessage(episode, item.title ?? l10n.commonUnknown),
      actionLabel: l10n.commonUndo,
      onAction: () async {
        try {
          await undo();
        } catch (e) {
          debugPrint('[InProgress] undo mark as seen failed: $e');
        }
      },
    );
  } catch (e) {
    debugPrint('[InProgress] mark as seen failed: $e');
  }
}

/// Opens the detail page of the series of [item].
Future<void> openInProgressSeries(
  BuildContext context,
  InProgressItem item,
) async {
  final provider = context.read<SearchProvider>();
  MediaItem media;
  try {
    media = (await provider.getMediaDetails(item.tmdbId, MediaType.tv)).item;
  } catch (_) {
    // Offline or without a key: the page loads what it can by itself.
    media = MediaItem(
      id: item.tmdbId,
      title: item.title ?? '',
      posterPath: item.posterPath,
      overview: '',
      releaseDate: '',
      mediaType: MediaType.tv,
    );
  }
  if (context.mounted) await MediaDetailPage.show(context, media);
}

/// Removes the series of [item] from Quick Add (it leaves "In progress") and
/// reports it with "Undo", which puts the same entry back.
Future<void> removeInProgressFromQuickAdd(
  BuildContext context,
  InProgressItem item,
) async {
  final l10n = context.l10n;
  final provider = context.read<SearchProvider>();
  final next = item.next;
  try {
    await provider.optOutSeries(
      next.tmdbId,
      seasonNumber: next.seasonNumber,
      episodeNumber: next.episodeNumber,
    );
    showAppMessage(
      l10n.inProgressRemovedMessage,
      actionLabel: l10n.commonUndo,
      onAction: () async {
        try {
          await provider.clearOptOutSeries(
            next.tmdbId,
            seasonNumber: next.seasonNumber,
            episodeNumber: next.episodeNumber,
          );
          // Restore the exact entry that was removed.
          await provider.addQuickAddItem(next);
        } catch (e) {
          debugPrint('[InProgress] undo quick add opt-out failed: $e');
        }
      },
    );
  } catch (e) {
    debugPrint('[InProgress] quick add opt-out failed: $e');
  }
}
