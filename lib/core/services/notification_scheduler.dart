import 'package:flutter/services.dart';
// Avoid platform timezone plugin to reduce Android build issues; use DateTime UTC timestamps.

import '../../features/media_details/data/models/notified_item_model.dart';

class NotificationScheduler {
  NotificationScheduler._privateConstructor();
  static final NotificationScheduler instance = NotificationScheduler._privateConstructor();

  static const MethodChannel _channel = MethodChannel('mediavore/notifications');

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // No-op: we rely on `DateTime` epoch millis (UTC) for scheduling on platform side.
    _initialized = true;
  }

  int _notificationIdFor(NotifiedItemModel item) {
    var id = item.tmdbId.abs();
    if (item.seasonNumber != null) id = id * 100 + item.seasonNumber!;
    if (item.episodeNumber != null) id = id * 100 + item.episodeNumber!;
    return id;
  }

  Future<void> scheduleForNotifiedItem(NotifiedItemModel item) async {
    if (item.releaseDate == null) return;

    final scheduled = item.releaseDate!;
    final now = DateTime.now();
    if (scheduled.isBefore(now)) return;

    final id = _notificationIdFor(item);
    final title = item.title;
    final body = item.seasonNumber != null && item.episodeNumber != null
        ? 'S${item.seasonNumber}E${item.episodeNumber} is out'
        : 'New release available';

    await _channel.invokeMethod('scheduleNotification', {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': scheduled.toUtc().millisecondsSinceEpoch,
    });
  }

  Future<void> cancelForNotifiedItem(NotifiedItemModel item) async {
    final id = _notificationIdFor(item);
    await _channel.invokeMethod('cancelNotification', {'id': id});
  }

  Future<void> rescheduleAll(Iterable<NotifiedItemModel> items) async {
    for (final item in items) {
      await cancelForNotifiedItem(item);
      if (item.releaseDate != null) await scheduleForNotifiedItem(item);
    }
  }

  Future<List<Map<String, dynamic>>> pending() async {
    // Not implemented on platform channel; return empty list
    return [];
  }
}
