import 'package:isar_community/isar.dart';

part 'notified_item_model.g.dart';

@collection
class NotifiedItemModel {
  Id? isarId;

  @Index(unique: true, composite: [CompositeIndex('type')])
  final int tmdbId;

  final String type; // 'movie' or 'tv'

  final String title;

  final String? posterPath;

  final DateTime? releaseDate;

  final int? seasonNumber;

  final int? episodeNumber;

  final int? runtime;

  final bool autoNotify; // If it was added automatically via watchlist

  /// When this entry's release data was last reconciled with TMDB.
  ///
  /// Used to throttle network refreshes (at most once per day per series) so
  /// the Releases list stays fresh without hammering the API.
  final DateTime? lastRefreshedAt;

  NotifiedItemModel({
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    this.releaseDate,
    this.seasonNumber,
    this.episodeNumber,
    this.runtime,
    this.autoNotify = false,
    this.lastRefreshedAt,
  });
}
