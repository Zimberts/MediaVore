import 'package:isar/isar.dart';

part 'quick_add_opt_out_model.g.dart';

@collection
class QuickAddOptOutModel {
  Id? isarId;

  final int tmdbId;

  final int? seasonNumber;
  final int? episodeNumber;

  final DateTime optedOutAt;

  QuickAddOptOutModel({
    this.isarId,
    required this.tmdbId,
    this.seasonNumber,
    this.episodeNumber,
    required this.optedOutAt,
  });
}
