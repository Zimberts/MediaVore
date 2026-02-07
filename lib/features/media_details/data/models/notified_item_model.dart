import 'package:isar/isar.dart';

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

  final bool autoNotify; // If it was added automatically via watchlist

  NotifiedItemModel({
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    this.releaseDate,
    this.seasonNumber,
    this.episodeNumber,
    this.autoNotify = false,
  });
}
