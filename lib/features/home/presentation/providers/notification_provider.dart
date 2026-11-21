import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Provider dedicated to series tracking, release reminders and notifications.
class NotificationProvider with ChangeNotifier {
  NotificationProvider(this.repository) {
    unawaited(init());
  }

  final MediaRepository repository;

  List<NotifiedItem> _notifiedItems = [];
  bool _isNotifiedRefreshing = false;
  StreamSubscription<void>? _notifiedItemsSubscription;

  List<NotifiedItem> get notifiedItems => _notifiedItems;
  bool get isNotifiedRefreshing => _isNotifiedRefreshing;

  Future<void> init() async {
    await loadNotifiedItems();
    _notifiedItemsSubscription = repository.watchNotifiedItems().listen((_) {
      unawaited(loadNotifiedItems());
    });
  }

  @override
  void dispose() {
    _notifiedItemsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadNotifiedItems() async {
    _notifiedItems = await repository.getNotifiedItems();
    notifyListeners();
  }

  bool isNotified(MediaItem item) {
    return _notifiedItems.any(
      (n) => n.tmdbId == item.id && n.type == item.mediaType,
    );
  }

  Future<void> toggleNotification(MediaItem item) async {
    await repository.toggleNotification(item);
    await loadNotifiedItems();
  }

  Future<void> refreshNotifiedItems({bool force = false}) async {
    _isNotifiedRefreshing = true;
    notifyListeners();
    try {
      await loadNotifiedItems();
      await repository.refreshNotifiedItems(force: force);
      await loadNotifiedItems();
    } finally {
      _isNotifiedRefreshing = false;
      notifyListeners();
    }
  }

  MediaItem _releaseShell(NotifiedItem item) => MediaItem(
    id: item.tmdbId,
    title: item.title,
    posterPath: item.posterPath,
    overview: '',
    releaseDate: item.releaseDate?.toIso8601String() ?? '',
    mediaType: item.type,
  );

  /// Stops following the release [item]: it leaves "Upcoming". Returns the
  /// action that follows it again, as it was (manual or automatic).
  Future<Future<void> Function()> disableReleaseAlert(NotifiedItem item) async {
    final shell = _releaseShell(item);
    await repository.toggleNotification(shell);
    await loadNotifiedItems();

    return () async {
      if (!await repository.isNotified(item.tmdbId, item.type)) {
        await repository.toggleNotification(shell, autoNotify: item.autoNotify);
      }
      await loadNotifiedItems();
    };
  }

  static bool _sameInstant(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute &&
      a.second == b.second;

  /// Marks a notified release as seen, returning an undo closure.
  Future<Future<void> Function()> markReleaseSeen(NotifiedItem item) async {
    final seenDate = DateTime.now();
    final isEpisode = item.type == MediaType.tv;

    await repository.markAsSeen(
      SeenItem(
        tmdbId: item.tmdbId,
        type: item.type,
        title: item.title,
        posterPath: item.posterPath,
        seenDate: seenDate,
        seasonNumber: isEpisode ? item.seasonNumber : null,
        episodeNumber: isEpisode ? item.episodeNumber : null,
        runtime: item.runtime,
      ),
    );

    // Refresh the title to find the next milestone to announce.
    try {
      await repository.getMediaDetails(item.tmdbId, type: item.type);
    } catch (e) {
      debugPrint('[NotificationProvider] markReleaseSeen refresh failed: $e');
    }
    await loadNotifiedItems();

    return () async {
      final viewings = await repository.getSeenStatus(item.tmdbId, item.type);
      for (final viewing in viewings) {
        final id = viewing.id;
        if (id != null && _sameInstant(viewing.seenDate, seenDate)) {
          await repository.deleteSeenEntry(id);
        }
      }

      if (isEpisode) {
        for (final queued in await repository.getQuickAddItems()) {
          final id = queued.isarId;
          if (id != null &&
              queued.tmdbId == item.tmdbId &&
              _sameInstant(queued.insertedAt, seenDate)) {
            await repository.removeQuickAddItemById(id);
          }
        }
        await repository.populateQuickAddFromSeenHistory(tmdbId: item.tmdbId);
      }

      await loadNotifiedItems();
    };
  }
}
