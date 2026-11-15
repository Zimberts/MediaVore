import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

enum _ReleaseAction { disableAlert, openDetails }

/// Opens the detail page of the release [item].
Future<void> openRelease(BuildContext context, NotifiedItem item) async {
  final provider = context.read<SearchProvider>();
  MediaItem media;
  try {
    media = (await provider.getMediaDetails(item.tmdbId, item.type)).item;
  } catch (_) {
    // Offline or without a key: the page loads what it can by itself.
    media = MediaItem(
      id: item.tmdbId,
      title: item.title,
      posterPath: item.posterPath,
      overview: '',
      releaseDate: '',
      mediaType: item.type,
    );
  }
  if (context.mounted) await MediaDetailPage.show(context, media);
}

/// Marks the release [item] as seen and reports it with "Undo".
Future<void> markReleaseSeen(BuildContext context, NotifiedItem item) async {
  final l10n = context.l10n;
  final provider = context.read<SearchProvider>();
  try {
    final undo = await provider.markReleaseSeen(item);
    showAppMessage(
      l10n.upcomingSeenMessage(item.title),
      actionLabel: l10n.commonUndo,
      onAction: () async {
        try {
          await undo();
        } catch (e) {
          debugPrint('[Upcoming] undo mark as seen failed: $e');
        }
      },
    );
  } catch (e) {
    debugPrint('[Upcoming] mark as seen failed: $e');
  }
}

/// Stops following the release [item] and reports it with "Undo".
Future<void> disableReleaseAlert(
  BuildContext context,
  NotifiedItem item,
) async {
  final l10n = context.l10n;
  final provider = context.read<SearchProvider>();
  try {
    final undo = await provider.disableReleaseAlert(item);
    showAppMessage(
      l10n.upcomingAlertDisabledMessage(item.title),
      actionLabel: l10n.commonUndo,
      onAction: () async {
        try {
          await undo();
        } catch (e) {
          debugPrint('[Upcoming] undo disable alert failed: $e');
        }
      },
    );
  } catch (e) {
    debugPrint('[Upcoming] disable alert failed: $e');
  }
}

/// Menu of a release: disable its alert, open its detail page.
Future<void> showReleaseMenu(BuildContext context, NotifiedItem item) async {
  final l10n = context.l10n;
  final action = await showAppMenu<_ReleaseAction>(
    context: context,
    title: item.title,
    items: [
      AppMenuItem(
        value: _ReleaseAction.disableAlert,
        icon: Icons.notifications_off_outlined,
        label: l10n.upcomingDisableAlert,
        subtitle: l10n.upcomingDisableAlertSubtitle,
      ),
      AppMenuItem(
        value: _ReleaseAction.openDetails,
        icon: item.type == MediaType.tv ? Icons.tv : Icons.movie,
        label: l10n.inProgressOpenDetails,
      ),
    ],
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case _ReleaseAction.disableAlert:
      await disableReleaseAlert(context, item);
    case _ReleaseAction.openDetails:
      await openRelease(context, item);
  }
}
