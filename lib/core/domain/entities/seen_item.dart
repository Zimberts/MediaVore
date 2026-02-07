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
  final int? runtime;
  final List<String>? genres;

  const SeenItem({
    this.id,
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    required this.seenDate,
    this.seasonNumber,
    this.episodeNumber,
    this.runtime,
    this.genres,
  });

  SeenItem copyWith({
    DateTime? seenDate,
    int? seasonNumber,
    int? episodeNumber,
    int? runtime,
    List<String>? genres,
  }) {
    return SeenItem(
      id: id,
      tmdbId: tmdbId,
      type: type,
      title: title,
      posterPath: posterPath,
      seenDate: seenDate ?? this.seenDate,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      runtime: runtime ?? this.runtime,
      genres: genres ?? this.genres,
    );
  }

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
    runtime,
    genres,
  ];
}
