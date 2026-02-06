import 'package:equatable/equatable.dart';

enum MediaType { movie, tv, person, unknown }

class TVSeason extends Equatable {
  final int id;
  final int seasonNumber;
  final int episodeCount;
  final String? name;

  const TVSeason({
    required this.id,
    required this.seasonNumber,
    required this.episodeCount,
    this.name,
  });

  factory TVSeason.fromJson(Map<String, dynamic> json) {
    return TVSeason(
      id: json['id'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      episodeCount: json['episode_count'] ?? 0,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'season_number': seasonNumber,
      'episode_count': episodeCount,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, seasonNumber, episodeCount, name];
}

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
  final List<TVSeason>? seasons;

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
    this.seasons,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final mediaTypeStr = json['media_type'] as String?;
    final mediaType = _parseMediaType(mediaTypeStr);

    List<String>? genresList;
    if (json['genres'] != null && json['genres'] is List) {
      genresList = [];
      for (final g in (json['genres'] as List)) {
        if (g is String) {
          genresList.add(g);
        } else if (g is Map) {
          final name = g['name'];
          if (name is String) genresList.add(name);
        }
      }
    }

    List<TVSeason>? seasonsList;
    if (json['seasons'] != null && json['seasons'] is List) {
      seasonsList = [];
      for (final s in (json['seasons'] as List)) {
        if (s is Map) {
          seasonsList.add(TVSeason.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    List<TVSeason>? seasonsList;
    if (json['seasons'] != null) {
      seasonsList = (json['seasons'] as List)
          .map((s) => TVSeason.fromJson(s))
          .toList();
    }

    return MediaItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      mediaType: mediaType,
      numberOfSeasons: json['number_of_seasons'] as int?,
      numberOfEpisodes: json['number_of_episodes'] as int?,
      status: json['status'] as String?,
      genres: genresList,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      runtime: json['runtime'] as int?,
      seasons: seasonsList,
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
      'seasons': seasons?.map((s) => s.toJson()).toList(),
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
        seasons,
      ];
}
