import 'package:isar/isar.dart';

part 'quick_add_item_model.g.dart';

@collection
class QuickAddItemModel {
  Id? isarId;

  final int tmdbId;

  final String type;

  final int? seasonNumber;
  final int? episodeNumber;

  final DateTime insertedAt;
  final DateTime? airDate;

  final String? title;
  final String? posterPath;

  QuickAddItemModel({
    this.isarId,
    required this.tmdbId,
    required this.type,
    this.seasonNumber,
    this.episodeNumber,
    required this.insertedAt,
    this.airDate,
    this.title,
    this.posterPath,
  });
}
