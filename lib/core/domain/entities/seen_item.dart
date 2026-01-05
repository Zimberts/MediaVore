import 'package:equatable/equatable.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

class SeenItem extends Equatable {
  final int? id; // Local database ID
  final int tmdbId;
  final MediaType type;
  final String title;
  final String? posterPath;
  final DateTime seenDate;
  final int? seasonNumber;
  final int? episodeNumber;

  const SeenItem({
    this.id,
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    required this.seenDate,
    this.seasonNumber,
    this.episodeNumber,
  });

  @override
  List<Object?> get props => [
        id,
        tmdbId,
        type,
        title,
        posterPath,
        seenDate,
        seasonNumber,
        episodeNumber,
      ];
}
