import 'package:equatable/equatable.dart';

enum MediaType { movie, tv, person, unknown }

class MediaItem extends Equatable {
  final int id;
  final String title;
  final String? posterPath;
  final String overview;
  final String releaseDate;
  final MediaType mediaType;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final String? status;
  final List<String>? genres;
  final double? voteAverage;
  final int? runtime;

  const MediaItem({
    required this.id,
    required this.title,
    this.posterPath,
    required this.overview,
    required this.releaseDate,
    this.mediaType = MediaType.movie,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.status,
    this.genres,
    this.voteAverage,
    this.runtime,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final mediaTypeStr = json['media_type'] as String?;
    final mediaType = _parseMediaType(mediaTypeStr);

    List<String>? genresList;
    if (json['genres'] != null) {
      genresList = (json['genres'] as List)
          .map((g) => g['name'] as String)
          .toList();
    }

    return MediaItem(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? '',
      posterPath: json['poster_path'],
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      mediaType: mediaType,
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
      status: json['status'],
      genres: genresList,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      runtime: json['runtime'],
    );
  }

  static MediaType _parseMediaType(String? type) {
    switch (type) {
      case 'movie':
        return MediaType.movie;
      case 'tv':
        return MediaType.tv;
      case 'person':
        return MediaType.person;
      default:
        return MediaType.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'release_date': releaseDate,
      'media_type': mediaType.name,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
      'status': status,
      'genres': genres,
      'vote_average': voteAverage,
      'runtime': runtime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        posterPath,
        overview,
        releaseDate,
        mediaType,
        numberOfSeasons,
        numberOfEpisodes,
        status,
        genres,
        voteAverage,
        runtime,
      ];
}
