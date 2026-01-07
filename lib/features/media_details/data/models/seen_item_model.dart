import 'package:isar/isar.dart';

part 'seen_item_model.g.dart';

@collection
class SeenItemModel {
  Id? isarId;

  final int tmdbId;

  final String type; // 'movie' or 'tv'

  final String title;

  final String? posterPath;

  final DateTime seenDate;

  final int? seasonNumber;

  final int? episodeNumber;

  SeenItemModel({
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    required this.seenDate,
    this.seasonNumber,
    this.episodeNumber,
  });
}
